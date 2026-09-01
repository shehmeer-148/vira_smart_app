import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleHelper {
  static QualifiedCharacteristic characteristic({
    required String deviceId,
    required Uuid service,
    required Uuid characteristic,
  }) {
    return QualifiedCharacteristic(
      serviceId: service,
      characteristicId: characteristic,
      deviceId: deviceId,
    );
  }
}