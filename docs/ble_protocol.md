# BLE protocol

This document describes the BLE behavior recovered from the `221122` and
`250426` display application firmwares. It calls the `221122` interface
**protocol v1** and the `250426` interface **protocol v2**. It is a
reverse-engineered implementation description, not a vendor protocol
specification.

Only behavior supported directly by the firmware is documented as fact. Fields whose purpose is not established are called `unknown` or `reserved` rather than guessed.

## Device identity and advertising

The GAP device name differs by protocol version:

| Protocol | Display firmware | Complete advertised name |
| --- | --- | --- |
| v1 | `221122` | `SUPER73` |
| v2 | `250426` | `S73 FTEX` |

The advertised name is the recommended protocol discriminator. `FTEX` identifies
the newer motor-controller architecture used by protocol v2. A client can select
the packet layout during scanning, before connecting:

- `SUPER73` selects protocol v1;
- `S73 FTEX` selects protocol v2;
- any other name leaves the protocol unknown.

Device Information remains useful as confirmation after connecting and as a
fallback when the platform's scan API does not expose the complete local name.

The advertising data contains:

- the complete local name;
- flags `0x06` (LE General Discoverable Mode and BR/EDR Not Supported);
- manufacturer-specific data using company identifier `0x020f`;
- eight manufacturer-data bytes derived from the nRF52832 `FICR.DEVICEID` words.

The firmware does not place its custom service UUIDs in the advertising data.

Advertising uses an interval of `0x280` BLE units, or 400 ms. The configured fast-advertising duration is zero, so advertising does not time out through this setting.

Preferred connection parameters are:

| Parameter | Value |
| --- | ---: |
| Minimum interval | 15 ms |
| Maximum interval | 45 ms |
| Slave latency | 0 |
| Supervision timeout | 4 s |

The standard Device Information Service is also initialized. Its manufacturer string is `COMODULE`, and it includes the exact version strings described below. The per-chip identifier is present in manufacturer advertising data but, because of an initialization-order bug, not in the intended Device Information Serial Number characteristic. `COMODULE` is service metadata; it is not the advertised GAP name.

## Security model

There are two separate security layers.

### BLE pairing and bonding

Peer Manager is configured for legacy bonded pairing with:

- bonding enabled;
- no MITM protection;
- no LE Secure Connections;
- no input/output capability;
- encryption key sizes from 7 through 16 bytes;
- encryption and identity key distribution in both directions.

This is effectively encrypted “Just Works” bonding. The custom GATT attributes are configured for Security Mode 1, Level 2, so the link must be encrypted before they can be used. The standard Device Information strings are configured for open reads and do not require this encryption or the application authentication layer.

### Application authentication

The firmware additionally implements its own 20-byte challenge/response protocol. Successful BLE pairing is not sufficient for normal commands and notifications.

The intended authentication flow is:

1. The authenticated-state byte is zero before authentication.
2. The device generates a new 20-byte challenge.
3. The client reads the challenge characteristic.
4. The client computes `SHA1(challenge || key)`.
5. The client writes the resulting 20-byte digest to the response characteristic.
6. An exact match changes the authenticated-state byte to one.

An incorrect response causes the firmware to request link termination. Protocol
v2 returns authentication state to zero on disconnect. Protocol v1 contains a
bug that instead sets it to one in its disconnect handler. Clients must not rely
on that bug: perform the challenge and verify the state on every connection.

The key is 20 bytes. On a device with no key record in FDS, the firmware creates a record containing 20 bytes of `0xff`. An authenticated client can replace the key through the key-update characteristic; the new key is written to FDS and the old record is deleted.

Equivalent response calculation:

```python
import hashlib

challenge = bytes.fromhex("...")  # exactly 20 bytes read from UUID 0x2556
key = b"\xff" * 20                # first-boot default only
response = hashlib.sha1(challenge + key).digest()
assert len(response) == 20
```

The challenge itself is derived from the nRF RTC1 counter through SHA-1. A client does not need to reproduce challenge generation; it only needs the value read from the characteristic.

## GATT services

### COMODULE data service

