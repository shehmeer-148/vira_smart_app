import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:vira_planter_app/Presentation/Providers/plant_provider.dart';

import '../../Core/plant_library.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../../Data/Services/Ble_Vira/ble_parser.dart';
import '../../Data/Services/Ble_Vira/ble_services.dart';
import '../../Core/enums.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../Data/Services/Database/database_helper.dart';
import '../../Data/Model_classes/plant_schedule_model.dart';

class BleProvider extends ChangeNotifier {
  BleProvider(this._bleService, this._database);

  final BleService _bleService;
  final DatabaseHelper _database;

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

  /// LOCAL DATABASE
  
  bool _isSetupFinished = false;
  bool get isSetupFinished => _isSetupFinished;

  // ====================== BLUETOOTH PAIRING & SCANNING FUNCTIONS =====================//

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
    // --------------------------------------------------
    // Prevent duplicate scans
    // --------------------------------------------------

    if (isScanning) {
      print("⚠️ Scan already running");
      return;
    }

    // --------------------------------------------------
    // Do not scan while connecting / connected
    // --------------------------------------------------

    if (isConnecting || isConnected) {
      print("⚠️ Cannot start scan while connected/connecting");
      return;
    }

    print("========== START SCAN ==========");

    // --------------------------------------------------
    // Cancel any previous scan subscription
    // --------------------------------------------------

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    // --------------------------------------------------
    // Clear previous devices
    // --------------------------------------------------

    _devices.clear();

    // --------------------------------------------------
    // Update state
    // --------------------------------------------------

    _connectionState =
        BleConnectionState.scanning;

    notifyListeners();

    // --------------------------------------------------
    // Start BLE scan
    // --------------------------------------------------

    print("🔍 Starting BLE scan...");

    _scanSubscription =
        _bleService.scan().listen(
              (device) {

            // Avoid duplicate devices
            if (_devices.any((d) => d.id == device.id)) {
              return;
            }

            print(
              "📡 Device found: "
                  "${device.name.isNotEmpty ? device.name : "Unknown"} "
                  "(${device.id})",
            );

            _devices.add(device);

            notifyListeners();
          },

          onError: (error) {

            print("❌ BLE scan error: $error");

            _scanSubscription = null;

            if (_connectionState ==
                BleConnectionState.scanning) {

              _connectionState =
                  BleConnectionState.disconnected;

              notifyListeners();
            }
          },

          onDone: () {

            print("🛑 BLE scan stream completed");

            _scanSubscription = null;

            if (_connectionState ==
                BleConnectionState.scanning) {

              _connectionState =
                  BleConnectionState.disconnected;

              notifyListeners();
            }
          },
        );

