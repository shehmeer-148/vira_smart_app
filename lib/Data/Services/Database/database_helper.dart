import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../Model_classes/pot_model.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  static const String databaseName = "vira.db";
  static const int databaseVersion = 1;

  //======================================================
  // TABLE
  //======================================================

  static const String potTable = "pots";

  //======================================================
  // COLUMNS
  //======================================================

  static const String id = "id";

  //-------------------------------
  // Device
  //-------------------------------

  static const String deviceId = "device_id";

  //-------------------------------
  // Plant
  //-------------------------------

  static const String plantType = "plant_type";

  static const String plantName = "plant_name";

  static const String plantImage = "plant_image";

  //-------------------------------
  // Schedule
  //-------------------------------

  static const String wateringIntervalDays = "watering_interval_days";

  static const String daysMask = "days_mask";

  static const String timeMinutes = "time_minutes";

  static const String wateringsPerDay =
      "waterings_per_day";

  static const String waterDuration =
      "water_duration";

  //-------------------------------
  // Live Status
  //-------------------------------

  static const String batteryLevel =
      "battery_level";

  static const String tankStatus =
      "tank_status";

  static const String lastWatered =
      "last_watered";

  static const String cycleCount =
      "cycle_count";

  static const String lowBattery =
      "low_battery";

  static const String firmwareVersion =
      "firmware_version";

  //-------------------------------
  // App
  //-------------------------------

  static const String pairedAt =
      "paired_at";

  static const String lastSynced =
      "last_synced";

  //======================================================
  // DATABASE
  //======================================================

  Future<Database> get database async {
    _database ??= await _initializeDatabase();

    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final path = join(
      await getDatabasesPath(),
      databaseName,
    );

    return openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  //======================================================
  // CREATE
  //======================================================

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await db.execute('''
    
    CREATE TABLE $potTable(

      $id INTEGER PRIMARY KEY AUTOINCREMENT,

      $deviceId TEXT UNIQUE NOT NULL,

      $plantType INTEGER NOT NULL,

      $plantName TEXT NOT NULL,

      $plantImage TEXT NOT NULL,

      $wateringIntervalDays INTEGER NOT NULL,

      $daysMask INTEGER NOT NULL,

      $timeMinutes INTEGER NOT NULL,

      $wateringsPerDay INTEGER NOT NULL,

      $waterDuration INTEGER NOT NULL,

      $batteryLevel INTEGER DEFAULT 0,

      $tankStatus INTEGER DEFAULT 0,

      $lastWatered INTEGER DEFAULT 0,

      $cycleCount INTEGER DEFAULT 0,

      $lowBattery INTEGER DEFAULT 0,

      $firmwareVersion TEXT DEFAULT "",

      $pairedAt INTEGER NOT NULL,

      $lastSynced INTEGER NOT NULL

    )
    
    ''');

    print("✅ SQLite Database Created");
  }

  //======================================================
  // UPGRADE
  //======================================================

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    print("⬆ Database Upgraded");
  }

  //======================================================
  // CLOSE
  //======================================================

  Future<void> close() async {
    final db = await database;

    db.close();
  }


  Future<int> insertPot(PotModel pot) async {
    final db = await database;

    final map = pot.toMap();

    // Let SQLite generate the auto-increment ID
    map.remove(DatabaseHelper.id);

    return await db.insert(
      potTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updatePot(PotModel pot) async {
    final db = await database;

    final map = pot.toMap();

    // Never update the primary key
    map.remove(DatabaseHelper.id);

    return await db.update(
      potTable,
      map,
      where: '$deviceId = ?',
      whereArgs: [pot.deviceId],
    );
  }
  Future<int> deletePot(String deviceId) async {
    final db = await database;

    return await db.delete(
      potTable,
      where: '$deviceId = ?',
      whereArgs: [deviceId],
    );
  }

  Future<PotModel?> getPot(String deviceId) async {
    final db = await database;

    final result = await db.query(
      'pots',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return PotModel.fromMap(result.first);
  }
  Future<List<PotModel>> getAllPots() async {
    final db = await database;

    final result = await db.query(
      potTable,
      orderBy: '$pairedAt DESC',
    );

    return result
        .map((e) => PotModel.fromMap(e))
        .toList();
  }

  Future<bool> potExists(String deviceID) async {
    final db = await database;

    final result = await db.query(
      potTable,
      columns: [deviceId],
      where: '$deviceId = ?',
      whereArgs: [deviceID],
      limit: 1,
    );

    return result.isNotEmpty;
  }
  Future<void> clearDatabase() async {
    final db = await database;

    await db.delete(potTable);
  }
}