import 'package:flutter_test/flutter_test.dart';

import 'package:superduper/utils.dart';

void main() {
  test('test utils', () {
    // Build our app and trigger a frame.
    var r = strToLis('00D1 0104 0100 0000 0000');
    print(r);
    // Verify that our counter has incremented.
    expect(r, []);
  });
}
