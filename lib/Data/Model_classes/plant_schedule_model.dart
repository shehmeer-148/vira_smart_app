import 'package:flutter/material.dart';
import 'package:vira_planter_app/Data/Model_classes/plant_model.dart';


class PlantSchedule {
  /// Reference to the selected plant from the library
  final PlantModel plant;

  /// Editable schedule values
  int wateringIntervalDays;
  int daysMask;
  int timeMinutes;
  int wateringsPerDay;
  int waterDuration;

  PlantSchedule({
    required this.plant,
    required this.wateringIntervalDays,
    required this.daysMask,
    required this.timeMinutes,
    required this.wateringsPerDay,
    required this.waterDuration,
  });

  /// Create an editable schedule from a plant's default values
  factory PlantSchedule.fromPlant(PlantModel plant) {
    return PlantSchedule(
      plant: plant,
      wateringIntervalDays: plant.wateringIntervalDays,
      daysMask: plant.daysMask,
      timeMinutes: plant.timeMinutes,
      wateringsPerDay: plant.wateringsPerDay,
      waterDuration: plant.waterDuration,
    );
  }

  /// Convenience getters
  int get hour => timeMinutes ~/ 60;

  int get minute => timeMinutes % 60;

  TimeOfDay get time => TimeOfDay(
    hour: hour,
    minute: minute,
  );

  /// Check if a weekday is selected
  bool isDaySelected(int index) {
    return (daysMask & (1 << index)) != 0;
  }

  /// Toggle a weekday
  void toggleDay(int index) {
    daysMask ^= (1 << index);
  }

  /// Update the watering time
  void updateTime(TimeOfDay value) {
    timeMinutes = value.hour * 60 + value.minute;
  }

  @override
  String toString() {
    return '''
PlantSchedule(
  plant: ${plant.name},
  interval: $wateringIntervalDays,
  daysMask: $daysMask,
  timeMinutes: $timeMinutes,
  wateringsPerDay: $wateringsPerDay,
  waterDuration: $waterDuration
)
''';
  }
}