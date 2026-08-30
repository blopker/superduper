# Background Set on connect synchronization

Status: the Android Companion Device Manager implementation is ready for physical-device validation. The iOS design remains a feasibility recommendation.

## Goal

After initial setup, the user should not need to open Superduper before riding:

1. The user turns on the active bike.
2. The operating system wakes Superduper without presenting its UI.
3. Superduper connects and authenticates.
4. It applies only enabled Set on connect choices, preserving other values.
5. It records the acknowledged result.
6. The user rides.

This is needed only on Android and iOS. It is a convenience feature, not a safety mechanism, and the UI must not claim it will work after the user revokes Bluetooth access, disables Bluetooth, force-stops the app where the platform prohibits relaunch, or leaves the phone out of range.

## Recommendation

Keep FlutterBluePlus as the foreground GATT connection owner and use narrow native integrations for background execution:

- iOS: AccessorySetupKit setup or migration, Core Bluetooth background configuration, and state restoration.
- Android: Companion Device Manager presence runs a bounded native GATT transaction.

Dart owns the bike protocol semantics and materializes literal background command frames in Drift. Android reads those frames without starting Flutter. A future iOS implementation can consume the same plan. A general-purpose replacement BLE library should be the last option, not the starting point.

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
| App backgrounded and screen off | Supported through a pending connection to a known peripheral | Supported through companion presence |
| App process removed by the OS | Supported through Core Bluetooth state restoration | Supported through companion presence |
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
  -> authenticate and apply Set on connect
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
5. Merge enabled Set on connect choices while preserving other values.
6. Write only when needed.
7. Persist the acknowledged outcome.

Version reads and other diagnostics are secondary. They should run only after the configuration write is acknowledged and only while sufficient execution time remains.

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

### Implemented Android prototype

The Android implementation follows this lifecycle:

```text
stable bike identity
  -> Companion Device Manager association and background privilege
  -> CDM presence callback or manufacturer-data PendingIntent scan
  -> read the materialized command plan from Drift
  -> native GATT connect and application authentication
  -> write each pre-encoded command in order
  -> disconnect and record the bounded outcome in Android shared preferences
```

The bike-settings page exposes the consented “Background Sync” switch on Android. Enabling it pauses the foreground bike connection and opens Android's system association flow for the active bike's stable Bluetooth address. If an imported bike does not have a saved module serial, enablement first briefly scans for that active bike and stores the serial. The preference is saved only after association and presence observation succeed. Disabling the feature, changing the active bike, or forgetting the bike stops observation and removes the association.

The system association chooser owns its lifetime; the app does not impose a timeout while the user is deciding. Before the chooser appears, a native watchdog reports a failed device search because Android 12 and 12L can otherwise end that search without invoking either association callback. If Android's association is later removed outside the app, reconciliation turns off the stored Background Sync request instead of failing app startup or leaving an enabled switch with no native registration.

Android restores presence observation and the manufacturer-data scan after boot, package replacement, the next app open, and Bluetooth becoming available. The association remains system-owned while enabled. Both the companion service and the scan receiver can wake a dead process.

A CDM BLE-appeared event or the scan's first matching advertisement starts
synchronization. Disconnect and disappearance events are ignored, including the
disconnect produced by the native transaction itself. The service serializes
transactions, ignores duplicates while one is loading or connected, and uses a
short cooldown to ignore the advertisement caused by its own GATT disconnect.
It also bails out while the activity is foreground. When the activity enters the
foreground, it cancels and closes any native GATT client before FlutterBluePlus
resumes ownership. If Android reports appearance while Bluetooth is transitioning,
the request is retained and resumed after the adapter reaches `STATE_ON`.

Drift is the only writer of the background plan. Whenever the active bike,
protocol, region, consent, or Set on connect choices change, Dart atomically
replaces the complete native execution plan: the exact manufacturer-data scan
filter, GATT service and characteristic identifiers, authentication inputs and
expected state, and the ordered command payloads. Disabled fields are encoded
as `0xFF`, which the display's independent range checks ignore. Kotlin opens the
database read-only, validates the plan's transport-level shape, then supplies
that data to Android's scan, digest, and GATT APIs. It contains no bike UUIDs,
manufacturer IDs, authentication secrets, or light, mode, assist, region, and
protocol semantics. An absent plan is a no-op.

The implementation still needs durable outcome storage in Drift, an outcome display in the UI and support report, unused-app restriction onboarding, and the Pixel/Samsung/Xiaomi hardware matrix.

### Android hardware smoke test

Use a debug build and a physical bike whose module serial appears under Bike information:

1. Choose at least one Set on connect value, make the bike active, enable Background Sync, and approve Android's association dialog while the bike remains on.
2. Turn the bike off and allow Android to observe its disappearance.
3. Background the app and remove its task without using Force Stop.
4. Turn the screen off, then power on the bike.
5. After the transaction has had time to finish, inspect the prototype result:

   ```text
   adb shell run-as io.kbl.superduper cat shared_prefs/background_sync.xml
   ```

   `last_presence_source` should be `bleAppeared` or `bleScanFirstMatch`, `last_presence_at_ms` and `last_sync_started_at_ms` should be recent, and `last_outcome` should be `confirmed`. If restoration failed, `registration_error_detail` records the native reason.
6. Open the app and confirm Set on connect was applied while every disabled value remained unchanged.

For the cold-process case, `adb shell am kill io.kbl.superduper` may be used only after the app is backgrounded. Do not use `am force-stop`: Force Stop intentionally cancels this path until the user opens the app again.

