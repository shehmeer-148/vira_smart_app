import 'dart:convert';
import 'dart:typed_data';

class BleEncoder {
  /// String -> UTF8 Bytes
  static List<int> string(String value) {
    print("Plant Name written in ble as: ${utf8.encode(value)}");
    return utf8.encode(value);
  }

  /// uint8
  static List<int> uint8(int value) {
    print(" Setup Done  written in ble as: ${[value]}");
    return [value];
  }

  /// uint16
  static List<int> uint16(int value) {
    final data = ByteData(2);
    data.setUint16(0, value, Endian.little);
    print("data write in vira for plant type/id and also for water duration as: ${data.buffer.asUint8List()}");


    return data.buffer.asUint8List();
  }

  /// uint32
  static List<int> uint32(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    print(" RTX Sync timestamp written in ble as: ${[data.buffer.asUint8List()]}");

    return data.buffer.asUint8List();
  }

}