The custom 128-bit UUID base is:

```text
00000000-1212-EFDE-1523-785FEABCD123
```

| Role | Short UUID | Full UUID | Properties | Fixed size |
| --- | ---: | --- | --- | ---: |
| Service | `0x1554` | `00001554-1212-EFDE-1523-785FEABCD123` | — | — |
| TX packet | `0x155e` | `0000155E-1212-EFDE-1523-785FEABCD123` | Read, Notify | 10 bytes |
| RX packet | `0x155f` | `0000155F-1212-EFDE-1523-785FEABCD123` | Read, Write | 10 bytes |
| History selector | `0x1564` | `00001564-1212-EFDE-1523-785FEABCD123` | Read, Write | 2 bytes |

Writes use the ordinary GATT Write property; Write Without Response is not enabled by the characteristic metadata.

The TX characteristic carries ordinary telemetry records and the bulk-transfer packets described below. Notifications are only attempted after application authentication succeeds.

### Authentication service

The authentication service uses the same 128-bit base.

| Role | Short UUID | Full UUID | Properties | Fixed size |
| --- | ---: | --- | --- | ---: |
| Service | `0x2554` | `00002554-1212-EFDE-1523-785FEABCD123` | — | — |
| Key update | `0x2555` | `00002555-1212-EFDE-1523-785FEABCD123` | Write | 20 bytes |
| Challenge | `0x2556` | `00002556-1212-EFDE-1523-785FEABCD123` | Read | 20 bytes |
| Response | `0x2557` | `00002557-1212-EFDE-1523-785FEABCD123` | Write | 20 bytes |
| Authenticated state | `0x2558` | `00002558-1212-EFDE-1523-785FEABCD123` | Read | 1 byte |

The key-update write is ignored unless the current connection has already passed application authentication.

### Auxiliary service

The firmware also creates a 16-bit service `0x1580` with characteristic `0x1581`. The characteristic is used for a periodic counter-like notification. Its higher-level purpose and complete three-byte payload format are not established, so they are intentionally not assigned names here.

### Nordic buttonless DFU service

The application initializes Nordic's buttonless DFU service independently of the COMODULE packet service:

| Role | UUID | Properties |
| --- | --- | --- |
| Service | `0xFE59` | — |
| Control point | `8EC90003-F315-4F60-9FB8-838830DAEA50` | Write, Indicate |

After the enter-bootloader response indication is confirmed, the service calls the application prepare event, clears retained `GPREGRET` register 0, sets it to the bootloader-enter magic `0xB1`, requests SoftDevice shutdown, and system-resets. The application prepare callback selects firmware-update UI state `0x10` before shutdown. `GPREGRET2` is separate and retains the target class selected by `F0CC`.

### Standard Device Information Service

The standard Device Information Service (`0x180a`) is present in both protocols.
It provides a pre-authentication fallback or confirmation for the advertised-name
selection:

| Characteristic | UUID | Protocol v1 | Protocol v2 |
| --- | ---: | --- | --- |
| Manufacturer Name | `0x2a29` | `COMODULE` | `COMODULE` |
| Hardware Revision | `0x2a27` | `v3.2.0` | `v3.3.0` |
| Firmware Revision | `0x2a26` | `221122` | `250426` |
| Software Revision | `0x2a28` | `221122` | `250426` |

The assignments are literal. The decimal build string is used for both Firmware
Revision and Software Revision. Read Firmware Revision (`0x2a26`) and select v1
only for `221122`, or v2 only for `250426`. Treat unknown build strings as an
unknown protocol rather than assigning them by numeric ordering. If the name and
revision disagree, do not send a control command until the combination is
understood.

The firmware appears intended to expose a Serial Number (`0x2a25`) formatted as `%08x%08x` from `FICR.DEVICEID1` and `FICR.DEVICEID0`, but it fills that Device Information initializer slot only after creating the service. Consequently, neither analyzed firmware actually adds the Serial Number characteristic. The same per-chip identifier remains available in advertising manufacturer data: the company identifier is the fixed value `0x020f`, followed by eight payload bytes containing `DEVICEID1` and `DEVICEID0` in big-endian order.

