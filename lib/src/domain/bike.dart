enum BikeProtocolVersion {
  v1('SUPER73'),
  v2('S73 FTEX');

  const BikeProtocolVersion(this.advertisedName);

  final String advertisedName;

  static BikeProtocolVersion? fromAdvertisedName(String name) {
    return switch (name) {
      'SUPER73' => BikeProtocolVersion.v1,
      'S73 FTEX' => BikeProtocolVersion.v2,
      _ => null,
    };
  }
}

enum BikeRegion {
  us('US'),
  eu('EU');

  const BikeRegion(this.label);

  final String label;
}

enum BikeColor {
  royalHorizon('royal_horizon', 'Royal Horizon', 0),
  oceanMirage('ocean_mirage', 'Ocean Mirage', 1),
  sunsetBlaze('sunset_blaze', 'Sunset Blaze', 2),
  electricMeadow('electric_meadow', 'Electric Meadow', 3),
  berryPop('berry_pop', 'Berry Pop', 4),
  cottonCandy('cotton_candy', 'Cotton Candy', 5),
  mysticTwilight('mystic_twilight', 'Mystic Twilight', 6),
  aquaFresh('aqua_fresh', 'Aqua Fresh', 7),
  fieryFuchsia('fiery_fuchsia', 'Fiery Fuchsia', 8),
  peachCream('peach_cream', 'Peach Cream', 9),
  emeraldWave('emerald_wave', 'Emerald Wave', 10),
  pastelDream('pastel_dream', 'Pastel Dream', 11),
  lavenderHaze('lavender_haze', 'Lavender Haze', 12),
  mintMagic('mint_magic', 'Mint Magic', 13),
  bubblegum('bubblegum', 'Bubblegum', 14),
  skyBreeze('sky_breeze', 'Sky Breeze', 15),
  blueLagoon('blue_lagoon', 'Blue Lagoon', 16),
  frostedMint('frosted_mint', 'Frosted Mint', 17),
  deepSpace('deep_space', 'Deep Space', 18),
  silverMist('silver_mist', 'Silver Mist', 19),
  stormyGray('stormy_gray', 'Stormy Gray', 20),
  midnightOcean('midnight_ocean', 'Midnight Ocean', 21),
  sunKissed('sun_kissed', 'Sun Kissed', 22),
  iceDrop('ice_drop', 'Ice Drop', 23),
  purpleRain('purple_rain', 'Purple Rain', 24),
  vanillaLatte('vanilla_latte', 'Vanilla Latte', 25),
  pureWhite('pure_white', 'Pure White', 26),
  darkMode('dark_mode', 'Dark Mode', 27),
  neonCyber('neon_cyber', 'Neon Cyber', 28),
  synthwave('synthwave', 'Synthwave', 29),
  pixelBlue('pixel_blue', 'Pixel Blue', 30),
  midnightSky('midnight_sky', 'Midnight Sky', 31);

  const BikeColor(this.key, this.displayName, this.legacyIndex);

  final String key;
  final String displayName;
  final int legacyIndex;

  static final List<BikeColor> displayOrder = List.unmodifiable(
    values.toList()
      ..sort((left, right) => left.displayName.compareTo(right.displayName)),
  );

  static BikeColor defaultForDeviceId(String deviceId) {
    final normalizedDeviceId = deviceId.trim().toLowerCase();
    if (normalizedDeviceId.isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', 'must not be empty');
    }

    var hash = 5381;
    for (final character in normalizedDeviceId.runes) {
      hash = ((hash * 33) + character) % 0x100000000;
    }
    return values[hash % values.length];
  }

  static BikeColor? fromKey(String key) {
    for (final color in values) {
      if (color.key == key) {
        return color;
      }
    }
    return null;
  }

  static BikeColor? fromLegacyIndex(int index) {
    if (index < 0 || index >= values.length) {
      return null;
    }
    return values[index];
  }
}

final class Bike {
  const Bike({
    required this.deviceId,
    required this.displayName,
    required this.protocol,
    required this.region,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.lastConnectedAt,
    this.advertisedName = 'SUPER73',
    this.moduleSerial,
  });

  final String deviceId;
  final String displayName;
  final String advertisedName;
  final BikeProtocolVersion protocol;
  final BikeRegion? region;
  final BikeColor color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConnectedAt;
  final String? moduleSerial;
}

