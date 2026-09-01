import 'dart:async';

import 'package:flutter/material.dart';

import '../../Core/plant_library.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../../Data/Services/Database/database_helper.dart';


class PotProvider extends ChangeNotifier {
  PotProvider(this._database);

  final DatabaseHelper _database;

  /// LOCAL DATABASE

  bool _isLoadingPots = false;
  bool get isLoadingPots => _isLoadingPots;
  List<PotModel> _pots = [];
  List<PotModel> get pots => List.unmodifiable(_pots);
  PotModel? _currentPot;
  PotModel? get currentPot => _currentPot;

  // ====================== GET PLANT CATEGORY =====================//

  String getPlantCategory(int plantTypeId) {
    final plant = PlantLibrary.getById(plantTypeId);

    return plant?.category ?? "Unknown";
  }

  // ====================== DATABASE FUNCTIONS =====================//

  /// DELETE
  Future<bool> deleteCurrentPot(
      String deviceId,
      ) async {

    try {

      await _database.deletePot(deviceId);
      return true;

    } catch (e) {


      return false;
    }
  }
  /// GET ONE
  Future<PotModel?> loadCurrentPotFromDb(
      String deviceId,
      ) async {

    try {

      final pot =
      await _database.getPot(deviceId);

      _currentPot = pot;

      notifyListeners();

      return pot;

    } catch (e) {


      return null;
    }
  }
  /// GET ALL
  Future<void> loadAllPots() async {

    _isLoadingPots = true;

    notifyListeners();

    try {

      _pots =
      await _database.getAllPots();

    } finally {

      _isLoadingPots = false;

      notifyListeners();
    }
  }
  /// Clear Provider
  void clear() {
    _pots = [];
    _currentPot = null;
    _isLoadingPots = false;

    notifyListeners();
  }

// ====================== BLUETOOTH READ/WRITE/NOTIFY FUNCTIONS =====================//

/// READ


}