The official Android app uses this advertising payload as the module serial. It calls `getManufacturerSpecificData(527)`, converts the returned eight bytes to hexadecimal without separators, lowercases the result, and matches it against the cached connection serial. The firmware-update check sends that same string as the `moduleId` path parameter to `module/{moduleId}/update`; it does not obtain the update-check identifier from Device Information characteristic `0x2a25`.

These characteristics use open-read permissions. A client can therefore
fingerprint the display firmware without completing pairing or custom SHA-1
authentication.

## Ten-byte application packet format

Both normal RX commands and TX telemetry use fixed 10-byte packets:

```text
offset  size  meaning
0       2     packet ID, big-endian
2       8     packet-specific payload
```

The RX handler rejects normal commands unless the write length is exactly 10 bytes and application authentication has succeeded. The one observed exception is packet `F0CC`, which bypasses both checks in the handler. The characteristic has a 10-byte maximum and requires an encrypted BLE link, but the `F0CC` branch itself does not verify the actual write length before reading its fields.

Unless a packet section says otherwise, unused bytes should be zero.

## RX commands

### `00D1`: protocol v1 vehicle controls

Protocol v1 writes this packet to RX characteristic `0x155f`:

```text
offset  size  meaning
0       2     00 D1
2       1     lights: accepted values 0 or 1
3       1     assist level: accepted values 0 through 4
4       1     legacy motor operating mode: accepted values 0 through 11
5       5     unused by this handler
```

The legacy operating mode is a motor-control algorithm selector, not a protocol
v2 ride preset. In the paired legacy controller, modes 0 through 3 are the
non-EU/cadence family; mode 4 and higher select the EU/torque-sensor and other
control paths.

Example:

```text
00 D1 01 03 01 00 00 00 00 00
```

This requests lights on, assist level 3, and legacy operating mode 1.

### `00C1`: protocol v2 vehicle controls

```text
offset  size  meaning
0       2     00 C1
2       1     lights: accepted values 0 or 1
3       1     assist level: accepted values 0 through 4
4       1     ride mode: accepted values 0 through 3
5       5     unused by this handler
```

Each field is range-checked independently. An invalid field does not prevent valid fields in the same packet from being applied.

The command updates the controller-facing light state, assist level, and ride-mode field. It does not generate a dedicated command-response packet.

The ride preset is independent of assist level. It selects these two
motor-controller CANopen settings:

| Ride preset | `0x201c:0` global speed cap | `0x2027:4` throttle |
| ---: | ---: | --- |
| 0 | 32% | Disabled |
| 1 | 32% | Enabled |
| 2 | 45% | Disabled |
| 3 | 99% | Enabled |

Example:

```python
packet = bytes.fromhex("00 c1 01 03 02 00 00 00 00 00")
# lights on, assist level 3, ride mode 2
```

### `F000`: clock and timezone

```text
offset  size  encoding       meaning
0       2     big-endian     F0 00
2       4     big-endian u32 Unix time
6       2     big-endian i16 timezone offset in minutes
8       2                  unused by this handler
```

The timestamp is applied with BLE as its source. The firmware rejects timestamps at or below `0x5a497a00`.

Packet construction:

```python
import struct

packet = struct.pack(">HIh", 0xF000, unix_time, timezone_minutes) + b"\x00\x00"
assert len(packet) == 10
```

### `F0AA`: navigation update

```text
offset  size  encoding       meaning
0       2     big-endian     F0 AA
2       2     big-endian i16 navigation angle in degrees
4       4     big-endian u32 distance
8       1                  navigation state/control value
9       1                  maneuver/exit value
```

Confirmed behavior for byte 8:

- `1` stores angle, distance, and byte 9, and selects or updates the navigation display where allowed by the current UI state;
- `2` changes the UI state when navigation is on one particular screen;
- `0` exits one of the navigation UI states;
- other values do not update the navigation fields.

The precise product-level names for the byte-8 states are not established. Byte 9 is retained as an unsigned byte and is displayed numerically for values 1 through 9 in one navigation rendering path.

