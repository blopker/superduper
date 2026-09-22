# Bike-session evidence from BLE firmware

Inspected in Binary Ninja: `comodule-sdisplay-nrf-221122.bin.bndb` (protocol
v1) and `comodule-sdisplay-nrf-250426.bin.bndb` (protocol v2). These findings
come from static analysis, followed by the limited hardware experiment below.
The app uses the one-byte convention described here; firmware is unmodified.

## Strongest candidate: a marker in control-command history

Both firmware versions retain the complete 10-byte received control command in
RAM history. The control handler consumes bytes 2–4 and ignores bytes 5–9:

| Firmware | Control packet ID | Bytes 2–4 | Bytes 5–9 |
| --- | --- | --- | --- |
| `221122` | `00 D1` | lights, assist, operating mode | unused by control handler |
| `250426` | `00 C1` | lights, assist, ride preset | unused by control handler |

The app writes `1` at byte 5 and leaves bytes 6–9 zero. This means an app control
command was received during the current bike session. It does not identify a
specific transaction or settings revision and needs no local transaction journal.

The evidence supporting this candidate is:

1. The authenticated RX dispatcher passes the packet to the control handler and
   then inserts all ten bytes into history, including unused bytes.
2. The ordinary connect/disconnect handler for the COMODULE service changes the
   connection handle without clearing history.
3. Bike startup calls the history-seeding path before starting advertising.
   This inserts the control ID again with the startup seed payload, replacing
   any previous record with that ID. V1 explicitly zeroes its seed buffer.
   V2 uses a static seed buffer at `0x20006480` and changes only its ID byte in
   that routine. Runtime entry `0x23248` zeroes RAM from `0x20003548` for `0x5258`
   bytes, which includes that buffer. A literal-reference search found the
   buffer's address only in the seeding routine. Thus static analysis also
   supports a zero payload in V2, although it has not been observed on hardware.
4. Periodic telemetry does not publish the control-command ID. Its descriptor
   flags are `0x80`, whereas the telemetry builder selects descriptors with bit
   `0x20` set. V2's `00 D1` is telemetry; its control marker must use `00 C1`.
5. History is indexed by packet ID, so changes to other existing telemetry IDs
   do not themselves discard the control record.

This is more specific than an arbitrary RAM marker. Both applications have a
power-off path that stops advertising and work timers, disables the SoftDevice,
and enters a sleep/transition state. A normal bike power cycle need not be a
full MCU reset. Startup's explicit overwrite of the control record is therefore
the relevant boundary, rather than assuming all RAM was cleared.

## App behavior

Presence triggers a bounded inspection transaction:

1. Connect and authenticate normally.
2. Select a different known history ID and read it successfully as a cache
   barrier. Then select the firmware's control ID through `0x1564` and read
   `0x155f`, validating the ID and full record.
3. A valid control record with byte 5 equal to `1` suppresses the background
   write, regardless of current preferences or live settings.
4. Any valid control record without that marker allows the requested settings
   to be written with the marker. Then select/read the record again through a
   different-ID barrier and verify the complete command before reporting receipt.
5. A missing or unreadable control record fails the transaction. It is not
   treated as an unmarked record.

Foreground control writes use the same byte. A preference change does not clear
the bike's marker; explicit foreground writes still apply normally. Physical
changes before the first marked write do not suppress background application.
The policy deliberately does not reconstruct user changes since startup.

History readback confirms application receipt, not that the motor controller
has applied the settings. The RX dispatcher also records commands whose fields
were ignored by the control handler. This mechanism must not strengthen the
meaning of an acknowledgement beyond what the firmware actually confirms.

The background executor accepts exactly one V1/V2 control command, so settings
and marker are written together. A GATT write acknowledgement alone is not
reported as a verified receipt.

## Limitations

- History has 30 entries. A new packet ID can evict an older record. Unknown
  commands are also recorded, so arbitrary marker IDs are a weaker choice than
  the control ID that startup explicitly seeds.
- Another app can replace the same command record. An unmarked replacement
  permits background reapplication. SuperDuper's foreground and background paths
  both mark their control writes.
- A missing selector target leaves the RX/result buffer unchanged. An old copy
  of the marker can survive in that buffer. A successfully observed different-ID
  barrier is necessary before trusting a repeated read; if the barrier fails,
  report uncertainty rather than accepting the stale marker.
- The inference is specific to the two inspected firmware versions and their
  startup paths. Confirm soft power cycles, quick power cycles, and full battery
  removal separately.
- A marker permits safe inspection after an appearance; it does not wake Android
  when every presence callback is missing. Scan recovery and pending-work
  reconciliation remain separate requirements.
- This is deduplication evidence, not an authentication mechanism. Continue the
  existing challenge/response protocol on every connection.

## Other candidates examined

**Advertising:** the inspected constructors use the static device identifier in
manufacturer data. No boot/session marker was found there.

**Authentication challenge:** regenerated on every connection, so simply comparing
challenges does not identify a new bike session. Both versions derive it from
RTC1 through a deterministic SHA-1 calculation. Timer initialization during
startup calls the RTC stop/clear routine, making timer recovery an interesting
secondary experiment. However, recovering the timer from its digest and accounting
for rollover and timer lifecycle is more complicated than reading command history.
It is not an established session identifier.

