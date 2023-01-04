import 'package:flutter_test/flutter_test.dart';

import 'package:superduper/utils.dart';
import 'package:superduper/services.dart';

void main() {
  test('test utils', () {
    var r = strToLis('00D1 0104 0100 0000 0000');
    expect(r, [0, 209, 1, 4, 1, 0, 0, 0, 0, 0]);
  });

  test('bike state', () {
    var lightOn = strToLis('03000400010100000000');
    var lightOff = strToLis('03000400000100000000');
    var state = BikeState(lightOff);
    expect(state.lightOn, false);
    state = BikeState(lightOn);
    expect(state.lightOn, true);
    var assist4mode3 = strToLis('03000400000300000000');
    var assist3mode2 = strToLis('03000300000200000000');
    state = BikeState(assist4mode3);
    expect(state.assist, 4);
    expect(state.mode, 3);
    state = BikeState(assist3mode2);
    expect(state.assist, 3);
    expect(state.mode, 2);
    state.mode = 3;
    expect(state.mode, 3);
    expect(state.lightOn, false);
    state.light = 1;
    expect(state.lightOn, true);
    state.mode = 1;
    expect(state.lightOn, true);
    expect(state.write(), [0, 209, 1, 3, 1, 0, 0, 0, 0, 0]);
    state.light = 0;
    expect(state.write(), [0, 209, 0, 3, 1, 0, 0, 0, 0, 0]);
    state.mode = 3;
    expect(state.write(), [0, 209, 0, 3, 3, 0, 0, 0, 0, 0]);
  });
}
