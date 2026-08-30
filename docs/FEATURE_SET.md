# SuperDuper feature-set baseline

This document defines the behavior that matters when modernizing SuperDuper. It
describes the product shipped by version `0.7.8+58`, separating its user-facing
contract from implementation details and unresolved behavior. A new
implementation may change the design and architecture while preserving the
product contract below.

## Product at a glance

SuperDuper is a local-first mobile controller for compatible ebikes. It
discovers nearby bikes over Bluetooth Low Energy (BLE), saves multiple bikes,
and controls their light, regulatory mode, and pedal-assist level.

The core product principles are:

- No SuperDuper account, backend, or internet connection is required to find,
  save, or control a bike.
- Bike data and preferences stay on the device.
- A user can keep several bikes and switch among them.
- Desired settings can be enforced when a bike resets or changes them.
- The app controls capabilities already exposed by the bike firmware; it does
  not modify or replace firmware.

The supported release platforms are Android and iOS. A macOS target exists for
development, but the product documentation and release process do not promise a
macOS release.

## Confirmed V2 core requirement

The modernization has one product requirement beyond the behavior reliably
implemented by version `0.7.8+58`: opening the app must automatically prepare a
persisted active bike for riding.

- The first bike set up becomes active by default.
- When multiple bikes are saved, the user can explicitly choose the one active
  auto-connect bike.
- Opening the app connects directly to that bike without requiring navigation
  into its control screen.
- After connecting, the app reads the current configuration, applies the
  user's enabled Set on connect values, writes one complete configuration if
  needed, and accepts an acknowledged write.
- The app reports ride readiness only after the initial read and any Set on
  connect write.
- Until background operation is proven, this workflow runs while the app is
  foreground-active and repeats the next time the app opens.

The current `currentBike` JSON field is not a durable active-bike preference, so
V2 requires a separate persisted active-bike identity. The detailed behavior
and migration rules are defined in [`V2.md`](../V2.md).

## User journeys

### 1. Launch and permissions

1. The app starts in a dark theme and asks for the Bluetooth-related permissions
   needed by the platform.
2. While permission requests are in progress, it shows a loading indicator.
3. If a requested permission is denied, it replaces the app with an instruction
   to enable Bluetooth and location permissions.
4. Once permissions are available, the bike-selection screen opens and scanning
   starts automatically.

The selection screen also reports adapter problems without hiding the rest of
the interface:

- Bluetooth off: `Bluetooth is turned off`.
- Unauthorized: `Bluetooth permissions are needed`.
- Any other unavailable state: `Bluetooth unavailable`.

### 2. Find and save a bike

- Scanning starts automatically when the selection screen is first shown and
  runs for up to 100 seconds.
- The scan action toggles between starting and stopping a scan. An empty state
  also offers a scan action.
- Android attempts to turn Bluetooth on when a scan starts.
- Scan results are limited to the two supported protocol-local-name identifiers.
- Previously saved bikes and newly found bikes are shown in separate lists.
- Each entry shows a friendly name and the BLE device identifier.
- Newly found bikes receive a stable, friendly adjective-and-animal name derived
  from their device identifier.
- Selecting a bike opens its control screen and begins connecting. After its
  first successful state sync, a newly found bike appears in the saved list.
- Saved bikes remain available even when they are not currently nearby.

Saved-bike cards visually distinguish connected from disconnected bikes. When
at least one BLE device is connected, a global `Disconnect` action disconnects
all devices reported as connected to the app. Going back to the bike list does
not explicitly disconnect the selected bike, which makes switching back to it
quicker.

### 3. Connect and recover

- Selecting a bike starts a BLE connection automatically.
- The control screen shows `Connecting...`, `Connected`, or an actionable
  `Connect` state.
- A disconnected selected bike is retried automatically every 10 seconds.
- The user can tap `Connect` between automatic attempts.
- After connecting, the app discovers the bike's services and reads its current
  settings.
- On Android, the connection requests an MTU of 512 before service discovery.
- Connection failures are logged and converted to a disconnected state instead
  of terminating the app.

### 4. Control a bike

The control screen shows the bike name, connection status, settings action, and
three live controls.

| Control | Values | Tap behavior |
| --- | --- | --- |
| Light | Off / On | Toggles the bike light |
| Mode | 1 through 4 | Selects a mode directly |
| Assist | 0 through 4 | Selects a level directly |

A control change sends the complete light, assist, and mode configuration to
the bike. If the bike is disconnected, control taps do not change the saved
state.

The app reads the bike periodically while its control state is active and reads
again after connection. Values observed on the bike update the local display;
polling and telemetry never reapply Set on connect values.

#### Light

Light toggles the bike's lights when the bike exposes that capability.

#### Mode

