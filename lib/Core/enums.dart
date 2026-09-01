enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}
enum ConnectResult {
  connected,
  bluetoothNotReady,
  alreadyConnecting,
  deviceNotFound,
  connectionFailed,
}
enum LowBatteryFlag {
  ok,
  low,
  unknown,
}

extension LowBatteryFlagExtension on LowBatteryFlag {
  String get title {
    switch (this) {
      case LowBatteryFlag.ok:
        return "Battery OK";

      case LowBatteryFlag.low:
        return "Low Battery";

      case LowBatteryFlag.unknown:
        return "Unknown";
    }
  }
}

//======================================================================//

enum TankStatus {
  ok,
  empty,
  noSensor,
  unknown,
}

extension TankStatusExtension on TankStatus {
  String get title {
    switch (this) {
      case TankStatus.ok:
        return "Tank OK";

      case TankStatus.empty:
        return "Tank Empty";

      case TankStatus.noSensor:
        return "No Sensor";

      case TankStatus.unknown:
        return "Unknown";
    }
  }
}