    print("================================");
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
  Future<ConnectResult> connectToPot(PotModel pot) async {
    print("");
    print("=================================================");
    print("CONNECT TO SAVED POT");
    print("=================================================");
    print("Plant Name : ${pot.plantName}");
    print("Device ID  : ${pot.deviceId}");
    print("=================================================");

    // --------------------------------------------------
    // Already connected to this pot
    // --------------------------------------------------

    if (_connectedDevice?.id == pot.deviceId &&
        _connectionState == BleConnectionState.connected) {
      print("🟢 Already connected to this pot");

      return ConnectResult.connected;
    }

    // --------------------------------------------------
    // Another connection is already in progress
    // --------------------------------------------------

    if (_isConnecting) {
      print("⚠️ Another BLE connection is already in progress");
      return ConnectResult.alreadyConnecting;
    }

    // --------------------------------------------------
    // Bluetooth must be ready
    // --------------------------------------------------

    if (_bleStatus != BleStatus.ready) {
      print("❌ Bluetooth is not ready");
      print("Current BLE status: $_bleStatus");
      return ConnectResult.bluetoothNotReady;
    }

    try {

      // ------------------------------------------------
      // Stop any active scan
      // ------------------------------------------------

      print("🛑 Stopping previous scan...");
      await stopScan();

      // ------------------------------------------------
      // Disconnect currently connected pot
      // ------------------------------------------------

      if (_connectedDevice != null) {
        print("🔌 Another pot is connected");
        print("Disconnecting current pot...");

        await disconnect();

        // Give Android BLE stack a moment
        await Future.delayed(
          const Duration(milliseconds: 300),
        );
      }

      // ------------------------------------------------
      // Prepare fresh scan
      // ------------------------------------------------

      _devices.clear();
      _connectionState = BleConnectionState.scanning;
      _connectingPotId = pot.deviceId;

      notifyListeners();

      print("");
      print("🔍 Starting BLE scan...");
      print("Looking for device:");
      print("   ${pot.deviceId}");

      // ------------------------------------------------
      // Completer
      // ------------------------------------------------

      final completer = Completer<DiscoveredDevice?>();

      // ------------------------------------------------
      // Start scan
      // ------------------------------------------------

      await _scanSubscription?.cancel();

      _scanSubscription =
          _bleService.scan().listen(
                (device) {

              print("");
              print("📡 BLE DEVICE DISCOVERED");
              print("Name : ${device.name}");
              print("ID   : ${device.id}");
              print("RSSI : ${device.rssi}");

              // --------------------------------------------
              // Add to discovered devices
              // --------------------------------------------

              if (_devices.every(
                    (d) => d.id != device.id,
              )) {
                _devices.add(device);
                notifyListeners();
              }

              // --------------------------------------------
              // Check target device
              // --------------------------------------------

              if (device.id == pot.deviceId) {
                print("");
                print("🎯 TARGET POT FOUND!");
                print("Plant Name : ${pot.plantName}");
                print("Device ID  : ${device.id}");

                if (!completer.isCompleted) {
                  completer.complete(device);
                }
              }
            },
            onError: (error) {
              print("");
              print("❌ BLE SCAN ERROR");
              print(error);

              if (!completer.isCompleted) {
                completer.complete(null);
              }
            },
          );

      // ------------------------------------------------
      // Wait for target pot
      // ------------------------------------------------

      print("");
      print("⏳ Waiting for target pot...");

      final device =
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print("");
          print("⏰ POT DISCOVERY TIMEOUT");
          print("Device ID: ${pot.deviceId}");

          return null;
        },
      );

      // ------------------------------------------------
      // Target not found
      // ------------------------------------------------

      if (device == null) {
        print("");
        print("❌ TARGET POT NOT FOUND");

        await stopScan();

        _connectionState =
            BleConnectionState.disconnected;
        _connectingPotId = null;

        notifyListeners();

        return ConnectResult.deviceNotFound;
      }

      // ------------------------------------------------
      // Target found → stop scanning
      // ------------------------------------------------

      print("");
      print("🛑 Target pot found");
      print("Stopping scan...");

      await stopScan();

      // ------------------------------------------------
      // Store actual discovered device
      // ------------------------------------------------

      _selectedDevice = device;

      print("");
      print("✅ Target device selected");
      print("Name : ${device.name}");
      print("ID   : ${device.id}");
      print("RSSI : ${device.rssi}");

      // ------------------------------------------------
      // Connect using existing connect()
      // ------------------------------------------------

      print("");
      print("🔗 Calling connect()...");

      final connected =
      await connect();

      // ------------------------------------------------
      // Result
      // ------------------------------------------------

      if (connected) {
        print("");
        print("=================================================");
        print("🟢 POT CONNECTED SUCCESSFULLY");
        print("=================================================");
        print("Plant Name : ${pot.plantName}");
        print("Device ID  : ${pot.deviceId}");
        print("=================================================");

        // ---------------------------------------------
        // Read VIRA values and save to database
        // ---------------------------------------------

        final synced = await syncConnectedPotToDatabase();

        if (!synced) {
          print("⚠️ Pot connected but sync failed");
        } else {
          print("✅ Pot connected and database synced");
        }
        _connectingPotId = null;
        notifyListeners();

        return ConnectResult.connected;
      }

      print("");
      print("=================================================");
      print("🔴 POT CONNECTION FAILED");
      print("=================================================");
      print("Plant Name : ${pot.plantName}");
      print("Device ID  : ${pot.deviceId}");
      print("=================================================");
      _connectingPotId = null;
      notifyListeners();

