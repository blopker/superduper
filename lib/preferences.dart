import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefProvider = Provider((ref) {
  return Preferences(ref);
});

class Preferences {
  final pref = SharedPreferences.getInstance();
  Preferences(this.ref);
  final Ref ref;

  Future<Map<String, dynamic>?> getJson(String id) async {
    var data = (await pref).getString(id);
    if (data == null) {
      return null;
    }
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<bool> setJson(String id, Map data) async {
    return (await pref).setString(id, jsonEncode(data));
  }
}
