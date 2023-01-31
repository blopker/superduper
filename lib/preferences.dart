import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const boxKey = 'pref';

final prefProvider = Provider((ref) {
  return Preferences(ref);
});

class Preferences {
  Preferences(this.ref);
  final Ref ref;

  get pref {
    return Hive.box(boxKey);
  }

  Future<Map<String, dynamic>?> getJson(String id) async {
    String? data = pref.get(id);
    if (data == null) {
      return null;
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> setJson(String id, Map data) async {
    return pref.put(id, jsonEncode(data));
  }
}

Future init() async {
  print('OPENBOX');
  await Hive.initFlutter();
  return await Hive.openBox(boxKey);
}
