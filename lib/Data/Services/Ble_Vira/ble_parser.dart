import 'dart:convert';
import 'dart:typed_data';

import '../../../Core/enums.dart';

class BleParser {
  /// UTF8 String
  static String parseString(List<int> bytes) {
    return utf8.decode(bytes).replaceAll('\u0000', '');
  }

  /// uint8
  static int parseUint8(List<int> bytes) {
    return bytes.first;
  }

  /// uint16 (Little Endian)
  static int parseUint16(List<int> bytes) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return data.getUint16(0, Endian.little);
  }

  /// uint32 (Little Endian)
  static int parseUint32(List<int> bytes) {
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return data.getUint32(0, Endian.little);
  }

  /// UUID Parser
  static String parseUuid(List<int> bytes) {
    if (bytes.length != 16) {
      return "Invalid UUID";
    }

    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return "${hex.substring(0, 8)}-"
        "${hex.substring(8, 12)}-"
        "${hex.substring(12, 16)}-"
        "${hex.substring(16, 20)}-"
        "${hex.substring(20)}";
  }

  /// firmware Version parser
  static String parseFirmwareVersion(List<int> bytes) {
    if (bytes.length < 3) {
      return "Unknown";
    }

    final major = bytes[0];
    final minor = bytes[1];
    final patch = bytes[2];

    return "$major.$minor.$patch";
  }

  ///   low Battery Parser
  static LowBatteryFlag parseLowBatteryFlag(List<int> bytes) {
    if (bytes.isEmpty) {
      return LowBatteryFlag.unknown;
    }

    switch (bytes.first) {
      case 0x00:
        return LowBatteryFlag.ok;

      case 0x01:
        return LowBatteryFlag.low;

      default:
        return LowBatteryFlag.unknown;
    }
  }

  ///   tank Status Parser
  static TankStatus parseTankStatus(List<int> bytes) {
    if (bytes.isEmpty) {
      return TankStatus.unknown;
    }

    switch (bytes.first) {
      case 0x00:
        return TankStatus.ok;

      case 0x01:
        return TankStatus.empty;

      case 0xFF:
        return TankStatus.noSensor;

      default:
        return TankStatus.unknown;
    }
  }

  static BleSchedule parseSchedule(List<int> bytes) {

    final daysMask = bytes[0];

    final timeMinutes =
    bytes[1] | (bytes[2] << 8);

    final wateringsPerDay = bytes[3];
    print("========== Schedule ==========");
    print("Raw Bytes        : $bytes");
    print("Days Mask        : ${bytes[0]}");
    print("Days Binary      : ${bytes[0].toRadixString(2).padLeft(8,'0')}");
    print("Time Minutes     : $timeMinutes");
    print("Hour             : ${timeMinutes ~/ 60}");
    print("Minute           : ${timeMinutes % 60}");
    print("Waterings / Day  : $wateringsPerDay");
    print("==============================");

    return BleSchedule(
      daysMask: daysMask,
      timeMinutes: timeMinutes,
      wateringsPerDay: wateringsPerDay,
    );
  }
}

class BleSchedule {
  final int daysMask;
  final int timeMinutes;
  final int wateringsPerDay;

  const BleSchedule({
    required this.daysMask,
    required this.timeMinutes,
    required this.wateringsPerDay,
  });

  @override
  String toString() {

    return '''
BleSchedule(
  daysMask: $daysMask,
  timeMinutes: $timeMinutes,
  wateringsPerDay: $wateringsPerDay
)
''';
  }
}