**Auxiliary counter (`0x1581`):** notify-only, with a 16-bit counter in the first
two bytes and an undefined third byte. The periodic worker increments it once
per second even without a connection. The inspected increment paths contain no
per-bike-start reset; the worker stops during power-off. It may help measure
activity but should not be treated as per-ride uptime or a boot counter.

**Authentication state:** V1 sets it on disconnect; V2 clears it. This is neither
a consistent cross-version session marker nor a replacement for authentication.

## Firmware anchors

Addresses refer to the loaded application views, not raw-file offsets.

| Evidence | `221122` | `250426` |
| --- | --- | --- |
| Authenticated RX dispatch and history insertion | `0x2d178` | `0x2d194` |
| Control handler; consumes bytes 2–4 | `0x3076c` | `0x33234` |
| History insert/update | `0x300b0` | `0x30120` |
| History selector | `0x2d3a8` | `0x2d3e8` |
| COMODULE connect/disconnect handler | `0x2c40e` | `0x2c42a` |
| Startup history seeding | `0x31660` | `0x331d8` |
| Startup wrapper calling seeding | `0x31738` | `0x33954` |
| Application startup/shutdown state machine | `0x343dc` | `0x35dc4` |
| Telemetry builder; checks descriptor bit `0x20` | `0x2df7c` | `0x2dfbc` |
| Descriptor table | RAM `0x20003230` | flash initializer `0x476ac` |
| Challenge derivation | `0x2f048` | `0x2f06c` |
| Authentication BLE event handler | `0x2c94c` | `0x2c968` |
| Auxiliary counter notify/increment | `0x2de30` | `0x2de70` |

## Hardware experiment

### Initial observation: 2026-09-22

A nearby physical bike reports firmware `221122`, hardware `v3.2.0`. A scratch
CoreBluetooth probe authenticated and read its control history using an observed
`FCFC` cache barrier. It then wrote `00 D1 FF FF FF` followed by a random five-byte
marker. The three `FF` control fields are rejected individually by the verified
control handler, while the RX dispatcher still records the packet in history.

Immediate barrier-protected readback matched the complete marker packet. Live
`0300` telemetry before and two seconds after was identical:
`03 00 04 00 01 03 00 00 00 00`.

On the next connection from a fresh probe process, the record was instead exactly
the pre-experiment command, `00 D1 FF 04 03 00 00 00 00 00`. This is consistent
with a competing client reapplying settings, but is not proof of that cause.
The user then turned phone Bluetooth off. A fresh marker survived ten seconds
of connected operation and a disconnect followed by a new probe process and BLE
connection. Both readbacks used a successfully observed different-ID cache
barrier. Live `0300` telemetry remained unchanged. This supports competing phone
activity as the cause of the first replacement, although that phone's writes
were not captured directly.

With the phone still isolated, the user changed assist using the physical buttons
approximately twelve times. A further fresh connection found the same marker.
Live `0300` changed from `03 00 04 00 01 03 00 00 00 00` to
`03 00 00 00 01 03 00 00 00 00`, showing assist changed from 4 to 0 independently
of command history.

The user then powered the bike off normally, waited about five seconds, and
powered it back on. Barrier-protected history readback returned
`00 D1 00 00 00 00 00 00 00 00`: the marker was replaced by the predicted zero
startup seed. This validates normal reconnect persistence, independence from
physical assist changes, and clearing on a normal power cycle for this V1 bike.

A second fresh marker was written and verified immediately and after ten seconds.
The user then switched the bike off/on as quickly as its normal controls allow.
Readback again returned `00 D1 00 00 00 00 00 00 00 00`. The duration of that
manual quick cycle was not instrumented. The probe disconnected after readback;
the final power cycle removed the experimental marker.

| Test on physical V1 (`221122`) | Observed result |
| --- | --- |
| No-op command with marker in unused bytes | Exact readback; live control telemetry unchanged |
| Ten seconds connected with periodic telemetry | Marker retained |
| Disconnect and fresh probe-process connection, phone Bluetooth off | Marker retained |
| Approximately twelve physical assist changes | Marker retained; live assist changed 4 → 0 |
| Normal power-off, approximately five seconds off, then on | Zero startup seed |
| User-performed quick power-off/on | Zero startup seed |
| Initial reconnect before phone isolation | Previous control command returned; competing client suspected |

These observations support using the control-history marker as session evidence
on this V1 bike. They do not establish V2 hardware behavior, long-duration
retention, missing-event recovery on Android, or absence of interference from
other BLE clients. The probe used no-op control fields, so this experiment also
does not validate applying a complete real configuration plan with a marker.

Probe source, local marker state, and logs are in the Git-ignored
`scratch/ble_session_probe` directory. Authentication values are not logged.

### Broader hardware validation

On each firmware, send a valid control command carrying a marker in bytes 5–9
and verify its history readback. Reconnect repeatedly without powering off, toggle
phone Bluetooth, and restart the app process: the marker should survive. Change
settings using physical controls: the marker should remain while live settings
change. Then test normal power-off/on and quick power cycles: the control record
should return to its startup seed. Repeat with full battery removal, prolonged
telemetry, and another BLE client.

Record the selected ID, cache-barrier success, returned control record, and actual
bike power state. Do not include authentication secrets or responses. Only after
these observations agree with the static analysis should the marker replace the
current presence latch as the primary deduplication evidence.
