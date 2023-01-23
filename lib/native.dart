import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const platform = MethodChannel('io.kbl.superduper/native');

init() {
  print('init native');
  platform.setMethodCallHandler((call) {
    print(call);
    return Future.value('ok');
  });
}

enum NativeMethod {
  getBatteryLevel,
}

Future<T> call<T>(NativeMethod method) async {
  try {
    final T result = await platform.invokeMethod(method.name);
    return result;
  } on PlatformException catch (e) {
    debugPrint("Failed to get result: '${e.message}'.");
    rethrow;
  }
}

Future<int> getBatteryLevel() {
  return call<int>(NativeMethod.getBatteryLevel);
}
