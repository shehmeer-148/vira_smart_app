import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:vira_planter_app/Presentation/Providers/plant_provider.dart';

import '../../Data/Model_classes/pot_model.dart';
import '../../Data/Services/Ble_Vira/ble_parser.dart';
import '../../Data/Services/Ble_Vira/ble_services.dart';
import '../../Core/enums.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../Data/Services/Database/database_helper.dart';
import '../../Data/Model_classes/plant_schedule_model.dart';
import '../../smp_test.dart';

class BleProvider extends ChangeNotifier {
  BleProvider(this._bleService);

  final BleService _bleService;

  bool _isConnecting = false;

 /// BLUETOOTH STATUS

  BleStatus _bleStatus = BleStatus.unknown;
  BleStatus get bleStatus => _bleStatus;

  /// CONNECTION

  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState =>
      _connectionState;
  bool get isScanning =>
      _connectionState == BleConnectionState.scanning;
  bool get isConnecting =>
      _connectionState == BleConnectionState.connecting;
  bool get isConnected =>
      _connectionState == BleConnectionState.connected;

  /// DEVICE

  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices =>
      List.unmodifiable(_devices);
  DiscoveredDevice? _selectedDevice;
  DiscoveredDevice? get selectedDevice =>
      _selectedDevice;
  DiscoveredDevice? _connectedDevice;
  DiscoveredDevice? get connectedDevice =>
      _connectedDevice;
  String? get deviceId =>
      _connectedDevice?.id;

  /// POT DATA

  bool _isWritingPlant = false;
  bool get isWritingPlant => _isWritingPlant;
  bool _isWritingSchedule = false;
  bool get isWritingSchedule => _isWritingSchedule;

  /// DASHBOARD CONNECTION STATUS
  String? _connectingPotId;
  bool isPotConnected(String deviceId) {
    return _connectedDevice?.id == deviceId;
  }
  // bool isPotConnecting(String deviceId) {
  //   return _isConnecting &&
  //       _selectedDevice?.id == deviceId;
  // }
  bool isPotConnecting(String deviceId) {
    return _connectingPotId == deviceId;
  }

  /// SUBSCRIPTIONS

  StreamSubscription<BleStatus>? _statusSubscription;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<int>? _batterySubscription;

  /// TEST DATA
  // ============================================================
// TEST APP CONFIGURATION DATA
// ============================================================

  int? _plantType;
  String? _plantName;

  int? _daysMask;
  int? _timeMinutes;
  int? _waterDuration;

// Live Status
  int _batteryLevel = 0;
  int _tankStatus = 0;
  int _lastWatered = 0;
  int _cycleCount = 0;
  bool _lowBattery = false;
  String _firmwareVersion = 'Unknown';

  int? get plantType => _plantType;
  String? get plantName => _plantName;

  int? get daysMask => _daysMask;
  int? get timeMinutes => _timeMinutes;
  int? get waterDuration => _waterDuration;

  int get batteryLevel => _batteryLevel;
  int get tankStatus => _tankStatus;
  int get lastWatered => _lastWatered;
  int get cycleCount => _cycleCount;
  bool get lowBattery => _lowBattery;
  String get firmwareVersion => _firmwareVersion;

  bool _isReadingConfiguration = false;
  bool get isReadingConfiguration => _isReadingConfiguration;

  bool _hasWrittenConfiguration = false;
  bool get hasWrittenConfiguration => _hasWrittenConfiguration;

  bool _isDfuUpdating = false;
  bool get isDfuUpdating => _isDfuUpdating;

  // ====================== BLUETOOTH PAIRING & SCANNING FUNCTIONS =====================//
  // Tracks when each device was last seen
  final Map<String, DateTime> _lastSeen = {};