      return ConnectResult.connectionFailed;

    } catch (e, stack) {
      print("");
      print("=================================================");
      print("❌ CONNECT TO POT EXCEPTION");
      print("=================================================");

      print("Plant Name : ${pot.plantName}");
      print("Device ID  : ${pot.deviceId}");

      print("");
      print("Error:");
      print(e);

      print("");
      print("Stack:");
      print(stack);

      // ------------------------------------------------
      // Cleanup
      // ------------------------------------------------

      await stopScan();

      _connectedDevice = null;
      _selectedDevice = null;
      _connectingPotId = null;

      _isConnecting = false;

      _connectionState =
          BleConnectionState.disconnected;

      notifyListeners();

      return ConnectResult.connectionFailed;
    }
  }

  // ====================== DATABASE FUNCTIONS =====================//

  /// INSERT OR UPDATE
  Future<bool> saveCurrentPot({
    required PotModel pot,
  }) async {

    try {

      final exists =
      await potExists(pot.deviceId);

      if (exists) {

        final oldPot =
        await _database.getPot(
            pot.deviceId);

        final updatedPot = pot.copyWith(
          id: oldPot!.id,
          pairedAt: oldPot.pairedAt,
          lastSynced: DateTime.now().millisecondsSinceEpoch,
        );

        await _database.updatePot(updatedPot);

        print("✏ Pot Updated");

      } else {


        final newPot = pot.copyWith(

          pairedAt:
          DateTime.now().millisecondsSinceEpoch,

          lastSynced:
          DateTime.now().millisecondsSinceEpoch,

        );

        await _database.insertPot(newPot);

        print("💾 New Pot Saved");

      }

      return true;

    } catch (e) {

      print(e);

      return false;

    }
  }
 /// FINISH SETUP
  Future<bool> finishSetup(PlantProvider plant) async {
    _isSetupFinished = true;
    notifyListeners();

    try {

      print("=================================");
      print("🔄 Finishing Current Pot");
      print("=================================");

      await Future.delayed(
        const Duration(seconds: 1),
      );
       final pot = await readCurrentPot();
      
      //final pot = await readDummyCurrentPot(plantProvider: plant);
      if (pot == null) {

        print("❌ Failed to read pot from BLE");

        return false;
      }

      // Save SQLite

      print("💾 Saving Pot...");

      final success = await saveCurrentPot(
        pot: pot,
      );

      if (!success) {

        print("❌ Failed to save pot");

        return false;
      }


      print("✅ Provider Updated");
      print("🎉 Refresh Completed Successfully");

      return true;

    } catch (e, stack) {

      print("=================================");
      print("❌ Refresh Current Pot Failed");
      print("=================================");
      print(e);
      print(stack);

      return false;
    }
    finally{
      _isSetupFinished = false;
      notifyListeners();
    }
  }
 /// CHECK EXISTS
  Future<bool> potExists(
      String deviceId,
      ) async {

    return await _database.potExists(
      deviceId,
    );
  }
  /// CLEAR
  Future<void> clearLocalDatabase() async {

    await _database.clearDatabase();

    notifyListeners();
  }
  /// SYNC POT VALUES TO DATABASE
  Future<bool> syncConnectedPotToDatabase() async {
    print("");
    print("==============================================");
    print("🔄 SYNCING CONNECTED POT");
    print("==============================================");

    if (_connectedDevice == null) {
      print("❌ Cannot sync - no connected device");
      return false;
    }

    try {


      print("📖 Reading pot values from VIRA...");

      final pot = await readCurrentPot();

      if (pot == null) {
        print("❌ Failed to read pot values");
        return false;
      }

      // ---------------------------------------------
      // Save / update SQLite
      // ---------------------------------------------

      print("💾 Saving synced pot to database...");

      final success = await saveCurrentPot(
        pot: pot,
      );

      if (!success) {
        print("❌ Failed to save synced pot");
        return false;
      }

      print("✅ Pot synced successfully");
      print("==============================================");

      return true;

    } catch (e, stack) {

      print("❌ Pot sync failed");
      print(e);
      print(stack);

      return false;
    }
  }