Mode selects one of four firmware-provided regulatory profiles. Internally the
app presents both regions as modes 1–4 while translating the BLE values for the
selected region.

US behavior:

| Mode | Category | Pedal assist | Throttle | Documented limit |
| --- | --- | --- | --- | --- |
| 1 | Class 1 | Yes | No | 20 mph |
| 2 | Class 2 | Yes | Yes | 20 mph |
| 3 | Class 3 | Yes | No | 28 mph |
| 4 | Off-road | Yes | Yes | No limit |

EU behavior:

| Mode | Category | Pedal assist | Throttle | Documented limit |
| --- | --- | --- | --- | --- |
| 1 | EPAC | Yes | No | 25 km/h |
| 2 | 250W | Yes | No | 35 km/h |
| 3 | 850W | Yes | No | 45 km/h |
| 4 | Off-road | Yes | Yes | No limit |

The first successful state read infers the region when none has been saved:
wire modes 0–3 imply US and 4–7 imply EU. Once saved, the user-selected region
controls future encoding.

#### Assist

Assist controls pedal-assist strength from 0 (none) through 4 (full). It does
not change throttle power.

### 5. Configure Set on connect

Set on connect is configured in Bike Settings, separately from the live control
screen. Light, Mode, and Assist each have an enable switch. Mode and Assist show
their direct value selector when enabled. Because the bike starts with its light
off, enabling the Light option means turn the light on.

On each connection, the app reads the bike, applies enabled choices in one
complete configuration write, and confirms the result. It does not enforce them
again during that connection. The saved choices persist across app launches and
are not changed by live or physical bike controls. Enabled choices appear as
small lock-and-value indicators on Bike Control; tapping one opens Bike Settings.

### 6. Android Background Sync

Background Sync applies the normal Set on connect behavior when Android wakes
the process for a companion bike presence event. Enabling it:

- Registers the selected bike as a companion device.
- Materializes exact Set on connect commands in SQLite whenever settings change.
- Runs a bounded native authentication and write transaction when that bike appears.

Disabling Background Sync removes the companion association. The preference is
saved per bike, and the control is not shown on iOS.

The background path does not start Flutter or a foreground service. FlutterBluePlus
owns foreground connections; Android owns only the short presence-triggered
transaction and closes it before the app resumes. Screen-off, backgrounded,
dismissed-from-recents, and force-stopped behavior remain physical-device
acceptance-test cases.

### 7. Personalize and remove a bike

The settings sheet allows a user to:

- Rename a bike; a non-empty name is required.
- Choose US or EU behavior; a region is required.
- Choose one of 32 named color gradients used by that bike's cards and controls.
- Delete the saved bike after a confirmation dialog.

Name, region, and color changes are local metadata and are not sent to the bike.
Deleting a bike is intended to remove only its local record; it does not modify
the bike.

### 8. Help and diagnostics

- `Not connecting?` opens the project FAQ in the system browser.
- `Help & Tips` on the control screen opens the Getting Started guide in the
  system browser.
- Debug builds expose a `DEBUG CONSOLE` that can open the bike-editing form with
  a generated test device identifier. This is a developer aid, not a release
  feature.

## Local data model

The app stores JSON files in its application-documents directory. There is no
cloud sync, cross-device sync, account recovery, import, or export.

Each saved bike contains:

| Field | Purpose |
| --- | --- |
| BLE device identifier | Stable identity and connection target |
| Name | Generated default or custom friendly name |
| Set on connect light | Whether to turn the light on at connection |
| Set on connect mode | Enabled choice and selected mode |
| Set on connect assist | Enabled choice and selected assist level |
| Region | US/EU mode interpretation |
| Background Sync | Per-bike Android companion-sync preference |
| Color | Selected gradient index |

A separate settings file stores the most recently selected bike identifier. The
current app writes and clears that value but does not read it to restore the
control screen at launch, so launch restoration is not an active feature.

Malformed, missing, or unreadable local files fall back to empty/default state.
Uninstalling the app or clearing its app data removes these records.

## BLE compatibility contract

Compatibility is based on advertised name and GATT shape rather than an explicit
model list. The repository documents successful use across compatible models, but
the app does not branch by model or expose a compatibility check.

The state protocol uses these GATT identifiers:

- Metrics service: `00001554-1212-efde-1523-785feabcd123`.
- State register: `0000155f-1212-efde-1523-785feabcd123`.
- Register selector: `00001564-1212-efde-1523-785feabcd123`.

To read state, the app writes `[3, 0]` to the selector and reads the state
register. In the response, assist is byte 2, light is byte 4, and mode is byte 5.

Writes use a ten-byte payload:

```text
[0, 0xD1, light, assist, wireMode, 0, 0, 0, 0, 0]
```

