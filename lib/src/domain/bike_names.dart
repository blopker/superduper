const _adjectives = <String>[
  'Brave',
  'Bright',
  'Calm',
  'Clever',
  'Electric',
  'Gentle',
  'Happy',
  'Lucky',
  'Mighty',
  'Rapid',
  'Silver',
  'Steady',
  'Swift',
  'Velvet',
  'Wild',
  'Zippy',
];

const _animals = <String>[
  'Badger',
  'Bear',
  'Falcon',
  'Fox',
  'Hare',
  'Heron',
  'Jaguar',
  'Lynx',
  'Otter',
  'Owl',
  'Panda',
  'Raven',
  'Seal',
  'Tiger',
  'Wolf',
  'Wren',
];

String defaultBikeName(String deviceId) {
  var hash = 0x811c9dc5;
  for (final codeUnit in deviceId.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  final adjective = _adjectives[hash % _adjectives.length];
  final animal = _animals[(hash ~/ _adjectives.length) % _animals.length];
  return '$adjective $animal';
}
