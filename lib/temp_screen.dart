import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

import 'Core/app_colors.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  final flutterReactiveBle = FlutterReactiveBle();

  /// streamsSubscription for bluetooth status(on/off) ///
  /// streamsSubscription for bluetooth scan(all near by devices scan)  ///
  /// streamsSubscription for bluetooth connection State( connecting or disconnecting)   ///

  StreamSubscription<ConnectionStateUpdate>? connection;
  StreamSubscription<BleStatus>? bleStatusSub;
  StreamSubscription<DiscoveredDevice>? scanSub;

  /// for battery notification subscription ///
  StreamSubscription<List<int>>? batterySubscription;

  /// list for scaned devices ///
  List<DiscoveredDevice> devices = [];

  /// state variables ///
  bool isReady = false;
  String message = "Initializing...";
  bool isDialogShowing = false;
  bool isConnected = false;
  String? connectedDeviceId;
  ////////////////////////////////////
  int leftBattery = 0;
  int rightBattery = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  // ================= INIT =================
  Future<void> init() async {
    bool granted = await checkAndRequestPermissions();

    if (!granted) {
      setState(() {
        message = "❌ Permissions required to continue";
      });
      return;
    }

    /// data coming in stream in real time like bluetooth on/off
    bleStatusSub = flutterReactiveBle.statusStream.listen((status) {
      print("BLE Status: $status");

      if (status == BleStatus.ready) {
        if (!isReady) {
          setState(() {
            isReady = true;
            message = "Scanning...";
          });
          startScan();
        }
      } else {
        setState(() {
          isReady = false;
        });
        handleBleNotReady(status);
      }
    });
  }

  // ================= PERMISSIONS =================
  Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((s) => s.isGranted);
    } else {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
  }

  // ================= SCAN =================
  void startScan() {
    scanSub?.cancel();
    devices.clear();

    scanSub = flutterReactiveBle
        .scanForDevices(
          withServices: [
            // Uuid.parse("0000ffc0-0000-1000-8000-00805f9b34fb"),
           // Uuid.parse("0000ffc0"),
          ],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            if (devices.every((d) => d.id != device.id)) {
              setState(() {
                devices.add(device);
              });
            }
          },
          onError: (error) {
            print("Scan error: $error");
          },
        );
  }

  void handleBleNotReady(BleStatus status) {
    // 🚫 Ignore unknown (initial state)
    if (status == BleStatus.unknown) return;

    String msg;

    if (status == BleStatus.poweredOff) {
      msg = "Please turn ON Bluetooth";
    } else if (status == BleStatus.locationServicesDisabled) {
      msg = "Please turn ON Location";
    } else {
      msg = "Bluetooth not ready";
    }

    setState(() {
      message = msg;
    });

    // 🚫 Prevent multiple dialogs
    if (isDialogShowing) return;

    isDialogShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //====================================================
                  // ICON
                  //====================================================
                  Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == BleStatus.poweredOff
                          ? Icons.bluetooth_disabled_rounded
                          : Icons.location_off_rounded,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    "Action Required",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            isDialogShowing = false;

                            if (status == BleStatus.poweredOff) {
                              AppSettings.openAppSettings(
                                type: AppSettingsType.bluetooth,
                              );
                            } else if (status ==
                                BleStatus.locationServicesDisabled) {
                              AppSettings.openAppSettings(
                                type: AppSettingsType.location,
                              );
                            }
                          },
                          child: const Text("Open Settings"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // ================= CONNECT DEVICE ===================
 // bool isConnecting = false;

  Future<void> connectToDevice(DiscoveredDevice device) async {
    bool retried = false;

    Future<void> connect() async {
      connection = flutterReactiveBle
          .connectToDevice(
            id: device.id,
            connectionTimeout: const Duration(seconds: 10),
          )
          .listen(
            (update) async {
              print("State: ${update.connectionState}");

              if (update.connectionState == DeviceConnectionState.connected) {
                print("✅ Connected");
                await discoverServices(device.id);
                await showServicesDialog(context, device.id);
                await readPlantName(device.id);
                await startBatteryNotification(device.id);
              }

              if (update.connectionState ==
                      DeviceConnectionState.disconnected &&
                  !retried) {
                retried = true;

                print("🔄 First attempt failed. Retrying in 500ms...");

                await connection?.cancel();
                await Future.delayed(const Duration(milliseconds: 500));

                await connect();
              }
            },
            onError: (e) {
              print("Error: $e");
            },
          );
    }

    await connect();
  }

  Future<void> discoverServices(String deviceId) async {
    print("🔍 Discovering services...");

    final services = await flutterReactiveBle.discoverServices(deviceId);

    for (var service in services) {
      print("🗂 Service: ${service.serviceId}");

      for (var char in service.characteristics) {
        print("   📄 Characteristic: ${char.characteristicId}");
      }
    }
  }

  Future<List<DiscoveredService>> discoverServicesUi(String deviceId) async {
    try {
      final services = await flutterReactiveBle.discoverServices(deviceId);
      return services;
    } catch (e) {
      debugPrint("Error discovering services: $e");
      return [];
    }
  }

  Future<void> disconnectDevice() async {
    await connection?.cancel();
    await batterySubscription?.cancel();
    await scanSub?.cancel();

    setState(() {
      isConnected = false;
      connectedDeviceId = null;
    });

    print("🔌 Disconnected manually");
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    bleStatusSub?.cancel();
    scanSub?.cancel();
    connection?.cancel();
    batterySubscription?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Scanner"),
        actions: [
          IconButton(
            onPressed: () {
              disconnectDevice();
            },
            icon: Icon(Icons.bluetooth_disabled),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Status message
          Text(message, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 10),

          if (!isReady)
            const Text(
              "Turn ON Bluetooth & Location",
              style: TextStyle(color: Colors.red),
            ),

          const Divider(),

          // Device List
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text("No devices found"))
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        title: Text(
                          device.name.isNotEmpty
                              ? device.name
                              : "Unknown Device",
                        ),
                        subtitle: Text(device.id),
                        trailing: const Icon(Icons.bluetooth),
                        onTap: () {
                          print("Tapped: ${device.name}");
                          connectToDevice(device);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isReady) {
            startScan();
          }
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Future<void> showServicesDialog(BuildContext context, String deviceId) async {
    final services = await discoverServicesUi(deviceId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("BLE Services"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, serviceIndex) {
                final service = services[serviceIndex];

                return ExpansionTile(
                  title: Text(
                    service.serviceId.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // children: service.characteristics.map((characteristic) {
                  //   // return ListTile(
                  //   //   leading: const Icon(Icons.memory),
                  //   //   title: Text(characteristic.characteristicId.toString()),
                  //   // );
                  //   return ListTile(
                  //     title: Text(characteristic.characteristicId.toString()),
                  //     subtitle: Text(
                  //       "Read: ${characteristic.isReadable}\n"
                  //           "Write: ${characteristic.isWritableWithResponse || characteristic.isWritableWithoutResponse}\n"
                  //           "Notify: ${characteristic.isNotifiable}",
                  //     ),
                  //   );
                  // }).toList(),
                  children: service.characteristics.map((characteristic) {
                    final uuid = characteristic.characteristicId
                        .toString()
                        .toUpperCase();

                    String? value;

                    // Battery Characteristic
                    if (uuid.contains("FFD1")) {
                      value = "Left: $leftBattery%   Right: $rightBattery%";
                    }

                    return ListTile(
                      leading: const Icon(Icons.memory),
                      title: Text(characteristic.characteristicId.toString()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Read: ${characteristic.isReadable}\n"
                            "Write: ${characteristic.isWritableWithResponse || characteristic.isWritableWithoutResponse}\n"
                            "Notify: ${characteristic.isNotifiable}",
                          ),

                          if (value != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> readPlantName(String deviceId) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(
        // "0000FFC1-0000-1000-8000-00805F9B34FB",
        "0000ffc0-0000-1000-8000-00805f9b34fb",
      ),
      characteristicId: Uuid.parse(
        // "0000FFD1-0000-1000-8000-00805F9B34FB",
        "0000ffc3-0000-1000-8000-00805f9b34fb",
      ),
      deviceId: deviceId,
    );

    final value = await flutterReactiveBle.readCharacteristic(characteristic);
    print(value.toList());
    final plantName = utf8.decode(value);

    print("🌱 Plant Name: $plantName");
  }

  Future<void> startBatteryNotification(String deviceId) async {
    final batteryCharacteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("0000ffc0-0000-1000-8000-00805f9b34fb"),
      characteristicId: Uuid.parse("0000ffc3-0000-1000-8000-00805f9b34fb"),
      deviceId: deviceId,
    );

    batterySubscription = flutterReactiveBle
        .subscribeToCharacteristic(batteryCharacteristic)
        .listen(
          (value) {
            // print("Raw Bytes : $value");
            //
            // final text = utf8.decode(value);
            //
            // print("Battery Notify : $text");
            print("Raw Battery Data: $value");

            if (value.length >= 2) {
              setState(() {
                leftBattery = value[0];
                rightBattery = value[1];
              });

              print("Left Battery : $leftBattery%");
              print("Right Battery: $rightBattery%");
            }
          },
          onError: (e) {
            print("Notify Error : $e");
          },
        );
  }
}
