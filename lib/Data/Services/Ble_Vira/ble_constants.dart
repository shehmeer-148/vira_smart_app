import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  // ======================
  // Services
  // ======================

  static final Uuid serviceStatus =
  Uuid.parse("0000FFC2-0000-1000-8000-00805F9B34FB");

  static final Uuid serviceConfig =
  Uuid.parse("0000FFC1-0000-1000-8000-00805F9B34FB");

  // ======================
  // FFC1 Characteristics
  // ======================

  static final Uuid plantName =
  Uuid.parse("0000FFD1-0000-1000-8000-00805F9B34FB");

  static final Uuid plantType =
  Uuid.parse("0000FFD2-0000-1000-8000-00805F9B34FB");

  static final Uuid schedule =
  Uuid.parse("0000FFD3-0000-1000-8000-00805F9B34FB");

  static final Uuid waterDuration =
  Uuid.parse("0000FFD4-0000-1000-8000-00805F9B34FB");

  static final Uuid hubMode =
  Uuid.parse("0000FFD5-0000-1000-8000-00805F9B34FB");

  static final Uuid rtcSync =
  Uuid.parse("0000FFD6-0000-1000-8000-00805F9B34FB");

  static final Uuid controlPoint =
  Uuid.parse("0000FFD7-0000-1000-8000-00805F9B34FB");

  // ======================
  // FFC0 Characteristics
  // (Add all status UUIDs from the spec)
  // ======================

  static final Uuid battery =
  Uuid.parse("0000FFE1-0000-1000-8000-00805F9B34FB");

  static final Uuid lastWatered =
  Uuid.parse("0000FFE2-0000-1000-8000-00805F9B34FB");

  static final Uuid cycleCount =
  Uuid.parse("0000FFE3-0000-1000-8000-00805F9B34FB");

  static final Uuid tankStatus =
  Uuid.parse("0000FFE4-0000-1000-8000-00805F9B34FB");

  static final Uuid deviceUuid =
  Uuid.parse("0000FFE5-0000-1000-8000-00805F9B34FB");

  static final Uuid firmwareVersion =
  Uuid.parse("0000FFE6-0000-1000-8000-00805F9B34FB");

  static final Uuid lowBatteryFlag =
  Uuid.parse("0000FFE7-0000-1000-8000-00805F9B34FB");

}