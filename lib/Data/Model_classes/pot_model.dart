import 'package:flutter/material.dart';

import '../../Core/plant_library.dart';
import '../Services/Database/database_helper.dart';

class PotModel {
  // SQLite
  final int? id;

  // Device
  final String deviceId;

  // Plant
  final int plantType;
  final String plantName;
  final String plantImage;

  // Schedule
  final int wateringIntervalDays;
  final int daysMask;
  final int timeMinutes;
  final int wateringsPerDay;
  final int waterDuration;

  // Live Status
  final int batteryLevel;
  final int tankStatus;
  final int lastWatered;
  final int cycleCount;
  final bool lowBattery;
  final String firmwareVersion;

  // App
  final int pairedAt;
  final int lastSynced;

  const PotModel({
    this.id,
    required this.deviceId,
    required this.plantType,
    required this.plantName,
    required this.plantImage,
    required this.wateringIntervalDays,
    required this.daysMask,
    required this.timeMinutes,
    required this.wateringsPerDay,
    required this.waterDuration,
    required this.batteryLevel,
    required this.tankStatus,
    required this.lastWatered,
    required this.cycleCount,
    required this.lowBattery,
    required this.firmwareVersion,
    required this.pairedAt,
    required this.lastSynced,
  });

  //---------------------------------------------------------
  // Convenience Getters
  //---------------------------------------------------------

  TimeOfDay get wateringTime => TimeOfDay(
    hour: timeMinutes ~/ 60,
    minute: timeMinutes % 60,
  );

  bool isDaySelected(int index) {
    return (daysMask & (1 << index)) != 0;
  }

  //---------------------------------------------------------
  // TO MAP
  //---------------------------------------------------------

  Map<String, dynamic> toMap() {

    final map = {
      DatabaseHelper.id: id,
      DatabaseHelper.deviceId: deviceId,

      DatabaseHelper.plantType: plantType,
      DatabaseHelper.plantName: plantName,
      DatabaseHelper.plantImage: plantImage,

      DatabaseHelper.wateringIntervalDays: wateringIntervalDays,
      DatabaseHelper.daysMask: daysMask,
      DatabaseHelper.timeMinutes: timeMinutes,
      DatabaseHelper.wateringsPerDay: wateringsPerDay,
      DatabaseHelper.waterDuration: waterDuration,

      DatabaseHelper.batteryLevel: batteryLevel,
      DatabaseHelper.tankStatus: tankStatus,
      DatabaseHelper.lastWatered: lastWatered,
      DatabaseHelper.cycleCount: cycleCount,
      DatabaseHelper.lowBattery: lowBattery ? 1 : 0,
      DatabaseHelper.firmwareVersion: firmwareVersion,

      DatabaseHelper.pairedAt: pairedAt,
      DatabaseHelper.lastSynced: lastSynced,
    };

    if (id != null) {
      map[DatabaseHelper.id] = id;
    }

    return map;
  }

  //---------------------------------------------------------
  // FROM MAP
  //---------------------------------------------------------

  factory PotModel.fromMap(Map<String, dynamic> map) {
    return PotModel(
      id: map[DatabaseHelper.id],

      deviceId: map[DatabaseHelper.deviceId],

      plantType: map[DatabaseHelper.plantType],
      plantName: map[DatabaseHelper.plantName],
      plantImage: map[DatabaseHelper.plantImage],

      wateringIntervalDays:
      map[DatabaseHelper.wateringIntervalDays],

      daysMask: map[DatabaseHelper.daysMask],

      timeMinutes: map[DatabaseHelper.timeMinutes],

      wateringsPerDay:
      map[DatabaseHelper.wateringsPerDay],

      waterDuration:
      map[DatabaseHelper.waterDuration],

      batteryLevel:
      map[DatabaseHelper.batteryLevel],

      tankStatus:
      map[DatabaseHelper.tankStatus],

      lastWatered:
      map[DatabaseHelper.lastWatered],

      cycleCount:
      map[DatabaseHelper.cycleCount],

      lowBattery:
      map[DatabaseHelper.lowBattery] == 1,

      firmwareVersion:
      map[DatabaseHelper.firmwareVersion],

      pairedAt:
      map[DatabaseHelper.pairedAt],

      lastSynced:
      map[DatabaseHelper.lastSynced],
    );
  }

  //---------------------------------------------------------
  // COPY WITH
  //---------------------------------------------------------

  PotModel copyWith({
    int? id,
    String? deviceId,
    int? plantType,
    String? plantName,
    String? plantImage,
    int? wateringIntervalDays,
    int? daysMask,
    int? timeMinutes,
    int? wateringsPerDay,
    int? waterDuration,
    int? batteryLevel,
    int? tankStatus,
    int? lastWatered,
    int? cycleCount,
    bool? lowBattery,
    String? firmwareVersion,
    int? pairedAt,
    int? lastSynced,
  }) {
    return PotModel(
      id: id ?? this.id,

      deviceId: deviceId ?? this.deviceId,

      plantType: plantType ?? this.plantType,
      plantName: plantName ?? this.plantName,
      plantImage: plantImage ?? this.plantImage,

      wateringIntervalDays:
      wateringIntervalDays ?? this.wateringIntervalDays,

      daysMask: daysMask ?? this.daysMask,

      timeMinutes: timeMinutes ?? this.timeMinutes,

      wateringsPerDay:
      wateringsPerDay ?? this.wateringsPerDay,

      waterDuration:
      waterDuration ?? this.waterDuration,

      batteryLevel:
      batteryLevel ?? this.batteryLevel,

      tankStatus:
      tankStatus ?? this.tankStatus,

      lastWatered:
      lastWatered ?? this.lastWatered,

      cycleCount:
      cycleCount ?? this.cycleCount,

      lowBattery:
      lowBattery ?? this.lowBattery,

      firmwareVersion:
      firmwareVersion ?? this.firmwareVersion,

      pairedAt:
      pairedAt ?? this.pairedAt,

      lastSynced:
      lastSynced ?? this.lastSynced,
    );
  }

  //---------------------------------------------------------
  // DEBUG
  //---------------------------------------------------------

  @override
  String toString() {
    return '''
==================== POT ====================

ID                  : $id
Device ID           : $deviceId

Plant Type          : $plantType
Plant Name          : $plantName
Plant Image         : $plantImage

Water Interval      : $wateringIntervalDays day(s)
Days Mask           : $daysMask
Time Minutes        : $timeMinutes
Waterings / Day     : $wateringsPerDay
Water Duration      : $waterDuration sec

Battery             : $batteryLevel%
Tank Status         : $tankStatus
Last Watered        : $lastWatered
Cycle Count         : $cycleCount
Low Battery         : $lowBattery
Firmware            : $firmwareVersion

Paired At           : $pairedAt
Last Synced         : $lastSynced

=============================================
''';
  }
  String getPlantCategory(int plantTypeId) {
    final plant = PlantLibrary.getById(plantTypeId);

    return plant?.category ?? "Unknown";
  }
}