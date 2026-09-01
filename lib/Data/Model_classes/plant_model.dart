

import 'package:flutter/material.dart';

import '../../Util/helper_classes.dart';

class PlantModel {
  final int id;

  final String name;

  final String category;

  final String image;

  final bool popular;

  /// default values from plant library

  /// Every X days
  final int wateringIntervalDays;

  /// Monday..Sunday bit mask
  final int daysMask;

  /// minutes from midnight
  final int timeMinutes;

  /// 1x,2x,3x...
  final int wateringsPerDay;

  /// seconds
  final int waterDuration;

  /// shown on schedule screen
  final String tip;

  const PlantModel({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.wateringIntervalDays,
    required this.daysMask,
    required this.timeMinutes,
    required this.wateringsPerDay,
    required this.waterDuration,
    required this.tip,
    this.popular = false,
  });

  bool get isCustom => id == 0xFFFF;

  String get subtitle =>
      isCustom
          ? "Set manually"
          : "Every $wateringIntervalDays days";

  int get hour => timeMinutes ~/ 60;

  int get minute => timeMinutes % 60;

  TimeOfDay get time =>
      TimeOfDay(
        hour: hour,
        minute: minute,
      );


  bool isDaySelected(int index) {
    return WeekDays.isSelected(daysMask, index);
  }
}