final class BikeVersionInfo {
  const BikeVersionInfo({
    required this.hardwareRevision,
    required this.firmwareRevision,
    required this.softwareRevision,
    required this.stmFirmwareVersion,
    required this.controllerVariant,
    required this.bootloaderHandoff,
    required this.motorControllerVersion,
    required this.bmsVersion,
  });

  final String hardwareRevision;
  final String firmwareRevision;
  final String softwareRevision;
  final int stmFirmwareVersion;
  final int controllerVariant;
  final int bootloaderHandoff;
  final int motorControllerVersion;
  final int bmsVersion;

  @override
  bool operator ==(Object other) {
    return other is BikeVersionInfo &&
        hardwareRevision == other.hardwareRevision &&
        firmwareRevision == other.firmwareRevision &&
        softwareRevision == other.softwareRevision &&
        stmFirmwareVersion == other.stmFirmwareVersion &&
        controllerVariant == other.controllerVariant &&
        bootloaderHandoff == other.bootloaderHandoff &&
        motorControllerVersion == other.motorControllerVersion &&
        bmsVersion == other.bmsVersion;
  }

  @override
  int get hashCode => Object.hash(
    hardwareRevision,
    firmwareRevision,
    softwareRevision,
    stmFirmwareVersion,
    controllerVariant,
    bootloaderHandoff,
    motorControllerVersion,
    bmsVersion,
  );
}

final class CachedBikeVersions {
  const CachedBikeVersions({required this.info, required this.readAt});

  final BikeVersionInfo info;
  final DateTime readAt;
}

final class CachedBikeOdometer {
  const CachedBikeOdometer({required this.meters, required this.readAt});

  final int meters;
  final DateTime readAt;
}

final class SetOnConnectSettings {
  const SetOnConnectSettings({
    required this.lightEnabled,
    required this.mode,
    required this.modeEnabled,
    required this.assist,
    required this.assistEnabled,
  });

  const SetOnConnectSettings.defaults()
    : lightEnabled = false,
      mode = 0,
      modeEnabled = false,
      assist = 0,
      assistEnabled = false;

  final bool lightEnabled;
  final int mode;
  final bool modeEnabled;
  final int assist;
  final bool assistEnabled;

  SetOnConnectSettings copyWith({
    bool? lightEnabled,
    int? mode,
    bool? modeEnabled,
    int? assist,
    bool? assistEnabled,
  }) {
    return SetOnConnectSettings(
      lightEnabled: lightEnabled ?? this.lightEnabled,
      mode: mode ?? this.mode,
      modeEnabled: modeEnabled ?? this.modeEnabled,
      assist: assist ?? this.assist,
      assistEnabled: assistEnabled ?? this.assistEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SetOnConnectSettings &&
        lightEnabled == other.lightEnabled &&
        mode == other.mode &&
        modeEnabled == other.modeEnabled &&
        assist == other.assist &&
        assistEnabled == other.assistEnabled;
  }

  @override
  int get hashCode => Object.hash(
    lightEnabled,
    mode,
    modeEnabled,
    assist,
    assistEnabled,
  );
}

const backgroundSyncConsentVersion = 2;

final class BackgroundPreference {
  const BackgroundPreference({
    required this.requested,
    required this.consentVersion,
  });

  const BackgroundPreference.defaults() : requested = false, consentVersion = 0;

  final bool requested;
  final int consentVersion;
}

final class SavedBike {
  const SavedBike({
    required this.bike,
    required this.setOnConnect,
    this.backgroundPreference = const BackgroundPreference.defaults(),
    this.versions,
    this.odometer,
  });

  final Bike bike;
  final SetOnConnectSettings setOnConnect;
  final BackgroundPreference backgroundPreference;
  final CachedBikeVersions? versions;
  final CachedBikeOdometer? odometer;
}

final class BikeNotFoundException implements Exception {
  const BikeNotFoundException(this.deviceId);

  final String deviceId;

  @override
  String toString() => 'No saved bike exists for device ID "$deviceId".';
}

final class BikeAlreadyExistsException implements Exception {
  const BikeAlreadyExistsException(this.deviceId);

  final String deviceId;

  @override
  String toString() => 'A bike with device ID "$deviceId" is already saved.';
}
