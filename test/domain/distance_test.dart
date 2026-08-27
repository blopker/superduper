import 'package:flutter_test/flutter_test.dart';
import 'package:superduper/src/domain/distance.dart';

void main() {
  test('formats an odometer reading in kilometers and miles', () {
    expect(
      formatOdometerDistance(1609344),
      '1609.3 km · 1000.0 mi',
    );
  });

  test('rejects a negative odometer reading', () {
    expect(() => formatOdometerDistance(-1), throwsRangeError);
  });
}