// ====================== BLUETOOTH READ/WRITE/NOTIFY FUNCTIONS =====================//

  /// READ

  Future<String?> readPlantName() async {
    try {
      if (_connectedDevice == null) {
        print("❌ Cannot read plant name: No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("");
      print("==========================================");
      print("📖 READ PLANT NAME");
      print("Device: $deviceId");
      print("==========================================");

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

      print("");
      print("==========================================");
      print("📖 READ PLANT TYPE");
      print("Device: $deviceId");
      print("==========================================");

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
  Future<void> readDeviceInfo() async {
    try {
      if (_connectedDevice == null) {
        print("❌ No connected device");
        return;
      }

      final deviceId = _connectedDevice!.id;

      print("");
      print("==================================================");
      print("🔍 READING VIRA DEVICE INFO");
      print("==================================================");
      print("BLE Device ID : $deviceId");

      final deviceUuid =
      await _bleService.readDeviceUuid(deviceId);

      final firmware =
      await _bleService.readFirmwareVersion(deviceId);

      print("");
      print("==================================================");
      print("✅ VIRA DEVICE INFO");
      print("==================================================");
      print("📱 BLE Device ID : $deviceId");
      print("🔑 Device UUID   : $deviceUuid");
      print("⚙️ Firmware      : $firmware");
      print("==================================================");

    } catch (e, stack) {
      print("");
      print("❌ FAILED TO READ DEVICE INFO");
      print("Error: $e");
      print(stack);
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
  Future<BleSchedule?> readSchedule() async {

    print("");
    print("==================================================");
    print("📖 READ SCHEDULE");
    print("==================================================");

    try {

      // --------------------------------------------------
      // Check connection
      // --------------------------------------------------

      if (_connectedDevice == null) {

        print("❌ No Connected Device");
        print("❌ Cannot read schedule");

        print("==================================================");
        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("🔗 Device ID : $deviceId");


      print("");
      print("➡️ Sending READ request to Vira...");

      // --------------------------------------------------
      // Read schedule
      // --------------------------------------------------

      final schedule =
      await _bleService.readSchedule(deviceId);

      print("");
      print("⬅️ Schedule received from Vira");

      // --------------------------------------------------
      // Parsed values
      // --------------------------------------------------

      print("");
      print("📅 PARSED SCHEDULE");
      print("----------------------------------");
      print("Days Mask        : ${schedule.daysMask}");
      print("Time Minutes     : ${schedule.timeMinutes}");
      print("Waterings / Day  : ${schedule.wateringsPerDay}");
      print("----------------------------------");

      // --------------------------------------------------
      // Human-readable time
      // --------------------------------------------------

      final hours = schedule.timeMinutes ~/ 60;
      final minutes = schedule.timeMinutes % 60;

      print(
        "⏰ Watering Time  : "
            "${hours.toString().padLeft(2, '0')}:"
            "${minutes.toString().padLeft(2, '0')}",
      );

      print("");
      print("✅ Schedule Read Successfully");
      print("==================================================");

      return schedule;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ READ SCHEDULE FAILED");
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

      print("");
      print("==================================================");
      print("📖 Reading Current Pot - SEQUENTIAL");
      print("Device : $deviceId");
      print("==================================================");

      //==================================================
      // 1. PLANT NAME
      //==================================================

      print("");
      print("1️⃣ Reading Plant Name...");

      final plantName =
      await _bleService.readPlantName(deviceId);

      print("✅ Plant Name: $plantName");


      //==================================================
      // 2. PLANT TYPE
      //==================================================

      print("");
      print("2️⃣ Reading Plant Type...");

      final plantType =
      await _bleService.readPlantType(deviceId);

      print("✅ Plant Type: $plantType");


      //==================================================
      // 3. DAYS MASK
      //==================================================

      print("");
      print("3️⃣ Reading Schedule Days Mask...");

      final daysMask =
      await _bleService.readScheduleDaysMask(deviceId);

      print("✅ Days Mask: $daysMask");


      //==================================================
      // 4. SCHEDULE TIME
      //==================================================

      print("");
      print("4️⃣ Reading Schedule Time...");

      final timeMinutes =
      await _bleService.readScheduleTime(deviceId);

      print("✅ Time Minutes: $timeMinutes");


      //==================================================
      // 5. WATER DURATION
      //==================================================

      print("");
      print("5️⃣ Reading Water Duration...");

      final waterDuration =
      await _bleService.readWaterDuration(deviceId);

      print("✅ Water Duration: $waterDuration seconds");


      //==================================================
      // 6. BATTERY
      //==================================================

      print("");
      print("6️⃣ Reading Battery Level...");

      final batteryLevel =
      await _bleService.readBatteryLevel(deviceId);

      print("✅ Battery: $batteryLevel%");


      //==================================================
      // 7. LAST WATERED
      //==================================================

      print("");
      print("7️⃣ Reading Last Watered...");

      final lastWatered =
      await _bleService.readLastWatered(deviceId);

      print("✅ Last Watered: $lastWatered");


      //==================================================
      // 8. CYCLE COUNT
      //==================================================

      print("");
      print("8️⃣ Reading Cycle Count...");

      final cycleCount =
      await _bleService.readCycleCount(deviceId);

      print("✅ Cycle Count: $cycleCount");


      //==================================================
      // 9. TANK STATUS
      //==================================================

      print("");
      print("9️⃣ Reading Tank Status...");

      final tankStatus =
      await _bleService.readTankStatus(deviceId);

      print("✅ Tank Status: ${tankStatus.name}");


      //==================================================
      // 10. DEVICE UUID
      //==================================================
      print("Waiting before reading Device UUID...");
      await Future.delayed(const Duration(seconds: 1));
      print("");
      print("🔟 Reading Device UUID...");

      final deviceUuid =
      await _bleService.readDeviceUuid(deviceId);

      print("✅ Device UUID: $deviceUuid");


      //==================================================
      // 11. FIRMWARE
      //==================================================

      print("");
      print("1️⃣1️⃣ Reading Firmware Version...");

      final firmware =
      await _bleService.readFirmwareVersion(deviceId);

      print("✅ Firmware: $firmware");


      //==================================================
      // 12. LOW BATTERY FLAG
      //==================================================

      print("");
      print("1️⃣2️⃣ Reading Low Battery Flag...");

      final lowBattery =
      await _bleService.readLowBatteryFlag(deviceId);

      print("✅ Low Battery: ${lowBattery.name}");


      //==================================================
      // PLANT LIBRARY
      //==================================================

      final libraryPlant =
      PlantLibrary.getById(plantType);


      //==================================================
      // FINAL DATA
      //==================================================

      print("");
      print("==================================================");
      print("📦 RAW DATA RECEIVED FROM VIRA POT");
      print("==================================================");

      print("🪴 Plant Name       : $plantName");
      print("🪴 Plant Type       : $plantType");

      print("");

      print("📅 Schedule");
      print("   Days Mask        : $daysMask");
      print("   Time Minutes     : $timeMinutes");
      print("   Water Duration   : $waterDuration sec");

      print("");

      print("📊 Status");
      print("   Battery          : $batteryLevel%");
      print("   Last Watered     : $lastWatered");
      print("   Cycle Count      : $cycleCount");
      print("   Tank Status      : ${tankStatus.name}");
      print("   Low Battery      : ${lowBattery.name}");

      print("");

      print("🔧 Device");
      print("   Device UUID      : $deviceUuid");
      print("   Firmware         : $firmware");

      print("");

      print("📚 Plant Library");
      print("   Image            : ${libraryPlant?.image}");
      print("   Category         : ${libraryPlant?.category}");
      print("   Water Interval   : ${libraryPlant?.wateringIntervalDays}");

      print("==================================================");


      //==================================================
      // CREATE POT MODEL
      //==================================================

      final pot = PotModel(
        deviceId: _connectedDevice!.id,

        //---------------- Plant ----------------//

        plantType: plantType,
        plantName: plantName,
        plantImage: libraryPlant?.image ?? "",
        wateringIntervalDays:
        libraryPlant?.wateringIntervalDays ?? 0,

        //---------------- Schedule ----------------//

        daysMask: daysMask,
        timeMinutes: timeMinutes,

        // Temporarily removed from Vira hardware
        wateringsPerDay: 0,

        waterDuration: waterDuration,

        //---------------- Status ----------------//

        batteryLevel: batteryLevel,
        tankStatus: tankStatus.index,
        lastWatered: lastWatered,
        cycleCount: cycleCount,
        firmwareVersion: firmware,
        lowBattery: lowBattery == LowBatteryFlag.low,

        //---------------- App ----------------//

        pairedAt: 0,
        lastSynced:
        DateTime.now().millisecondsSinceEpoch,
      );


      //==================================================
      // FINAL RESULT
      //==================================================

      print("");
      print("==================================================");
      print("🧱 POT MODEL CREATED");
      print("==================================================");
      print(pot);
      print("==================================================");

      return pot;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ READ CURRENT POT FAILED");
      print("==================================================");

      print("Error: $e");

      print("");
      print("Stack Trace:");
      print(stack);

      print("==================================================");

      return null;
    }
  }

  /// WRITE
  Future<bool> saveSelectedPlant({
    required int plantId,
    required String plantName,
  }) async {
    _isWritingPlant = true;
    notifyListeners();
    try {
      if (_connectedDevice == null) {
        print("❌ No connected device");
        return false;
      }

      print("");
      print("=================================");
      print("🌿 Saving Plant");
      print("Device : ${_connectedDevice!.id}");
      print("Plant ID   : $plantId");
      print("Plant Name : $plantName");
      print("=================================");

      //----------------------------------
      // Write Plant Type And Name
      //----------------------------------
      print("➡ Writing Plant Type And Name...");

      await Future.wait([
        _bleService.writePlantType(
          _connectedDevice!.id,
          plantId,
        ),
        _bleService.writePlantName(
          _connectedDevice!.id,
          plantName,
        ),
      ]);

      print("✅ Plant Type And Name Written");

      print("🎉 Plant Saved Successfully");

      return true;
    } catch (e) {
      print("❌ Error Saving Plant");
      print(e);

      return false;
    }
    finally{
      _isWritingPlant = false;
      notifyListeners();
    }
  }

  Future<bool> saveSchedule({
    required PlantSchedule schedule,
  }) async {

    _isWritingSchedule = true;
    notifyListeners();

    try {

      if (_connectedDevice == null) {
        print("❌ No connected device");
        return false;
      }

      final deviceId = _connectedDevice!.id;

      print("");
      print("==============================================");
      print("📅 SAVE SCHEDULE - NEW SPEC WRITE/READ TEST");
      print("==============================================");

      print("Device ID       : $deviceId");
      print("Days Mask       : ${schedule.daysMask}");
      print("Time Minutes    : ${schedule.timeMinutes}");
      print("Water Duration  : ${schedule.waterDuration}");
      print("==============================================");


      // ==================================================
      // 1️⃣ WRITE DAYS MASK - FFD3
      // ==================================================

      print("");
      print("1️⃣ WRITE DAYS MASK");
      print("----------------------------------------------");

      await _bleService.writeScheduleDaysMask(
        deviceId,
        schedule.daysMask,
      );

      print("✅ Days Mask WRITE completed");

      // ==================================================
      // 3️⃣ WRITE SCHEDULE TIME - FFD4
      // ==================================================

      print("");
      print("3️⃣ WRITE SCHEDULE TIME");
      print("----------------------------------------------");

      await _bleService.writeScheduleTime(
        deviceId,
        schedule.timeMinutes,
      );

      print("✅ Schedule Time WRITE completed");


      // ==================================================
      // 5️⃣ WRITE WATER DURATION - FFD5
      // ==================================================

      print("");
      print("5️⃣ WRITE WATER DURATION");
      print("----------------------------------------------");

      await _bleService.writeWaterDuration(
        deviceId,
        schedule.waterDuration,
      );

      print("✅ Water Duration WRITE completed");




      return true;

    } catch (e, stack) {

      print("");
      print("==============================================");
      print("❌ WRITE/READ TEST FAILED");
      print("==============================================");

      print("Error: $e");
      print("");
      print("Stack:");
      print(stack);

      return false;

    } finally {

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

  /// NOTIFICATION
  void startBatteryNotification() {

    print("");
    print("==================================================");
    print("🔔 START BATTERY NOTIFICATION");
    print("==================================================");

    if (deviceId == null) {
      print("❌ Cannot start battery notification");
      print("❌ Device ID is null");
      return;
    }

    print("📱 Device ID: $deviceId");
    // print("🔧 Service: ${BleConstants.serviceStatus}");
    // print("🔧 Characteristic: ${BleConstants.battery}");

    _batterySubscription?.cancel();

    print("🧹 Previous battery subscription cancelled");

    _batterySubscription =
        _bleService
            .batteryStream(deviceId!)
            .listen(
              (battery) {

            print("");
            print("🔋 ==========================================");
            print("🔋 BATTERY NOTIFICATION RECEIVED");
            print("🔋 Battery Value: $battery%");
            print("🔋 ==========================================");

            // _batteryLevel = battery;

            notifyListeners();
          },
          onError: (error) {

            print("");
            print("❌ ==========================================");
            print("❌ BATTERY NOTIFICATION ERROR");
            print("❌ $error");
            print("❌ ==========================================");

          },
          onDone: () {

            print("");
            print("🛑 ==========================================");
            print("🛑 BATTERY NOTIFICATION STREAM CLOSED");
            print("🛑 ==========================================");

          },
        );

    print("✅ Battery notification listener started");
    print("==================================================");
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
