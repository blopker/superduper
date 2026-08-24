# Background locked-setting synchronization

Status: feasibility and architecture recommendation, based on platform behavior current as of August 2026.

## Goal

After initial setup, the user should not need to open Superduper before riding:

1. The user turns on the active bike.
2. The operating system wakes Superduper without presenting its UI.
3. Superduper connects, authenticates, and reads the current configuration.
4. It applies only the locked values, preserving values the user left unlocked.
5. It confirms the result and records the outcome.
6. The user rides.

This is needed only on Android and iOS. It is a convenience feature, not a safety mechanism, and the UI must not claim it will work after the user revokes Bluetooth access, disables Bluetooth, force-stops the app where the platform prohibits relaunch, or leaves the phone out of range.

## Recommendation

Proceed with platform feasibility prototypes, starting with iOS. Do not replace FlutterBluePlus before those prototypes show that it is necessary.

The first implementation should keep FlutterBluePlus as the sole GATT connection owner and add narrow native integrations for the operating-system features it does not provide:

- iOS: AccessorySetupKit setup or migration, Core Bluetooth background configuration, and state restoration.
- Android: Companion Device Manager presence and/or a filtered `BluetoothLeScanner` `PendingIntent` that wakes background Dart work.

Both platforms should initially run the existing Dart `BikeSession` connection, authentication, merge, write, and confirmation path. If cold-starting Flutter is not reliable enough, move only the fixed background synchronization transaction into Swift and Kotlin. A general-purpose replacement BLE library should be the last option, not the starting point.

## Verified bike advertisement

The distinction between a GATT service and an advertised service is important. The bike exposes custom services after a connection, but the tested bike does not include those service UUIDs in its advertisement.

A passive Core Bluetooth scan of a powered-on protocol V1 bike returned:

```text
Complete local name: SUPER73
Advertised service UUIDs: none
Overflow service UUIDs: none
Solicited service UUIDs: none
Service data: none
Manufacturer data: company ID 0x020f followed by the 8-byte module serial
```

The scan did not connect to or modify the bike. Its result agrees with the reverse-engineered [BLE protocol documentation](ble_protocol.md), which records a 400 ms advertisement containing the complete name and stable manufacturer serial but no custom service UUID.

Only a physical V1 bike was verified over the air. The firmware analysis says V2 has the same advertising shape, but that should be confirmed on a physical V2 bike.

This shape has opposite consequences on the two platforms:

- Android can efficiently filter for the exact bike using manufacturer ID `0x020f` and its eight serial bytes.
- iOS cannot discover it through an ordinary screen-off background scan because iOS requires one or more advertised service UUIDs for that scan.

## Platform feasibility

| Condition | iOS | Android |
| --- | --- | --- |
| App backgrounded and screen off | Supported through a pending connection to a known peripheral | Supported through companion presence or a filtered scan `PendingIntent` |
| App process removed by the OS | Supported through Core Bluetooth state restoration | Supported through companion presence or a scan `PendingIntent` |
| Device reboot | Restored after the first unlock, subject to Apple’s restoration rules | Re-register work at boot, unless the app is stopped, restricted, or hibernated |
| User force-quit or Force Stop | AccessorySetupKit improves iOS 26 relaunch eligibility, but this must be proven | Not supported until the user interacts with the app again |
| Months without opening the app | Normally possible while authorization remains intact | App hibernation must be addressed during opt-in |
| Persistent user-visible notification | Not required | Not required for short work; required if a foreground service is used |

## iOS design

### Background scanning is not the trigger

When an iOS app is in the background, `scanForPeripherals(withServices:)` must specify one or more services. The bike advertises none, so scanning by name or manufacturer data cannot provide the desired screen-off behavior. iOS 26 Live Activities temporarily relax scanning restrictions while the app is sufficiently in use, but Apple states that the relaxation ends when the locked screen turns off. This is not a viable “never open the app” mechanism.

