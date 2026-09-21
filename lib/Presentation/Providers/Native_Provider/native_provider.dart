import 'package:flutter/foundation.dart';

import '../../../Data/Services/Native_Services/native_service.dart';

class NativeProvider extends ChangeNotifier {
  final NativeService _nativeService;

  NativeProvider(this._nativeService);

  String _message = '';
  String get message => _message;

  int _battery = 0;
  int get battery => _battery;

  Future<void> getNativeMessage() async {
    _message = await _nativeService.getNativeMessage();
    notifyListeners();
  }

  Future<void> getBatteryInfo() async {
    _battery = await _nativeService.getBatteryInfo();
    notifyListeners();
  }
}