US modes use wire values 0–3 and EU modes use 4–7. A rewrite must preserve this
translation and the fact that all three control values are written together.

The source defines security, device-information, notification, and firmware
update UUIDs, but no current user journey uses custom authentication, pairing,
firmware inspection, notifications, or firmware updates. Those constants do not
represent active features.

## Privacy and network behavior

- Core discovery, storage, Set on connect, and control work without internet
  access.
- The app has no login, backend API, advertising, telemetry, or analytics SDK.
- It does not collect or transmit bike identifiers, custom names, preferences,
  usage, or location.
- The only app-initiated network behavior is opening help pages in an external
  browser after a user taps a help action.
- Apple and Google may collect their normal store installation metrics and
  opt-in crash reports independently of the app.

The Android manifest currently declares internet and advertising-ID permissions
even though no runtime feature or dependency uses an advertising identifier.
These declarations are implementation cleanup candidates, not features to
preserve.

## Platform behavior

| Area | Android | iOS | macOS target |
| --- | --- | --- | --- |
| Product release | Yes | Yes | No documented release |
| Configured minimum | API 31 / Android 12 | iOS 15.6 | macOS 11 |
| BLE scan/connect | Yes | Yes | Development support present |
| Location requested at launch | No | Yes in current code | No |
| Background Lock control | Yes | No | No |
| Notification and battery-optimization prompts | For Background Lock | No | No |
| Supported orientations | Platform default | Portrait and landscape | Desktop window |

The public README says iOS 12+, while the current Xcode project requires iOS
15.6. The modernization plan needs an explicit minimum-version decision.

## Explicit non-features

The current product does not provide:

- Accounts, authentication, profiles, subscriptions, or payments.
- A backend, cloud backup, device-to-device sync, or remote bike control.
- Maps, ride recording, GPS tracking, speed, range, battery, or trip metrics.
- Bike firmware updates, controller programming, or capabilities beyond those
  already offered by the official firmware.
- Scheduling, automation rules, widgets, shortcuts, or notifications other than
  the Android foreground-service notification.
- In-app onboarding tutorials, per-model setup, or compatibility diagnostics.

## Modernization acceptance baseline

A replacement can be considered feature-compatible when it demonstrates:

- Permission, adapter-off, scan-in-progress, empty-scan, and scan-stop states.
- Automatic filtered discovery plus manual rescanning.
- Saving, listing, reconnecting to, switching among, editing, and deleting
  multiple bikes.
- Stable generated names and persisted custom name, region, color, and Set on
  connect choices.
- Correct live Light, Mode, and Assist reads and writes for both US and EU
  encodings.
- One-shot application of every enabled Set on connect choice after connection.
- Automatic reconnection and a manual retry path after connection loss.
- Zero-tap connection and Set on connect synchronization for one persisted
  active bike when the app opens.
- A deterministic first-bike default and an explicit way to make another saved
  bike active.
- Android companion association and background-work lifecycle behavior.
- Offline core operation and no app-owned transmission of locally stored data.
- External FAQ and Getting Started links.

Protocol behavior should be covered by automated tests. Discovery, persistence,
reconnection, setting enforcement, and Android lifecycle behavior should have
integration tests or repeatable hardware test procedures.

## Behaviors to resolve before implementation

These items are inconsistent or incomplete in the current product and should be
decided explicitly instead of copied accidentally:

- Product copy says Background Lock works after the app is closed, while its
  foreground task has no independent state-sync callback.
- A selected-bike identifier is persisted but never restored on launch.
- The privacy copy describes location as Android-only, while the iOS launch path
  also requests a location permission through the permission abstraction.
- The advertised iOS minimum is 12, but the build target is 15.6.
- Selecting a newly found bike does not immediately insert it into local storage;
  it is saved after a successful state read or write.
- Deleting from the settings sheet leaves the control screen active, where a
  later state update can save the bike again.
- Most BLE failures are log-only; the interface does not explain missing GATT
  services, failed reads/writes, permanently denied permissions, or how to open
  system settings.

## Implementation traceability

This baseline was derived from the following current sources:

- App launch and permissions: `lib/main.dart`.
- Discovery and bike selection: `lib/select_page.dart`.
- Connection, scanning, reads, writes, and reconnection: `lib/repository.dart`.
- Bike state, live controls, Set on connect, and Android background operation:
  the corresponding feature and BLE modules under `lib/src/`.
- Persistent data: `lib/db.dart` and `lib/models.dart`.
- Editing and color choices: `lib/edit_bike.dart` and `lib/colors.dart`.
- GATT identifiers and payload model: `lib/services.dart`.
- Product claims and user-facing semantics: `README.md`, `privacy.md`, and
  `docs/content/privacy.md`.
- Platform declarations: `android/app` and `ios/Runner`.
