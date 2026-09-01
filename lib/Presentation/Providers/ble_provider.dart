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
  }  /// SELECT DEVICE
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
  Future<bool> connectToViraPot(PotModel pot) async {
    print("");
    print("=================================================");
    print("🔗 CONNECT TO SAVED POT");
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
      return true;
    }

    // --------------------------------------------------
    // Another connection is already in progress
    // --------------------------------------------------

    if (_isConnecting) {
      print("⚠️ Another BLE connection is already in progress");
      return false;
    }

    // --------------------------------------------------
    // Bluetooth must be ready
    // --------------------------------------------------

    if (_bleStatus != BleStatus.ready) {
      print("❌ Bluetooth is not ready");
      print("Current BLE status: $_bleStatus");
      return false;
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

        return false;
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
        _connectingPotId = null;
        notifyListeners();

        return true;
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

      return false;

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

      return false;
    }
  }
  Future<ConnectResult> connectToPot(PotModel pot) async {
    print("");
    print("=================================================");
    print("🔗 CONNECT TO SAVED POT");
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

        // final synced = await syncConnectedPotToDatabase();
        //
        // if (!synced) {
        //   print("⚠️ Pot connected but sync failed");
        // } else {
        //   print("✅ Pot connected and database synced");
        // }
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

          lastSynced:
          DateTime.now().millisecondsSinceEpoch,
        );

        await _database.updatePot(updatedPot);

        print("✏ Pot Updated");

      } else {

        //------------------------------------------
        // First ever pairing
        //------------------------------------------

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
 /// UPDATE
  Future<bool> updateCurrentPot(
      PotModel pot,
      ) async {

    try {

      await _database.updatePot(pot);

      print("✏ Pot Updated");

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

       //final pot = await readCurrentPot();
      
      final pot = await readDummyCurrentPotOld(plantProvider: plant);
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
      // ---------------------------------------------
      // Read actual values from VIRA
      // ---------------------------------------------

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

// ====================== SYNC POT VALUES TO DATABASE =====================//
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
  // Future<BleSchedule?> readSchedule() async {
  //
  //   try {
  //
  //     if (_connectedDevice == null) {
  //       print("❌ No Connected Device");
  //       return null;
  //     }
  //
  //     final schedule =
  //     await _bleService.readSchedule(
  //       _connectedDevice!.id,
  //     );
  //
  //     print(schedule);
  //
  //
  //     return schedule;
  //
  //   } catch (e) {
  //
  //     print(e);
  //
  //     return null;
  //   }
  // }

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
  Future<PotModel?> readCurrentPot() async {
    try {
      if (_connectedDevice == null) {
        print("❌ No connected device");
        return null;
      }

      final deviceId = _connectedDevice!.id;

      print("");
      print("==================================================");
      print("📖 Reading Current Pot");
      print("Device : $deviceId");
      print("==================================================");

      //--------------------------------------------------
      // Read everything in parallel
      //--------------------------------------------------

      final results = await Future.wait([

        //---------------- Configuration ----------------//

        _bleService.readPlantName(deviceId),
        _bleService.readPlantType(deviceId),
        _bleService.readSchedule(deviceId),
        _bleService.readWaterDuration(deviceId),

        //---------------- Status ----------------//

        _bleService.readBatteryLevel(deviceId),
        _bleService.readLastWatered(deviceId),
        _bleService.readCycleCount(deviceId),
        _bleService.readTankStatus(deviceId),
        _bleService.readDeviceUuid(deviceId),
        _bleService.readFirmwareVersion(deviceId),
        _bleService.readLowBatteryFlag(deviceId),
      ]);

      //--------------------------------------------------
      // Cast
      //--------------------------------------------------

      final plantName = results[0] as String;
      final plantType = results[1] as int;
      final schedule = results[2] as BleSchedule;
      final waterDuration = results[3] as int;

      final batteryLevel = results[4] as int;
      final lastWatered = results[5] as int;
      final cycleCount = results[6] as int;
      final tankStatus = results[7] as TankStatus;
      final deviceUuid = results[8] as String;
      final firmware = results[9] as String;
      final lowBattery = results[10] as LowBatteryFlag;

      final libraryPlant =
      PlantLibrary.getById(plantType);

      print("✅ Pot Read Successfully");

      //--------------------------------------------------
// Debug Prints
//--------------------------------------------------

      print("");
      print("==================================================");
      print("📦 RAW DATA RECEIVED FROM VIRA POT");
      print("==================================================");

      print("🪴 Plant Name           : $plantName");
      print("🪴 Plant Type           : $plantType");

      print("");

      print("📅 Schedule");
      print("   Days Mask           : ${schedule.daysMask}");
      print("   Time Minutes        : ${schedule.timeMinutes}");
      print("   Waterings / Day     : ${schedule.wateringsPerDay}");
      print("   Water Duration      : $waterDuration sec");

      print("");

      print("📊 Status");
      print("   Battery             : $batteryLevel%");
      print("   Last Watered        : $lastWatered");
      print("   Cycle Count         : $cycleCount");
      print("   Tank Status         : ${tankStatus.name}");
      print("   Low Battery         : ${lowBattery.name}");

      print("");

      print("🔧 Device");
      print("   Device UUID         : $deviceUuid");
      print("   Firmware            : $firmware");

      print("");

      print("📚 Plant Library Lookup");
      print("   Image               : ${libraryPlant?.image}");
      print("   Category            : ${libraryPlant?.category}");
      print("   Water Interval      : ${libraryPlant?.wateringIntervalDays}");

      print("==================================================");

      // return PotModel(
      //
      //   deviceId: deviceUuid,
      //   plantType: plantType,
      //   plantName: plantName,
      //   plantImage: libraryPlant?.image ?? "",
      //   wateringIntervalDays:
      //   libraryPlant?.wateringIntervalDays ?? 0,
      //   daysMask: schedule.daysMask,
      //   timeMinutes: schedule.timeMinutes,
      //   wateringsPerDay:
      //   schedule.wateringsPerDay,
      //   waterDuration: waterDuration,
      //   batteryLevel: batteryLevel,
      //   tankStatus: tankStatus.index,
      //   lastWatered: lastWatered,
      //   cycleCount: cycleCount,
      //   firmwareVersion: firmware,
      //   lowBattery: lowBattery == LowBatteryFlag.low,
      //   pairedAt: 0, // Temporary values
      //   lastSynced: DateTime.now().millisecondsSinceEpoch,
      // );
      final pot = PotModel(
        deviceId: deviceUuid,
        plantType: plantType,
        plantName: plantName,
        plantImage: libraryPlant?.image ?? "",
        wateringIntervalDays:
        libraryPlant?.wateringIntervalDays ?? 0,
        daysMask: schedule.daysMask,
        timeMinutes: schedule.timeMinutes,
        wateringsPerDay: schedule.wateringsPerDay,
        waterDuration: waterDuration,
        batteryLevel: batteryLevel,
        tankStatus: tankStatus.index,
        lastWatered: lastWatered,
        cycleCount: cycleCount,
        firmwareVersion: firmware,
        lowBattery: lowBattery == LowBatteryFlag.low,
        pairedAt: 0,
        lastSynced: DateTime.now().millisecondsSinceEpoch,
      );

      print("");
      print("==================================================");
      print("🧱 POT MODEL CREATED");
      print("==================================================");
      print(pot);
      print("==================================================");

      return pot;

    } catch (e, stack) {
      print(e);
      print(stack);

      return null;
    }
  }
  Future<PotModel?> readDummyCurrentPotOld({
    required PlantProvider plantProvider,
  }) async {
    try {
      if (_connectedDevice == null) {
        print("❌ No connected device");
        return null;
      }

      final selectedPlant = plantProvider.selectedPlant;
      final schedule = plantProvider.schedule;

      if (selectedPlant == null || schedule == null) {
        print("❌ Plant or Schedule not found");
        return null;
      }

      print("");
      print("==================================================");
      print("🧪 Creating Dummy Pot");
      print("==================================================");

      final pot = PotModel(
        deviceId: _connectedDevice!.id,

        //---------------- Plant ----------------//

        plantType: selectedPlant.id,
        plantName: selectedPlant.name,
        plantImage: selectedPlant.image,
        wateringIntervalDays: selectedPlant.wateringIntervalDays,

        //---------------- Schedule ----------------//

        daysMask: schedule.daysMask,
        timeMinutes: schedule.timeMinutes,
        wateringsPerDay: schedule.wateringsPerDay,
        waterDuration: schedule.waterDuration,

        //---------------- Dummy Status ----------------//

        batteryLevel: 65,
        tankStatus: TankStatus.ok.index,
        lastWatered: 0,
        cycleCount: 0,
        firmwareVersion: "1.0.0",
        lowBattery: false,

        //---------------- App ----------------//

        pairedAt: 0,
        lastSynced: DateTime.now().millisecondsSinceEpoch,
      );

      print("");
      print("==================================================");
      print("🧪 DUMMY DATA");
      print("==================================================");

      print("🪴 Plant Name        : ${pot.plantName}");
      print("🪴 Plant Type        : ${pot.plantType}");
      print("🖼 Plant Image       : ${pot.plantImage}");

      print("");

      print("📅 Schedule");
      print("Days Mask           : ${pot.daysMask}");
      print("Time Minutes        : ${pot.timeMinutes}");
      print("Waterings / Day     : ${pot.wateringsPerDay}");
      print("Water Duration      : ${pot.waterDuration}");

      print("");

      print("📊 Dummy Status");
      print("Battery             : ${pot.batteryLevel}%");
      print("Tank Status         : ${TankStatus.values[pot.tankStatus]}");
      print("Cycle Count         : ${pot.cycleCount}");
      print("Last Watered        : ${pot.lastWatered}");
      print("Low Battery         : ${pot.lowBattery}");

      print("");

      print("🔧 Device");
      print("Device ID           : ${pot.deviceId}");
      print("Firmware            : ${pot.firmwareVersion}");

      print("");

      print("==================================================");
      print("🧱 POT MODEL CREATED");
      print("==================================================");
      print(pot);
      print("==================================================");

      return pot;
    } catch (e, stack) {
      print("❌ Dummy Pot Creation Failed");
      print(e);
      print(stack);
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
  Future<bool> saveScheduleOld({
    required PlantSchedule schedule,
  }) async {

    _isWritingSchedule = true;
    notifyListeners();

    try {

      if (_connectedDevice == null) {
        print("❌ No connected device");
        return false;
      }

      print("");
      print("=================================");
      print("📅 Saving Watering Schedule");
      print("=================================");

      print("Device ID        : ${_connectedDevice!.id}");
      print("Days Mask        : ${schedule.daysMask}");
      print("Time Minutes     : ${schedule.timeMinutes}");
      print("Waterings / Day  : ${schedule.wateringsPerDay}");
      print("Water Duration   : ${schedule.waterDuration}");
      print("=================================");

      //------------------------------------------------
      // Write Schedule + Duration together
      //------------------------------------------------

      print("➡ Writing Schedule Config...");

      await Future.wait([

        _bleService.writeScheduleConfig(
          _connectedDevice!.id,
          daysMask: schedule.daysMask,
          timeMinutes: schedule.timeMinutes,
          wateringsPerDay: schedule.wateringsPerDay,
        ),

        _bleService.writeWaterDuration(
          _connectedDevice!.id,
          schedule.waterDuration,
        ),

      ]);

      print("✅ Schedule Written Successfully");
      await setupDone();
      print("✅ SetupConfiguration Done and Written Successfully");

      return true;

    } catch (e) {

      print("❌ Error Writing Schedule");
      print(e);

      return false;

    } finally {

      _isWritingSchedule = false;
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
      print("📅 SAVE SCHEDULE - WRITE/READ TEST");
      print("==============================================");

      print("Device ID       : $deviceId");
      print("Days Mask       : ${schedule.daysMask}");
      print("Time Minutes    : ${schedule.timeMinutes}");
      print("Waterings/Day   : ${schedule.wateringsPerDay}");
      print("Water Duration  : ${schedule.waterDuration}");
      print("==============================================");


      // ==================================================
      // 1️⃣ WRITE SCHEDULE
      // ==================================================

      print("");
      print("1️⃣ WRITE SCHEDULE");
      print("----------------------------------------------");

      await _bleService.writeScheduleConfig(
        deviceId,
        daysMask: schedule.daysMask,
        timeMinutes: schedule.timeMinutes,
        wateringsPerDay: schedule.wateringsPerDay,
      );

      print("✅ Schedule WRITE completed");


      // ==================================================
      // 2️⃣ READ SCHEDULE IMMEDIATELY
      // ==================================================

      print("");
      print("2️⃣ READ SCHEDULE AFTER WRITE");
      print("----------------------------------------------");

      final readScheduleResult =
      await readSchedule();

      if (readScheduleResult == null) {

        print("❌ Schedule READ failed");

      } else {

        print("✅ Schedule READ successful");

        print("📥 Values returned by Vira:");
        print("   Days Mask       : ${readScheduleResult.daysMask}");
        print("   Time Minutes    : ${readScheduleResult.timeMinutes}");
        print("   Waterings/Day   : ${readScheduleResult.wateringsPerDay}");
        // print("   Water Duration  : ${readScheduleResult.waterDuration}");

      }


      // ==================================================
      // 3️⃣ WRITE WATER DURATION
      // ==================================================

      print("");
      print("3️⃣ WRITE WATER DURATION");
      print("----------------------------------------------");

      await _bleService.writeWaterDuration(
        deviceId,
        schedule.waterDuration,
      );

      print("✅ Water Duration WRITE completed");


      // ==================================================
      // 4️⃣ READ WATER DURATION IMMEDIATELY
      // ==================================================

      print("");
      print("4️⃣ READ WATER DURATION AFTER WRITE");
      print("----------------------------------------------");

      final readDurationResult =
      await readWaterDuration();

      if (readDurationResult == null) {

        print("❌ Water Duration READ failed");

      } else {

        print("✅ Water Duration READ successful");
        print("📥 Vira returned: $readDurationResult seconds");

      }


      // ==================================================
      // 5️⃣ DO NOT SETUP DONE YET
      // ==================================================

      print("");
      print("==============================================");
      print("🧪 WRITE/READ TEST COMPLETED");
      print("==============================================");

      print("⚠️ Setup Done NOT sent");
      print("⚠️ This is intentional for debugging");
      print("==============================================");


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

  ///  NOTIFICATION
  void startBatteryNotification() {

    if (deviceId == null) return;

    _batterySubscription?.cancel();

    _batterySubscription =
        _bleService
            .batteryStream(deviceId!)
            .listen((battery) {

         // _batteryLevel = battery;

          notifyListeners();
        });
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