Sources: [Core Bluetooth scan API](https://developer.apple.com/documentation/corebluetooth/cbcentralmanager/scanforperipherals%28withservices%3Aoptions%3A%29), [Apple engineer on screen-off scanning](https://developer.apple.com/forums/thread/815189).

### A pending connection is the trigger

After setup, the app can retrieve the known `CBPeripheral` using its saved identifier and call `connectPeripheral` while the bike is off. Apple documents that connection requests do not time out. With Core Bluetooth state restoration enabled, the operating system preserves connected and pending peripherals, completes the connection when the bike appears, and can relaunch the app to handle the event.

Sources: [Core Bluetooth background processing](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html), [central-manager restoration state](https://developer.apple.com/documentation/corebluetooth/central-manager-state-restoration-options), [restoration delegate](https://developer.apple.com/documentation/corebluetooth/cbcentralmanagerdelegate/centralmanager%28_%3Awillrestorestate%3A%29).

The intended lifecycle is:

```text
bike off
  -> pending connection retained by iOS
  -> bike turns on
  -> connection completes and wakes Superduper
  -> authenticate, merge, write, and confirm locked settings
  -> keep the connection idle while the bike remains on
  -> bike turns off and the connection drops
  -> disconnection wakes Superduper
  -> arm the next pending connection
```

Keeping the connection idle is likely necessary. If Superduper intentionally disconnects and immediately arms another pending connection, it will reconnect while the same bike power session is still active. If it disconnects without arming another request, there is no advertised service UUID with which to detect the next startup in the background.

The idle connection should not subscribe to periodic telemetry. Connection and disconnection events are sufficient for this lifecycle, while telemetry could wake the app repeatedly and waste power.

### Background execution deadline

Apple says a Core Bluetooth wake normally has around ten seconds to finish its work. The critical path must therefore be deliberately short:

1. Restore or establish the connection.
2. Discover required GATT state if it was not restored.
3. Authenticate.
4. Read the current configuration.
5. Merge locked values while preserving unlocked values.
6. Write only when needed.
7. Read back and confirm.
8. Persist the outcome.

Version reads and other diagnostics are secondary. They should run only after configuration is confirmed and only while sufficient execution time remains.

### AccessorySetupKit

Use AccessorySetupKit on iOS 18 and later. It can discover these bikes using company identifier `0x020f`, the advertised name, and an optional manufacturer-data mask. It returns a Bluetooth identifier for later Core Bluetooth connections. Existing saved peripherals can be migrated using their current `CBPeripheral.identifier`.

AccessorySetupKit does not replace the bike’s application authentication. It provides system authorization and accessory identity; communication still uses Core Bluetooth.

This is particularly important on iOS 26. Apple’s current relaunch rules restrict several restoration cases to accessories configured with AccessorySetupKit. An Apple engineer describes AccessorySetupKit migration as the route to restoration after a user force-quits the app. Because these semantics are new and sensitive to the exact pending Bluetooth operation, force-quit recovery must be demonstrated on hardware before it is promised to users.

Sources: [AccessorySetupKit discovery and migration](https://developer.apple.com/documentation/accessorysetupkit/discovering-and-configuring-accessories), [Meet AccessorySetupKit](https://developer.apple.com/videos/play/wwdc2024/10203/), [TN3115 restoration rules](https://developer.apple.com/documentation/technotes/tn3115-bluetooth-state-restoration-app-relaunch-rules/), [Apple engineer on pending connections and AccessorySetupKit](https://developer.apple.com/forums/thread/818370).

### Primary iOS risk

The main product risk is connection coexistence. A background connection may remain open for the entire time the bike is powered. We must establish whether the display supports another simultaneous phone connection and whether holding the connection interferes with the official app or other tools.

If the display supports only one phone central and holding that connection is unacceptable, there is no clean, reliable iOS power-cycle detector with the current advertisement. A firmware change that advertises a stable custom service UUID would be the highest-leverage solution: Superduper could disconnect after synchronization and let iOS wait on a background service-filtered scan for the next power-on event.

## Android design

Android directly supports waking a dead app process when a matching BLE advertisement is observed. Its current guidance recommends either:

- `BluetoothLeScanner.startScan(filters, settings, pendingIntent)` for a matching advertisement; or
- Companion Device Manager and `CompanionDeviceService` for an associated accessory’s presence.

Source: [Android background BLE guidance](https://developer.android.com/develop/connectivity/bluetooth/ble/background).

### Discovery

The strongest scan filter is the exact active bike:

```text
manufacturer ID = 0x020f
manufacturer bytes = saved 8-byte module serial
mask = all bytes significant
```

Android supports manufacturer-data filters and masks in `ScanFilter`. Filtered scans continue when the screen is off, unlike unfiltered scans. The bike’s stable serial also avoids waking Superduper for every nearby SUPER73 bike.

Sources: [ScanFilter builder](https://developer.android.com/reference/android/bluetooth/le/ScanFilter.Builder), [BluetoothLeScanner](https://developer.android.com/reference/android/bluetooth/le/BluetoothLeScanner).

### Companion association

The preferred Android 12-and-later path is:

1. Associate the bike through Companion Device Manager during initial setup.
2. Observe presence through `CompanionDeviceService`.
3. When the bike appears, run the short connection and synchronization transaction.
4. Mark it synchronized for the current presence epoch.
5. Clear that marker when the bike disappears.

Companion Device Manager does not establish the GATT connection and does not replace the custom authentication protocol. It supplies the association, background privileges, and presence lifecycle.

Android warns that companion presence has limited filtering and does not support unresolved random MAC addresses. We need to test the display’s address behavior. The exact manufacturer-serial `PendingIntent` scan is the fallback if address-based presence is unreliable.

Source: [Companion-device pairing](https://developer.android.com/develop/connectivity/bluetooth/companion-device-pairing).

### Executing the synchronization

The first prototype should enqueue short-lived background Dart work and run the existing `BikeSession` through FlutterBluePlus. Android explicitly recommends a Worker or Job for short communication following a scan `PendingIntent`.

If the operation cannot reliably finish as short work, a `connectedDevice` foreground service is the supported fallback. That introduces a user-visible notification and should not be the default unless testing proves it necessary.

### Hibernation and Force Stop

Android can hibernate an app that the user has not opened for several months. On Android 12 and later, hibernation resets runtime permissions and prevents background jobs and alerts. Android explicitly recognizes communication with smart and companion devices as a reason to explain and request an exemption from unused-app restrictions.

“Automatic bike setup” onboarding should therefore:

- explain why background operation is necessary;
- check the unused-app restrictions status; and
- offer the system settings flow to disable “Pause app activity if unused.”

A manual Force Stop remains terminal until the user interacts with the app. Android 15 also cancels pending intents when the app enters the stopped state. The app must re-register its scan and presence work after the next launch or other permitted user interaction.

Sources: [Android app hibernation](https://developer.android.com/topic/performance/app-hibernation), [Android 15 stopped-state behavior](https://developer.android.com/about/versions/15/behavior-changes-all).

## FlutterBluePlus scope

Superduper uses a small subset of FlutterBluePlus:

- adapter state;
- foreground scanning by name and manufacturer data;
- open a known device by platform identifier;
- connect and disconnect;
- discover three known services and a fixed set of characteristics;
- characteristic reads and writes;
- notification enablement and value events; and
- connection-state events.

It does not use generic bonding management, MTU negotiation, PHY selection, descriptor access, connection-priority changes, GATT cache clearing, post-connection RSSI reads, Bluetooth power control, or most of the package’s supported platforms and scan filters.

This narrow dependency is already isolated behind [`BikeTransport`](../lib/src/ble/bike_transport.dart) and implemented by [`FlutterBlueBikeTransport`](../lib/src/ble/flutter_blue_bike_transport.dart). Replacing the transport would not require rewriting the application or `BikeSession`.

FlutterBluePlus already offers `restoreState: true` on Darwin and its native implementation handles Core Bluetooth’s `willRestoreState` callback for pending and connected peripherals. Superduper does not currently enable that option. This existing support should be tested before any native GATT replacement is written.

FlutterBluePlus describes background BLE as an advanced use case that may require a fork, and it does not provide AccessorySetupKit, Android companion presence, or Android scan-`PendingIntent` orchestration. Those missing pieces are operating-system wake mechanisms rather than replacements for its GATT implementation.

Source: [FlutterBluePlus background documentation](https://pub.dev/packages/flutter_blue_plus#using-ble-in-app-background).

### Incremental implementation strategy

#### Stage 1: retain FlutterBluePlus

Add a small platform integration that only performs setup and wake orchestration:

- iOS native code owns AccessorySetupKit presentation and migration. After migration, FlutterBluePlus owns Core Bluetooth and uses state restoration.
- Android native code owns companion presence and scan-`PendingIntent` registration. It wakes registered background Dart work but does not open a GATT connection.
- Dart opens the database and runs the existing production `BikeSession` path.

This keeps a single connection owner and tests whether a cold Flutter launch is sufficiently fast and reliable.

#### Stage 2: native background transaction only

If cold Flutter or plugin restoration is unreliable, retain FlutterBluePlus for foreground use but implement the fixed background transaction natively:

```text
connect
discover fixed services and characteristics
read authentication challenge
write authentication response
verify authentication
read configuration
merge locked values
write configuration when changed
read back and confirm
record result
```

This is a bike-specific state machine, not a general BLE library. Swift and Kotlin implementations should share language-neutral golden fixtures for authentication, V1 and V2 packet encoding, configuration merging, manufacturer filters, and confirmation decoding.

The native transaction needs an atomic desired-state snapshot containing only:

- whether automatic synchronization is enabled;
- active bike platform identifier and module serial;
- selected protocol;
- lock flags and locked values; and
- a monotonically increasing configuration generation.

It should write back the last attempt, last confirmed generation and configuration, timestamps, and a bounded diagnostic record. It should not independently mutate the primary Drift model.

#### Stage 3: replace the transport only if ownership fails

Build a minimal app-owned BLE plugin only if foreground FlutterBluePlus and the native background transaction cannot hand ownership over safely. That plugin should implement the existing `BikeTransport` contract rather than a generic public GATT API.

Switching to another generic Flutter BLE package would not remove the need for AccessorySetupKit, Companion Device Manager, pending connections, process restoration, or app hibernation handling.

## Single-owner requirement

Only one component may own a bike connection at a time. A native wake component must not connect while FlutterBluePlus is connected, and FlutterBluePlus must not initialize its own central or GATT client while a native background transaction owns the bike.

Every prototype must test these handoffs:

- background synchronization while Flutter is not running;
- opening the app while background work is connecting or synchronizing;
- closing or backgrounding the app while the foreground connection is active;
- changing the active bike while an old pending request exists;
- disabling automatic synchronization; and
- forgetting the active bike.

## Required prototypes and acceptance tests

### iOS first

Test on physical devices with the screen off:

- AccessorySetupKit setup using the bike’s company ID and name.
- Migration of an already-saved peripheral identifier.
- Bike off, app suspended, then bike on.
- App process removed by the operating system before the bike turns on.
- User force-quit on iOS 26.
- Device reboot and first unlock.
- Bluetooth toggled through Control Center.
- Bluetooth toggled through Settings; failure requiring user action is acceptable.
- App upgrade while a connection is pending.
- One synchronization per bike power cycle with no reconnect loop.
- Idle connection for a complete ride.
- Simultaneous use by the official app or another phone.
- Synchronization completion within the background execution deadline.

### Android

Test at least a current Pixel and Samsung device:

- Companion association and presence callbacks.
- Exact manufacturer-serial `PendingIntent` filtering.
- Screen off and Doze.
- Process removal and task dismissal.
- Reboot and application upgrade.
- BLE address stability or rotation.
- Default and restricted battery modes.
- Simulated app hibernation and recovery.
- Manual Force Stop as an expected failure.
- One synchronization per presence epoch.
- Configuration readback proving locked values were applied and unlocked values were preserved.

### Common success criteria

- The application UI never needs to appear.
- The production authentication and configuration paths are used.
- Locked values are confirmed by a readback.
- Unlocked values are never overwritten.
- No duplicate writes occur in one power session.
- Failures use bounded retries and cannot loop indefinitely.
- The last outcome is available to the foreground app and support report.
- Disabling the feature cancels pending platform work and connections.
- Logs never include the authentication secret or challenge response.

## Product behavior

Present this as an explicit “Automatic bike setup” option during or after bike setup. The app should show:

- whether the feature is enabled;
- which bike is active;
- the last successful background synchronization time;
- whether the latest desired generation was confirmed; and
- a clear action when Bluetooth authorization, accessory authorization, Android unused-app settings, or another system condition requires attention.

Do not promise unconditional operation after Force Stop, permission revocation, Bluetooth being disabled, device-management restrictions, or the app being removed. A short local notification after a background failure may be useful, but successful synchronization should remain silent.

## Decision gates

The feature is recommended for production on Android if companion presence or exact filtered scanning reliably wakes short background work across the device test matrix.

The feature is recommended for production on iOS only if all of the following are true:

1. The pending connection reliably relaunches and restores the app.
2. The synchronization completes inside the background deadline.
3. Holding an idle connection does not create unacceptable battery use.
4. Holding that connection does not prevent expected use of the official app or another phone.
5. One and only one synchronization occurs per power cycle.

If the fourth condition fails, request or pursue a firmware change that advertises a stable custom service UUID. Without that change, iOS can still offer best-effort background behavior, but it should not be presented as the fully automatic experience described in this document.
