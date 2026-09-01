import 'package:flutter/material.dart';

import '../../Core/plant_library.dart';
import '../../Data/Model_classes/plant_model.dart';
import '../../Data/Model_classes/plant_schedule_model.dart';
import '../../Util/helper_classes.dart';

class PlantProvider extends ChangeNotifier {

  //-------------------------------------------------------
  // SEARCH
  //-------------------------------------------------------

  String _search = "";

  String get search => _search;

  //-------------------------------------------------------
  // CATEGORY
  //-------------------------------------------------------

  int _selectedCategory = 0;

  int get selectedCategory => _selectedCategory;

  //-------------------------------------------------------
  // SELECTED PLANT    & SCHEDULED PLANT
  //-------------------------------------------------------

  PlantModel? _selectedPlant;

  PlantModel? get selectedPlant => _selectedPlant;

  PlantSchedule? _schedule;

  PlantSchedule? get schedule => _schedule;

  //-------------------------------------------------------
  // CATEGORIES
  //-------------------------------------------------------

  List<String> get categories {

    final list = <String>["All"];

    for (final plant in PlantLibrary.plants) {
      if (!list.contains(plant.category)) {
        list.add(plant.category);
      }
    }

    return list;
  }

  //-------------------------------------------------------
  // ALL PLANTS
  //-------------------------------------------------------

  List<PlantModel> get plants => filteredPlants;

  //-------------------------------------------------------
  // FILTERED PLANTS
  //-------------------------------------------------------

  List<PlantModel> get filteredPlants {

    List<PlantModel> result =
    List.from(PlantLibrary.plants);

    //---------------------------------------------------
    // CATEGORY FILTER
    //---------------------------------------------------

    if (_selectedCategory != 0) {

      final category = categories[_selectedCategory];

      result = result
          .where((e) => e.category == category)
          .toList();
    }

    //---------------------------------------------------
    // SEARCH FILTER
    //---------------------------------------------------

    if (_search.isNotEmpty) {

      result = result
          .where(
            (e) => e.name
            .toLowerCase()
            .contains(_search.toLowerCase()),
      )
          .toList();
    }

    return result;
  }

  //-------------------------------------------------------
  // SEARCH
  //-------------------------------------------------------

  void searchPlant(String value) {

    _search = value;

    notifyListeners();
  }

  //-------------------------------------------------------
  // CATEGORY
  //-------------------------------------------------------

  void changeCategory(int index) {

    _selectedCategory = index;

    notifyListeners();
  }

  //-------------------------------------------------------
  // SELECT PLANT
  //-------------------------------------------------------

  void selectPlant(PlantModel plant) {

    _selectedPlant = plant;
    _schedule = PlantSchedule.fromPlant(plant);

    notifyListeners();
  }

  //-------------------------------------------------------
  // SELECT BY ID (ESP32)
  //-------------------------------------------------------

  void selectPlantById(int id) {

    _selectedPlant = PlantLibrary.getById(id);

    if (_selectedPlant != null) {
      _schedule = PlantSchedule.fromPlant(_selectedPlant!);
    }

    notifyListeners();
  }

  //-------------------------------------------------------
  // CLEAR
  //-------------------------------------------------------

  void clearSelection() {

    _selectedPlant = null;
    _schedule = null;


    notifyListeners();
  }

  void toggleDay(int index) {

    if (_schedule == null) return;

    _schedule!.daysMask =
        WeekDays.toggle(_schedule!.daysMask, index);

    notifyListeners();
  }
  void updateTime(TimeOfDay time) {

    if (_schedule == null) return;

    _schedule!.timeMinutes =
        time.hour * 60 + time.minute;

    notifyListeners();
  }
  void updateTimesPerDay(int value) {

    if (_schedule == null) return;

    _schedule!.wateringsPerDay = value;

    notifyListeners();
  }
  void updateWaterDuration(int seconds) {

    if (_schedule == null) return;

    _schedule!.waterDuration = seconds;

    notifyListeners();
  }
  void updateWateringInterval(int days) {

    if (_schedule == null) return;

    _schedule!.wateringIntervalDays = days;

    notifyListeners();
  }
}