Packet construction:

```python
import struct

packet = struct.pack(">HhIBB", 0xF0AA, angle_degrees, distance, nav_state, maneuver)
assert len(packet) == 10
```

### `F0CC`: firmware-update preflight

This packet is handled before the application-authentication and length checks. It is written to encrypted RX characteristic `0x155F`; it is not a firmware-data packet.

```text
offset  size  encoding       meaning
0       2     big-endian     F0 CC
2       1                  request selector
3       4     big-endian u32 expected fixed-region CRC32
7       1                  file selector for request type 0x80
8       2                  unused by this handler
```

Confirmed selector behavior:

- `0x01` selects request class `0x20` and queues a primary STM32-image request;
- `0x80` selects request class `0x80` and queues an external/motor-file request using bytes 3–6 and byte 7;
- other selector values select request class `0x40`, but this handler does not queue either external-flash request.

For class `0x80`, the application performs these directly observed steps:

1. Clear `GPREGRET2` bits 7–5 with SoftDevice SVC `0x3B`, then set them to `0x80` with SVC `0x3A`. The bootloader later reads these retained bits as the request class.
2. Queue the expected CRC32 and file selector. When the external-flash validator reaches stable state 5, it erases the external-file bank and creates the 9-byte header `crc32_be | FC | FF FF FF | selector`.
3. The client uses the Nordic buttonless DFU control point. After its response indication is confirmed, the application selects update UI state `0x10`, writes bootloader-enter magic `0xB1` to retained `GPREGRET`, shuts down the SoftDevice, and resets.
4. The bootloader sees both `GPREGRET == 0xB1` and request class `0x80` in `GPREGRET2`. It requires a signed Secure DFU init packet whose custom class is also `0x80` and streams the raw `.bin` data objects to the external-file bank at header offset `+9`.
5. A fixed-`0x7000` CRC32 check changes header status from `0xFC` to `0xF0`; the declared `.bin` size is written as a big-endian 24-bit value at offsets 5–7. The selector at offset 8 is preserved.
6. On the next application run, a status of `0xF0` plus a nonzero size makes the image eligible for the automatic CANopen motor-controller transfer described in `docs/can_protocol.md`.

The `F0CC` handler itself neither carries image bytes nor resets the device; buttonless DFU is the distinct control path that performs the reset.

### `F0DC`: bulk-transfer control and acknowledgement

Incoming format:

```text
offset  size  meaning
0       2     F0 DC
2       1     transfer control/request flag
3       1     acknowledgement flag
4       6     unused by this handler
```

- Byte 2 equal to zero stops/clears the active transfer.
- Byte 2 nonzero requests transfer/status processing.
- Byte 3 is copied into the acknowledgement flag used by transfer completion.

This command shares its packet ID with an outgoing status/completion packet.

## TX packets

### Ordinary telemetry records

The device cycles through controller fields marked for BLE export, packs fields sharing an ID into one 10-byte record, and notifies the TX characteristic when the record has changed. Multi-byte payload fields in these records are little-endian even though the two-byte packet ID is big-endian.

Protocol v2 exports IDs `D0`, `D1`, `D2`, and `D9`:

#### `00D0`

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     00 D0
2       1                  displayed PAS/assist value
3       1                  unknown
4       1                  light state
5       1                  state of charge, percent
6       4     little-endian  total distance; display scaling is raw * 0.001
```

#### `00D1`

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     00 D1
2       2     little-endian  speed
4       2     little-endian  range
6       2     little-endian  voltage; display scaling is raw * 0.01 V
8       2     little-endian  BMS error value, displayed in decimal
```

Speed is displayed in km/h or mph, and range in km or mi, according to the unit setting. The imperial conversion used by the UI is approximately `metric * 10 / 16`.

#### `00D2`

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     00 D2
2       4     little-endian  unknown
6       4     little-endian  MCU error value, displayed in hexadecimal
```

#### `00D9`

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     packet ID 00 D9
2       2     little-endian  local coin-cell voltage in millivolts
4       1                  RTC time-source enum
5       1                  BLE-selected ride mode
6       2     little-endian  MCU/controller version parsed from CANopen 0x2008:00
8       2     little-endian  BMS version/value parsed from CAN ID 0x466
```