### Companion association

The Android 12-and-later path is:

1. Associate the bike through Companion Device Manager during initial setup.
2. Observe presence through `CompanionDeviceService`.
3. When the bike appears, run the short connection and synchronization transaction.

Companion Device Manager does not establish the GATT connection and does not replace the custom authentication protocol. It supplies the association, background privileges, and presence lifecycle.

The association request filters on the exact saved Bluetooth address. Physical testing has established that the bike address is stable across power cycles. The read-only native plan must name that same address before any connection or setting write.

Source: [Companion-device pairing](https://developer.android.com/develop/connectivity/bluetooth/companion-device-pairing).

### Executing the synchronization

The presence service runs a short native bike-specific state machine: connect, discover the fixed characteristics, complete challenge-response authentication, write the materialized commands, and close the GATT client. It does not start Flutter, WorkManager, polling, notifications, version reads, or odometer reads.

If the operation cannot reliably finish as short work, a `connectedDevice` foreground service is the supported fallback. That introduces a user-visible notification and should not be the default unless testing proves it necessary.

### Hibernation and Force Stop

Android can hibernate an app that the user has not opened for several months. On Android 12 and later, hibernation resets runtime permissions and prevents background jobs and alerts. Android explicitly recognizes communication with smart and companion devices as a reason to explain and request an exemption from unused-app restrictions.

“Background Sync” onboarding should therefore:

- explain why background operation is necessary;
- check the unused-app restrictions status; and
- offer the system settings flow to disable “Pause app activity if unused.”

A manual Force Stop remains terminal until the user interacts with the app. The app restores presence observation after the next launch or other permitted user interaction.

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

FlutterBluePlus describes background BLE as an advanced use case that may require a fork, and it does not provide AccessorySetupKit or Android companion-presence orchestration. Those missing pieces are operating-system wake mechanisms rather than replacements for its GATT implementation.

Source: [FlutterBluePlus background documentation](https://pub.dev/packages/flutter_blue_plus#using-ble-in-app-background).

### Connection ownership strategy

#### Foreground transport

Add a small platform integration that only performs setup and wake orchestration:

- iOS native code owns AccessorySetupKit presentation and migration. After migration, FlutterBluePlus owns Core Bluetooth and uses state restoration.
- Android native code owns companion association, presence observation, and the bounded background GATT transaction.
- Dart owns foreground connections and writes the native background command plan.

This keeps a single connection owner and tests whether a cold Flutter launch is sufficiently fast and reliable.

#### Native background transaction

The Android background path is deliberately smaller than the foreground session:

```text
load the materialized execution plan
connect
discover the plan's services and characteristics
read the plan's authentication challenge
write the computed authentication response
verify the plan's expected authentication state
write its commands in order
record the acknowledged write
record result
```

This is a bounded plan executor, not a general BLE library. Dart owns the bike-specific golden fixtures for authentication inputs, V1 and V2 packet encoding, configuration merging, and manufacturer filters. Native implementations validate and execute the same materialized plan format.

The native transaction consumes an atomic execution snapshot containing:

- a plan-format version;
- the active bike Bluetooth address; and
- an exact manufacturer-data scan filter;
- service and characteristic identifiers;
- authentication algorithm inputs and expected state; and
- ordered, literal command payloads.

It writes timestamps and a bounded diagnostic outcome to Android shared preferences. It never mutates Drift.

#### Transport replacement fallback

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
- Screen off and Doze.
- Process removal and task dismissal.
- Reboot and application upgrade.
- Stable-address association across bike power cycles.
- Default and restricted battery modes.
- Simulated app hibernation and recovery.
- Manual Force Stop as an expected failure.
- One synchronization per presence epoch.
- Physical verification that `0xFF` fields are ignored independently on both protocol versions.

### Common success criteria

- The application UI never needs to appear.
- Authentication and command bytes match the documented production protocol.
- Set on connect writes are accepted when GATT acknowledges them.
- Disabled values are never overwritten.
- No duplicate writes occur in one power session.
- Each appearance starts at most one bounded attempt and cannot loop indefinitely.
- The last outcome is available to the foreground app and support report.
- Disabling the feature cancels pending platform work and connections.
- Logs never include the authentication secret or challenge response.

## Product behavior

Present this as an explicit “Background Sync” option during or after bike setup. The app should show:

- whether the feature is enabled;
- which bike is active;
- the last successful background synchronization time;
- whether the latest desired generation was confirmed; and
- a clear action when Bluetooth authorization, accessory authorization, Android unused-app settings, or another system condition requires attention.

Do not promise unconditional operation after Force Stop, permission revocation, Bluetooth being disabled, device-management restrictions, or the app being removed. A short local notification after a background failure may be useful, but successful synchronization should remain silent.

## Decision gates

The feature is recommended for production on Android if companion presence reliably wakes short background work across the device test matrix.

The feature is recommended for production on iOS only if all of the following are true:

1. The pending connection reliably relaunches and restores the app.
2. The synchronization completes inside the background deadline.
3. Holding an idle connection does not create unacceptable battery use.
4. Holding that connection does not prevent expected use of the official app or another phone.
5. One and only one synchronization occurs per power cycle.

If the fourth condition fails, request or pursue a firmware change that advertises a stable custom service UUID. Without that change, iOS can still offer best-effort background behavior, but it should not be presented as the fully automatic experience described in this document.
