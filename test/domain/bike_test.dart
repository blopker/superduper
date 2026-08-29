import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/bike.dart';

void main() {
  group('BikeControlValues', () {
    test('defines the supported logical control values', () {
      expect(BikeControlValues.modes, [0, 1, 2, 3]);
      expect(BikeControlValues.assistLevels, [0, 1, 2, 3, 4]);
    });

    test('recognizes valid modes and assist levels', () {
      expect(BikeControlValues.isValidMode(0), isTrue);
      expect(BikeControlValues.isValidMode(3), isTrue);
      expect(BikeControlValues.isValidMode(-1), isFalse);
      expect(BikeControlValues.isValidMode(4), isFalse);

      expect(BikeControlValues.isValidAssist(0), isTrue);
      expect(BikeControlValues.isValidAssist(4), isTrue);
      expect(BikeControlValues.isValidAssist(-1), isFalse);
      expect(BikeControlValues.isValidAssist(5), isFalse);
    });

    test('rejects values outside the supported ranges', () {
      expect(() => BikeControlValues.validateMode(-1), throwsRangeError);
      expect(() => BikeControlValues.validateMode(4), throwsRangeError);
      expect(() => BikeControlValues.validateAssist(-1), throwsRangeError);
      expect(() => BikeControlValues.validateAssist(5), throwsRangeError);
    });
  });
}