The `MCU` value shown on the LCD `bike info` screen comes from the same CANopen `0x2008:00` source as bytes 6–7. Consequently, `00D9` provides the useful part of that otherwise version-dependent screen over BLE.

The `00D0` assist field is the display/controller value associated with the
selected level, not necessarily the raw assist index 0 through 4. The raw level
is written to motor-controller object `0x2003:0`.

### `F0CD`: bulk data chunk

```text
offset  size  meaning
0       2     F0 CD
2       8     data bytes
```

The transfer buffer is sent in chunks of at most eight bytes. The last chunk is zero-padded because the packet buffer is cleared before it is filled. These notifications use a send path that does not suppress identical consecutive packets.

### `F0DC`: bulk-transfer status/completion

Outgoing packets have this shape:

```text
offset  size  encoding       meaning
0       2     big-endian     F0 DC
2       2                  zero
4       2     big-endian u16 transfer length/state value
6       1                  pending/status value
7       3                  zero
```

At completion, the firmware waits for a nonzero acknowledgement flag supplied in byte 3 of an incoming `F0DC` packet. If acknowledgement times out, it restores the external-flash read position.

The higher-level meaning of every status value is not fully established, so no symbolic status enumeration is assigned here.

## Packet history characteristic

The firmware maintains a 30-entry history of 10-byte records. Records are keyed by their first two bytes:

- inserting an identical record changes nothing;
- a changed record with an existing ID moves to the front;
- a new ID is inserted at the front and the oldest entry is dropped when full.

After application authentication, write a two-byte big-endian packet ID to
characteristic `0x1564`. If that ID exists, the matching 10-byte record is copied
into RX/result characteristic `0x155f`. Read `0x155f` and verify that its first
two bytes match the requested ID. If the ID is absent, `0x155f` remains unchanged,
so validation is mandatory. The selector does not request a notification.

Example for the latest protocol v2 `00D1` telemetry record:

```python
history_selector = bytes.fromhex("00 d1")
```

The history-selector write must be exactly two bytes. It does not itself request a TX notification.

### Version and identity history records

The layouts in this subsection are confirmed for protocol v2.

`controller_history_snapshot_push` also creates three non-telemetry records. They
are inserted into the same history and can be retrieved by writing their two-byte
ID to `0x1564`, then reading the 10-byte value from `0x155f`.

#### `FCFC`: display/STM version state

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     FC FC
2       3     big-endian     low 24 bits of STM firmware version
5       2     little-endian  controller variant code (normally 406 or 407)
7       1                  bootloader handoff value: GPREGRET2 & 0x1f, normally 8
8       1                  unknown
9       1                  constant 1
```

This record exposes the dynamic values behind most of the LCD `versions` screen:

- the LCD top row is hard-coded `330-<controller variant>`;
- the middle row is `<bootloader handoff>-250426-0` in this binary;
- the bottom row is the STM firmware version from a checksum-valid `$STM,FW,...` UART report.

The record is refreshed when the STM firmware report or related controller state changes. Before the STM report arrives, its version field can still be zero.

#### `FAFA`: motor-controller and BMS versions

```text
offset  size  encoding       confirmed meaning
0       2     big-endian     FA FA
2       4     big-endian     full MCU/motor-controller version
6       4     big-endian     full BMS version/value
```

Unlike `00D9`, which exports 16-bit fields, `FAFA` retains both values as full 32-bit integers. Record `FAFB` is also inserted with an all-zero payload; its higher-level purpose is not established.

Equivalent decoding:

```python
def decode_version_record(packet: bytes) -> dict:
    if len(packet) != 10:
        raise ValueError("expected one 10-byte record")

    packet_id = packet[:2]
    if packet_id == b"\xfc\xfc":
        return {
            "stm_version": int.from_bytes(packet[2:5], "big"),
            "controller_variant": int.from_bytes(packet[5:7], "little"),
            "bootloader_handoff": packet[7],
            "unknown": packet[8],
            "marker": packet[9],
        }
    if packet_id == b"\xfa\xfa":
        return {
            "motor_controller_version": int.from_bytes(packet[2:6], "big"),
            "bms_version": int.from_bytes(packet[6:10], "big"),
        }
    raise ValueError(f"unsupported record ID: {packet_id.hex()}")
