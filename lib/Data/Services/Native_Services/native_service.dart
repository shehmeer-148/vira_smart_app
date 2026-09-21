import 'package:flutter/services.dart';

class NativeService {
  static const MethodChannel _channel =
  MethodChannel('vira/native');

  Future<String> getNativeMessage() async {
    final result = await _channel.invokeMethod<String>(
      'getNativeMessage',
    );

    return result ?? '';
  }
  Future<int> getBatteryInfo() async {
    final result = await _channel.invokeMethod<int>(
      'getBatteryInfo',
    );

    return result ?? 0;
  }
}