  /// INITIALIZE
  Future<void> initialize() async {
    print("");
    print("========== BLE INITIALIZE ==========");

    // --------------------------------------------------
    // Check permissions
    // --------------------------------------------------

    final granted = await _checkPermissions();

    print("BLE Permissions Granted: $granted");

    if (!granted) {
      print("❌ BLE permissions denied");
      return;
    }

    // --------------------------------------------------
    // Clear previous BLE session
    // --------------------------------------------------

    print("🧹 Clearing previous BLE session...");

    await stopScan();

    final connectionSubscription = _connectionSubscription;
    _connectionSubscription = null;

    if (connectionSubscription != null) {
      print("🛑 Cancelling previous connection...");
      await connectionSubscription.cancel();
      print("✅ Previous connection cancelled");
    }

    final batterySubscription = _batterySubscription;
    _batterySubscription = null;

    if (batterySubscription != null) {
      print("🛑 Cancelling previous battery notification...");
      await batterySubscription.cancel();
      print("✅ Previous battery notification cancelled");
    }

    // --------------------------------------------------
    // Reset device state
    // --------------------------------------------------

    _connectedDevice = null;
    _selectedDevice = null;


    _isConnecting = false;

    _connectionState =
        BleConnectionState.disconnected;

    notifyListeners();

    // --------------------------------------------------
    // BLE STATUS SUBSCRIPTION
    // --------------------------------------------------

    await _statusSubscription?.cancel();

    _statusSubscription = null;

    print("Creating BLE status subscription...");

    _statusSubscription =
        _bleService.getStatusStream().listen((status) {

          print("");
          print("========== BLE STATUS EVENT ==========");
          print("Status          : $status");
          print("ConnectionState : $_connectionState");
          print("isScanning      : $isScanning");
          print("isConnecting    : $isConnecting");
          print("isConnected     : $isConnected");
          print("======================================");

          _bleStatus = status;

          notifyListeners();
        });

    print("BLE initialize completed");
    print("====================================");
  }
  Future<void> initializePairing() async {
    // print("");
    // print("========== INITIALIZE PAIRING ==========");
    //
    // await initialize();

    // --------------------------------------------------
    // Wait until BLE status becomes ready
    // --------------------------------------------------

    if (_bleStatus != BleStatus.ready) {
      print("⏳ BLE is not ready yet");

      return;
    }

    // --------------------------------------------------
    // Start scan for pairing screen
    // --------------------------------------------------

    if (!isScanning &&
        !isConnecting &&
        !isConnected) {

      print("🟢 BLE READY → START PAIRING SCAN");

      await startScan();
    }

    print("=========================================");
  }
  /// PERMISSIONS
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every(
            (e) => e.isGranted,
      );
    }

    return (await Permission.bluetooth.request())
        .isGranted;
  }

  /// SCAN
  Future<void> startScan() async {
    if (isScanning) return;
    if (isConnecting || isConnected) return;

    print("========== START SCAN ==========");

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _devices.clear();
    _lastSeen.clear(); // Clear timestamps

    _connectionState = BleConnectionState.scanning;
    notifyListeners();

    _scanSubscription = _bleService.scan().listen(
          (device) {
        // Update or Add timestamp
        _lastSeen[device.id] = DateTime.now();

        // If new device, add to list
        if (!_devices.any((d) => d.id == device.id)) {
          print("📡 Device found: ${device.name.isNotEmpty ? device.name : "Unknown"} (${device.id})");
          _devices.add(device);
          notifyListeners();
        }

        // --- STALE DEVICE CLEANUP ---
        // Remove devices not seen in the last 10 seconds
        final now = DateTime.now();
        final staleThreshold = const Duration(seconds: 10);

        bool changed = false;
        _devices.removeWhere((d) {
          final lastSeen = _lastSeen[d.id];
          if (lastSeen != null && now.difference(lastSeen) > staleThreshold) {
            print("🗑️ Removing stale device: ${d.id}");
            _lastSeen.remove(d.id);
            changed = true;
            return true;
          }
          return false;
        });

        if (changed) notifyListeners();
      },
      onError: (error) {
        print("❌ BLE scan error: $error");
        _scanSubscription = null;
        _connectionState = BleConnectionState.disconnected;
        notifyListeners();
      },
      onDone: () {
        _scanSubscription = null;
        _connectionState = BleConnectionState.disconnected;
        notifyListeners();
      },
    );
  }
  /// STOP
  Future<void> stopScan() async {
    print("========== STOP SCAN ==========");

    final subscription = _scanSubscription;

    if (subscription == null) {
      print("ℹ️ No active scan");
      return;
    }

    // Remove reference immediately
    _scanSubscription = null;

    print("🛑 Cancelling BLE scan...");

    await subscription.cancel();

    print("✅ BLE scan cancelled");

    print("==============================");
  }
  /// SELECT DEVICE
  void selectDevice(
      DiscoveredDevice device) {

    _selectedDevice = device;
    print("Selected hash: ${device.hashCode}");

    notifyListeners();
  }
  /// CONNECT
  Future<bool> connect() async {
    print("");
    print("=================================================");
    print("📡 CONNECT REQUEST");
    print("=================================================");

    final device = _selectedDevice;

    // --------------------------------------------------
    // VALIDATE DEVICE
    // --------------------------------------------------

    if (device == null) {
      print("❌ No device selected");
      return false;
    }

    // --------------------------------------------------
    // PREVENT DUPLICATE CONNECTION
    // --------------------------------------------------

    if (_isConnecting) {
      print("⚠️ Already connecting");
      return false;
    }

    // --------------------------------------------------
    // BLUETOOTH MUST BE READY
    // --------------------------------------------------

    if (_bleStatus != BleStatus.ready) {
      print("❌ Bluetooth is not ready");
      print("Current BLE status: $_bleStatus");
      return false;
    }

    // --------------------------------------------------
    // UPDATE CONNECTION STATE
    // --------------------------------------------------

    _isConnecting = true;
    _connectionState =
        BleConnectionState.connecting;

    notifyListeners();

    final completer = Completer<bool>();

    Timer? timeoutTimer;

    // Prevent cleanup from running multiple times

    bool isCleanedUp = false;

    // --------------------------------------------------
    // CLEANUP
    // --------------------------------------------------

    Future<void> cleanup() async {
      if (isCleanedUp) {
        print("⚠️ Cleanup already performed");
        return;
      }

      isCleanedUp = true;

      print("========== CONNECTION CLEANUP ==========");

      // Cancel timeout
      timeoutTimer?.cancel();
      timeoutTimer = null;

      // Take ownership of current subscription
      final subscription = _connectionSubscription;

      // Immediately remove reference
      _connectionSubscription = null;

      // Cancel connection subscription
      if (subscription != null) {
        print("🛑 Cancelling connection subscription...");

        await subscription.cancel();

        print("✅ Connection subscription cancelled");
      }

      // Reset provider state
      _connectedDevice = null;

      _isConnecting = false;

      _connectionState = BleConnectionState.disconnected;

      notifyListeners();

      print("Connection state reset");
      print("========================================");
    }

    try {
      print("Device Name : ${device.name}");
      print("Device ID   : ${device.id}");

      // --------------------------------------------------
      // STOP SCAN BEFORE CONNECTING
      // --------------------------------------------------

      await stopScan();

      // --------------------------------------------------
      // CANCEL ANY PREVIOUS CONNECTION
      // --------------------------------------------------

      final previousConnection = _connectionSubscription;

      _connectionSubscription = null;

      if (previousConnection != null) {
        print("⚠️ Previous connection exists");

        await previousConnection.cancel();

        print("✅ Previous connection cancelled");
      }

      // --------------------------------------------------
      // GIVE BLE STACK TIME TO RELEASE SCAN
      // --------------------------------------------------

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      // --------------------------------------------------
      // START CONNECTION
      // --------------------------------------------------

      print("🔗 Starting BLE connection...");

      _connectionSubscription = _bleService.connect(device).listen(
                (update) async{

              print("BLE : ${update.connectionState}",);

              switch (update.connectionState) {

              // --------------------------------------------
              // CONNECTING
              // --------------------------------------------

                case DeviceConnectionState.connecting:

                  print(
                    "🔵 BLE connection is CONNECTING",
                  );

                  break;

              // --------------------------------------------
              // CONNECTED
              // --------------------------------------------

                case DeviceConnectionState.connected:

                  print("🟢 BLE CONNECTED");
                  print("Connected Device : ${device.id}",);

                  // Stop timeout
                  timeoutTimer?.cancel();
                  timeoutTimer = null;

                  // Save connected device
                  _connectedDevice = device;

                  // Update state
                  _connectionState = BleConnectionState.connected;

                  _isConnecting = false;

                  notifyListeners();

                  // Complete connect()
                  if (!completer.isCompleted) {
                    completer.complete(true);
                  }

                  break;

              // --------------------------------------------
              // DISCONNECTING
              // --------------------------------------------

                case DeviceConnectionState.disconnecting:

                  print("🟡 BLE DISCONNECTING",);

                  break;

              // --------------------------------------------
              // DISCONNECTED
              // --------------------------------------------

                case DeviceConnectionState.disconnected:
                  print("🔴 BLE DISCONNECTED");

                  await cleanup();

                  if (!completer.isCompleted) {
                    completer.complete(false);
                  }


              // print("🔴 BLE DISCONNECTED");
                  //
                  // if (!completer.isCompleted) {
                  //
                  //   cleanup().then((_) {
                  //
                  //     if (!completer.isCompleted) {
                  //       completer.complete(false);
                  //     }
                  //
                  //   });
                  // }
                  //
                  // break;
              }
            },

            // ------------------------------------------------
            // CONNECTION ERROR
            // ------------------------------------------------

            onError: (error) {

              print("");
              print("❌ CONNECTION ERROR");
              print(error);
              print("");

              if (!completer.isCompleted) {

                cleanup().then((_) {

                  if (!completer.isCompleted) {
                    completer.complete(false);
                  }

                });
              }
            },
          );

      // --------------------------------------------------
      // CONNECTION TIMEOUT
      // --------------------------------------------------

      timeoutTimer = Timer(
        const Duration(seconds: 12),
            () {

          if (completer.isCompleted) {
            return;
          }

          print("");
          print("⏰ CONNECTION TIMEOUT");
          print("Device : ${device.id}");
          print(
            "The BLE connection did not reach CONNECTED",
          );
          print("");

          cleanup().then((_) {

            if (!completer.isCompleted) {
              completer.complete(false);
            }

          });
        },
      );

      // --------------------------------------------------
      // WAIT FOR CONNECTION RESULT
      // --------------------------------------------------

      final result = await completer.future;

      print("");
      print("========== CONNECT RESULT ==========");
      print("Device : ${device.id}");
      print("Result : $result");
      print("State  : $_connectionState");
      print("====================================");

      return result;

    } catch (e) {

      print("");
      print("❌ CONNECT EXCEPTION");
      print(e);
      print("");

      await cleanup();

      if (!completer.isCompleted) {
        completer.complete(false);
      }

      return false;
    }
  }
  /// DISCONNECT
  Future<void> disconnect() async {
    print("");
    print("========== BLE DISCONNECT ==========");

    // --------------------------------------------------
    // Cancel connection subscription
    // --------------------------------------------------

    final connectionSubscription =
        _connectionSubscription;

    _connectionSubscription = null;

    if (connectionSubscription != null) {
      print("🛑 Cancelling connection...");
      await connectionSubscription.cancel();
      print("✅ Connection cancelled");
    }

    // --------------------------------------------------
    // Cancel battery notification
    // --------------------------------------------------

    final batterySubscription =
        _batterySubscription;

    _batterySubscription = null;

    if (batterySubscription != null) {
      print("🛑 Cancelling battery notification...");
      await batterySubscription.cancel();
      print("✅ Battery notification cancelled");
    }

    // --------------------------------------------------
    // Clear device references
    // --------------------------------------------------

    _connectedDevice = null;
    _selectedDevice = null;

    // --------------------------------------------------
    // Reset connection state
    // --------------------------------------------------

    _isConnecting = false;

    _connectionState =
        BleConnectionState.disconnected;

    // --------------------------------------------------
    // Update UI
    // --------------------------------------------------

    notifyListeners();

    print("🔴 Device disconnected");
    print("==================================");
  }
  /// CONNECT TO SAVED POT


  /// READ

  Future<String?> readPlantName() async {
    try {
      if (_connectedDevice == null) {
        print("❌ Cannot read plant name: No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("📖 READ PLANT NAME");
      print("Device: $deviceId");

      final plantName =
      await _bleService.readPlantName(deviceId);

      print("🪴 Plant Name received from VIRA: $plantName");

      return plantName;
    } catch (e, stack) {
      print("❌ Failed to read plant name");
      print("Error: $e");
      print(stack);
      return null;
    }
  }
  Future<int?> readPlantType() async {
    try {
      if (_connectedDevice == null) {
        print("❌ Cannot read plant type: No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;


      print("📖 READ PLANT TYPE");
      print("Device: $deviceId");

      final plantType =
      await _bleService.readPlantType(deviceId);

      print("🪴 Plant Type received from VIRA: $plantType");

      return plantType;
    } catch (e, stack) {
      print("❌ Failed to read plant type");
      print("Error: $e");
      print(stack);
      return null;
    }
  }
  Future<int?> readBatteryLevel() async {
    try {
      if (_connectedDevice == null) {
        print("❌ Cannot read battery: No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("");
      print("==========================================");
      print("🔋 READ BATTERY LEVEL");
      print("Device: $deviceId");
      print("==========================================");

      final batteryLevel =
      await _bleService.readBatteryLevel(deviceId);

      print("🔋 Battery received from VIRA: $batteryLevel%");

      return batteryLevel;
    } catch (e, stack) {
      print("❌ Failed to read battery level");
      print("Error: $e");
      print(stack);
      return null;
    }
  }
  Future<String?> readDeviceUuid() async {

    print("");
    print("==============================================");
    print("📖 READ DEVICE UUID");
    print("==============================================");

    try {

      if (_connectedDevice == null) {

        print("❌ No Connected Device");

        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("🔗 BLE Device ID : $deviceId");

      final uuid =
      await _bleService.readDeviceUuid(deviceId);

      print("🔑 Device UUID : $uuid");

      return uuid;

    } catch (e, stack) {

      print("");
      print("❌ READ DEVICE UUID FAILED");
      print("Error : $e");
      print(stack);

      return null;
    }
  }
  Future<int?> readWaterDuration() async {

    print("");
    print("==================================================");
    print("📖 READ WATER DURATION");
    print("==================================================");

    try {

      // --------------------------------------------------
      // Check connection
      // --------------------------------------------------

      if (_connectedDevice == null) {

        print("❌ No Connected Device");
        print("❌ Cannot read water duration");

        print("==================================================");

        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("🔗 Device ID : $deviceId");

      print("");
      print("➡️ Requesting water duration from BLE service...");

      // --------------------------------------------------
      // Read from BLE
      // --------------------------------------------------

      final duration =
      await _bleService.readWaterDuration(
        deviceId,
      );

      // --------------------------------------------------
      // Result
      // --------------------------------------------------

      print("");
      print("⬅️ Water Duration Received");

      print("------------------------------------------");
      print("💧 Water Duration : $duration seconds");
      print("------------------------------------------");

      print("");
      print("✅ Water Duration Read Successfully");

      print("==================================================");

      return duration;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ READ WATER DURATION FAILED");
      print("==================================================");

      print("Error : $e");

      print("");
      print("Stack Trace:");
      print(stack);

      print("==================================================");

      return null;
    }
  }
  Future<int?> readScheduleDaysMask() async {

    print("");
    print("==================================================");
    print("📖 READ SCHEDULE DAYS MASK");
    print("==================================================");

    try {

      // --------------------------------------------------
      // Check connection
      // --------------------------------------------------

      if (_connectedDevice == null) {

        print("❌ No Connected Device");
        print("❌ Cannot read schedule days mask");

        print("==================================================");

        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("🔗 Device ID : $deviceId");

      print("");
      print("➡️ Requesting schedule days mask from BLE service...");

      // --------------------------------------------------
      // Read from BLE
      // --------------------------------------------------

      final daysMask =
      await _bleService.readScheduleDaysMask(
        deviceId,
      );

      // --------------------------------------------------
      // Result
      // --------------------------------------------------

      print("");
      print("⬅️ Schedule Days Mask Received");

      print("------------------------------------------");
      print("📅 Days Mask : $daysMask");
      print("------------------------------------------");

      print("");
      print("✅ Schedule Days Mask Read Successfully");

      print("==================================================");

      return daysMask;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ READ SCHEDULE DAYS MASK FAILED");
      print("==================================================");

      print("Error : $e");

      print("");
      print("Stack Trace:");
      print(stack);

      print("==================================================");

      return null;
    }
  }
  Future<int?> readScheduleTime() async {

    print("");
    print("==================================================");
    print("📖 READ SCHEDULE TIME");
    print("==================================================");

    try {

      // --------------------------------------------------
      // Check connection
      // --------------------------------------------------

      if (_connectedDevice == null) {

        print("❌ No Connected Device");
        print("❌ Cannot read schedule time");

        print("==================================================");

        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("🔗 Device ID : $deviceId");

      print("");
      print("➡️ Requesting schedule time from BLE service...");

      // --------------------------------------------------
      // Read from BLE
      // --------------------------------------------------

      final timeMinutes =
      await _bleService.readScheduleTime(
        deviceId,
      );

      // --------------------------------------------------
      // Result
      // --------------------------------------------------

      print("");
      print("⬅️ Schedule Time Received");

      print("------------------------------------------");
      print("⏰ Time Minutes : $timeMinutes");
      print("⏰ Time         : "
          "${(timeMinutes ~/ 60).toString().padLeft(2, '0')}:"
          "${(timeMinutes % 60).toString().padLeft(2, '0')}");
      print("------------------------------------------");

      print("");
      print("✅ Schedule Time Read Successfully");

      print("==================================================");

      return timeMinutes;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ READ SCHEDULE TIME FAILED");
      print("==================================================");

      print("Error : $e");

      print("");
      print("Stack Trace:");
      print(stack);

      print("==================================================");

      return null;
    }
  }
  Future<PotModel?> readCurrentPot() async {
    try {
      if (_connectedDevice == null) {
        print("❌ No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;


      print("📖 PROVIDER - READING CURRENT POT");
      print("Device : $deviceId");
      print("==================================================");

      return await _bleService.readCurrentPot(deviceId);

    } catch (e, stack) {


      print("❌ PROVIDER - READ CURRENT POT FAILED");
      print("Error: $e");

      print("Stack Trace:");
      print(stack);
      return null;
    }
  }

  Future<bool> readConfiguration() async {
    if (_connectedDevice == null) {
      print('❌ No connected device');
      return false;
    }

    try {
      _isReadingConfiguration = true;
      notifyListeners();

      print('');
      print('==============================================');
      print('📖 READ CONFIGURATION + LIVE STATUS');
      print('==============================================');

      // --------------------------------------------------
      // Read configuration
      // --------------------------------------------------

      final plantNameFuture = readPlantName();
      final plantTypeFuture = readPlantType();
      final daysMaskFuture = readScheduleDaysMask();
      final timeMinutesFuture = readScheduleTime();
      final waterDurationFuture = readWaterDuration();

      // --------------------------------------------------
      // Read live status
      // --------------------------------------------------

      final batteryFuture = readBatteryLevel();
      final lastWateredFuture = _bleService.readLastWatered(
        _connectedDevice!.id,
      );
      final cycleCountFuture = _bleService.readCycleCount(
        _connectedDevice!.id,
      );
      final tankStatusFuture = _bleService.readTankStatus(
        _connectedDevice!.id,
      );
      final firmwareVersionFuture = _bleService.readFirmwareVersion(
        _connectedDevice!.id,
      );
      final lowBatteryFuture = _bleService.readLowBatteryFlag(
        _connectedDevice!.id,
      );

      // --------------------------------------------------
      // Wait for all reads
      // --------------------------------------------------

      final results = await Future.wait([
        // Configuration
        plantNameFuture,
        plantTypeFuture,
        daysMaskFuture,
        timeMinutesFuture,
        waterDurationFuture,

        // Live status
        batteryFuture,
        lastWateredFuture,
        cycleCountFuture,
        tankStatusFuture,
        firmwareVersionFuture,
        lowBatteryFuture,
      ]);

      // --------------------------------------------------
      // Extract configuration results
      // --------------------------------------------------

      final plantName = results[0] as String?;
      final plantType = results[1] as int?;
      final daysMask = results[2] as int?;
      final timeMinutes = results[3] as int?;
      final waterDuration = results[4] as int?;

      // --------------------------------------------------
      // Extract live status results
      // --------------------------------------------------

      final battery = results[5] as int?;
      final lastWatered = results[6] as int?;
      final cycleCount = results[7] as int?;
      final tankStatus = results[8] as TankStatus?;
      final firmwareVersion = results[9] as String?;
      final lowBattery = results[10] as LowBatteryFlag?;

      // --------------------------------------------------
      // Store configuration values
      // --------------------------------------------------

      _plantName = plantName;
      _plantType = plantType;
      _daysMask = daysMask;
      _timeMinutes = timeMinutes;
      _waterDuration = waterDuration;

      // --------------------------------------------------
      // Store live status values
      // --------------------------------------------------

      if (battery != null) {
        _batteryLevel = battery;
      }

      if (lastWatered != null) {
        _lastWatered = lastWatered;
      }

      if (cycleCount != null) {
        _cycleCount = cycleCount;
      }

      if (tankStatus != null) {
        _tankStatus = tankStatus.index;
      }

      if (firmwareVersion != null) {
        _firmwareVersion = firmwareVersion;
      }

      if (lowBattery != null) {
        _lowBattery = lowBattery == LowBatteryFlag.low;
      }

      // --------------------------------------------------
      // Debug result
      // --------------------------------------------------

      print('');
      print('========== CONFIGURATION RESULT ==========');
      print('Plant Name       : $_plantName');
      print('Plant Type       : $_plantType');
      print('Days Mask        : $_daysMask');
      print('Time Minutes     : $_timeMinutes');
      print('Water Duration   : $_waterDuration');

      print('');
      print('========== LIVE STATUS RESULT ==========');
      print('Battery          : $_batteryLevel');
      print('Last Watered     : $_lastWatered');
      print('Cycle Count      : $_cycleCount');
      print('Tank Status      : $_tankStatus');
      print('Firmware Version : $_firmwareVersion');
      print('Low Battery      : $_lowBattery');
      print('========================================');

      return true;

    } catch (e, stack) {
      print('');
      print('❌ READ CONFIGURATION FAILED');
      print('Error: $e');
      print('Stack: $stack');

      return false;

    } finally {
      _isReadingConfiguration = false;
      notifyListeners();
    }
  }
  /// WRITE
  Future<bool> writeConfiguration({
    required int plantType,
    required String plantName,
    required int daysMask,
    required int timeMinutes,
    required int wateringsPerDay,
    required int waterDuration,
  }) async {
    if (_connectedDevice == null) {
      print('❌ No connected device');
      return false;
    }

    try {
      _isWritingPlant = true;
      _isWritingSchedule = true;

      notifyListeners();

      print('');
      print('==============================================');
      print('✍️ WRITE CONFIGURATION');
      print('==============================================');

      // Plant
      await Future.wait([
        _bleService.writePlantType(
          _connectedDevice!.id,
          plantType,
        ),
        _bleService.writePlantName(
          _connectedDevice!.id,
          plantName,
        ),
      ]);

      print('✅ Plant configuration written');

      // Schedule
      await _bleService.writeScheduleDaysMask(
        _connectedDevice!.id,
        daysMask,
      );

      await _bleService.writeScheduleTime(
        _connectedDevice!.id,
        timeMinutes,
      );

      await _bleService.writeWaterDuration(
        _connectedDevice!.id,
        waterDuration,
      );

      print('✅ Schedule configuration written');

      await setupDone();

      _hasWrittenConfiguration = true;

      print('🎉 CONFIGURATION WRITE SUCCESS');

      return true;
    } catch (e, stack) {
      print('❌ WRITE CONFIGURATION FAILED');
      print(e);
      print(stack);

      return false;
    } finally {
      _isWritingPlant = false;
      _isWritingSchedule = false;

      notifyListeners();
    }
  }
  Future<void> syncRtcNow() async {
    if (_connectedDevice == null) return;

    final unixTime =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    print(unixTime);

    await _bleService.syncRtc(
      _connectedDevice!.id,
      unixTime,
    );

    print("🕒 RTC Synced");
    print("Unix Time : $unixTime");
  }
  Future<void> setupDone() async {
    if (_connectedDevice == null) return;

    await _bleService.setupDone(_connectedDevice!.id);

    print(" Setup Done");
  }


  // Inside BleProvider class

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  double _updateProgress = 0.0;
  double get updateProgress => _updateProgress;

  // Future<void> startFirmwareUpdateOld() async {
  //   if (_connectedDevice == null) {
  //     print("❌ No device connected for DFU");
  //     return;
  //   }
  //
  //   try {
  //     _isUpdating = true;
  //     notifyListeners();
  //
  //     print("🚀 Starting DFU Update for: ${_connectedDevice!.id}");
  //
  //     // 1. Request high MTU for faster transfer
  //     await _bleService.requestMtu(deviceId: _connectedDevice!.id, mtu: 247);
  //
  //     // 2. Run the SMP Test
  //     final smpTest = SmpTest(
  //       ble: _bleService.ble, // Pass your reactive ble instance
  //       deviceId: _connectedDevice!.id,
  //     );
  //
  //     await smpTest.start();
  //
  //     print("✅ DFU Update Successful");
  //   } catch (e) {
  //     print("❌ DFU Update Failed: $e");
  //     rethrow;
  //   } finally {
  //     _isUpdating = false;
  //     notifyListeners();
  //   }
  // }
  // Inside BleProvider class



  Future<void> startFirmwareUpdateOld() async {
    if (_connectedDevice == null) return;

    try {
      _isUpdating = true;
      _updateProgress = 0.0; // Reset progress
      notifyListeners();

      print("🚀 Starting DFU Update for: ${_connectedDevice!.id}");

      await _bleService.requestMtu(deviceId: _connectedDevice!.id, mtu: 247);
      final smpTest = SmpTest(
        ble: _bleService.ble,
        deviceId: _connectedDevice!.id,

        onProgress: (progress) {
          _updateProgress = progress;
          print("Provider Progress: $_updateProgress"); // Add this debug print
          notifyListeners();
        },
      );

      await smpTest.start();

      print("✅ DFU Update Successful");
    } catch (e) {
      print("❌ DFU Update Failed: $e");
      rethrow;
    } finally {
      _isUpdating = false;
      _updateProgress = 0.0;
      notifyListeners();
    }
  }
  Future<void> startFirmwareUpdate() async {
    if (_connectedDevice == null) return;

    try {
      _isUpdating = true;
      _updateProgress = 0.0;
      notifyListeners();

      final deviceId = _connectedDevice!.id;
      print("🚀 Starting Optimized DFU Update for: $deviceId");

      // 1. Request High MTU (Already doing this, but ensure it's 512)
      // This allows more data per packet.
      await _bleService.requestMtu(deviceId: deviceId, mtu: 512);

      // 2. 🌟 CRITICAL: Request High Performance Connection Priority
      // This reduces the connection interval (time between packets)
      // from ~30ms down to ~7.5ms - 15ms on Android.
      try {
        await _bleService.requestConnectionPriority(
          deviceId: deviceId,
          priority: ConnectionPriority.highPerformance,
        );
        print("⚡ Connection priority set to High Performance");
      } catch (e) {
        print("⚠️ Could not set connection priority: $e");
      }

      // 3. Small delay to let the BLE stack apply the new parameters
      await Future.delayed(const Duration(milliseconds: 1000));


      final smpTest = SmpTest(
        ble: _bleService.ble,
        deviceId: deviceId,
        onProgress: (progress) {
          _updateProgress = progress;
          notifyListeners();
        },
      );

      await smpTest.start();

      print("✅ DFU Update Successful");
    } catch (e) {
      print("❌ DFU Update Failed: $e");
      rethrow;
    } finally {
      // 4. Optional: Reset priority to balanced to save battery after update
      try {
        await _bleService.requestConnectionPriority(
          deviceId: _connectedDevice!.id,
          priority: ConnectionPriority.balanced,
        );
      } catch (_) {}

      _isUpdating = false;
      _updateProgress = 0.0;
      notifyListeners();
    }
  }

  @override
  void dispose() {

    _statusSubscription?.cancel();

    _scanSubscription?.cancel();

    _connectionSubscription?.cancel();

    _batterySubscription?.cancel();

    super.dispose();
  }
}