```

The history-selector handler requires successful application authentication in addition to the encrypted-link permissions on the custom characteristics.

### Reading control state through history

Protocol v1 exposes its legacy operating state in packet `0x0300`. Write `03 00`
to `0x1564`, read and validate `0x0300` from `0x155f`, then read the operating
mode from payload byte 3 (packet offset 5).

Protocol v2 uses two records:

| Selector | Returned field |
| --- | --- |
| `00 D0` | payload byte 0: displayed assist value; payload byte 2: lights |
| `00 D9` | payload byte 3: ride preset 0 through 3 |

The writable `00D1` or `00C1` value left in `0x155f` is not an authoritative
state snapshot and may not reflect subsequent physical-button changes.

### Authenticated protocol-identification fallback

The advertised name is preferred, followed by Device Information. If neither is
available or conclusive:

1. Select `0x00d9` and validate the returned ID. A valid record identifies v2.
2. Otherwise select `0x0300` and validate the returned ID. A valid record
   identifies v1.
3. If neither is returned, keep the protocol unknown.

Do not identify a protocol from an unchanged or mismatched `0x155f` value, and do
not probe by sending both control commands.

## Minimal client sequence

A client using the application protocol should:

1. Scan for the complete local name.
2. Select protocol v1 for `SUPER73` or protocol v2 for `S73 FTEX`.
3. For an unknown name, connect and read Device Information Firmware Revision
   UUID `0x2a26`; select v1 for `221122`, v2 for `250426`, or reject an unknown
   build.
4. Optionally read `0x2a26` even for a recognized name and require the expected
   name/revision pair.
5. Complete encrypted Just Works pairing or restore an existing bond.
6. Read the 20-byte authentication challenge from UUID `0x2556`.
7. Compute `SHA1(challenge || key)` and write the 20-byte digest to UUID `0x2557`.
8. Read state UUID `0x2558` and require byte value 1.
9. Enable notifications on TX UUID `0x155e`, or use selector `0x1564` followed
   by a validated read from `0x155f`.
10. Write the selected protocol's exact 10-byte control command to `0x155f`.

After connecting, the standard Device Information characteristics can be read
without pairing or application authentication. History selection requires both.

## Firmware analysis anchors

The following application functions are the primary evidence for this document:

| Address | Function |
| ---: | --- |
| `0x2c45a` | COMODULE TX characteristic creation |
| `0x2c54c` | COMODULE RX characteristic creation |
| `0x2c63e` | history-selector characteristic creation |
| `0x2c730` | COMODULE service creation and UUID base |
| `0x271ac` | standard Device Information characteristic creation and UUID mapping |
| `0x2c938` | authentication challenge generation |
| `0x2cd90` | authenticated key update |
| `0x2cdc0` | response verification |
| `0x2ce1c` | authentication service creation |
| `0x2d194` | ten-byte RX dispatcher |
| `0x2d3e8` | history-selector handler |
| `0x2d698` | GAP name and connection parameters |
| `0x2d738` | advertising-data construction |
| `0x2dc00` | Device Information strings (`v3.3.0`, `250426`) |
| `0x2dfbc` | ordinary telemetry record packing, including `00D9` |
| `0x2dea4`–`0x2e2a0` | bulk-transfer state and TX packet creation |
| `0x30120` | 30-entry packet-history insertion |
| `0x302e2` | `FCFC`, `FAFA`, and `FAFB` history-record construction |
| `0x303a4` | `$STM,FW,...` parser and STM-version producer |
| `0x32ba8` | CANopen `0x2008:00` parser and controller-version producer |
| `0x33234` | `00C1` vehicle-control handler |

The advertised name is initialized at flash address `0x47514` as the nine-byte string `S73 FTEX\0`.
