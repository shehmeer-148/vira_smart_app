import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:vira_planter_app/smp_test.dart';

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

  ///////////////////DFU SMP Variables////////////////////
  static final Uuid smpServiceUuid =
  Uuid.parse("8d53dc1d-1db7-4cd3-868b-8a527460aa84");

  static final Uuid smpCharacteristicUuid =
  Uuid.parse("da2e7828-fbce-4e01-ae9e-261174997c48");

  StreamSubscription<List<int>>? smpNotifySubscription;

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

          //   final mtu = await flutterReactiveBle.requestMtu(
          //     deviceId: device.id,
          //     mtu: 247,
          //   );
          //
          //   print('📏 BLE MTU: $mtu');
          //   print('📦 Maximum ATT payload: ${mtu - 3}');
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

    final services =
    await flutterReactiveBle.discoverServices(deviceId);

    for (final service in services) {
      print("🗂 Service: ${service.serviceId}");

      for (final char in service.characteristics) {
        print("   📄 Characteristic: ${char.characteristicId}");
        print("      Read: ${char.isReadable}");
        print(
          "      Write: "
              "${char.isWritableWithResponse || char.isWritableWithoutResponse}",
        );
        print("      Notify: ${char.isNotifiable}");

        // ================= SMP =================

        if (service.serviceId == smpServiceUuid &&
            char.characteristicId == smpCharacteristicUuid) {
          print("");
          print("==========================================");
          print("🚀 SMP CHARACTERISTIC FOUND");
          print("==========================================");
          print("Service : ${service.serviceId}");
          print("Char    : ${char.characteristicId}");
          print("Notify  : ${char.isNotifiable}");
          print(
            "Write   : "
                "${char.isWritableWithResponse || char.isWritableWithoutResponse}",
          );
          print(
            'WriteNoResponse : '
                '${char.isWritableWithoutResponse}',
          );
          print("==========================================");

          // await setupSmp(deviceId);
          // await Future.delayed(const Duration(milliseconds: 300));
          //
          // await sendSmpImageStateRequest(deviceId);
          // print("==========================================");
          // print("================Starting the SMP test==========================");
          // final smpTest = SmpTest(
          //   ble: flutterReactiveBle,
          //   deviceId: deviceId,
          // );
          //
          // await smpTest.start();
          // final mtu = await flutterReactiveBle.requestMtu(
          //   deviceId: deviceId,
          //   mtu: 247,
          // );
          //
          // print('📏 BLE MTU: $mtu');
          // print('📦 Maximum ATT payload: ${mtu - 3}');
          await SmpTest(
            ble: flutterReactiveBle,
            deviceId: deviceId,
          ).start();
        }
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
    await scanSub?.cancel();

    setState(() {
      isConnected = false;
      connectedDeviceId = null;
    });

    print("🔌 Disconnected manually");
  }

  Future<void> setupSmp(String deviceId) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: smpServiceUuid,
      characteristicId: smpCharacteristicUuid,
      deviceId: deviceId,
    );

    print("📡 Subscribing to SMP notifications...");

    await smpNotifySubscription?.cancel();

    smpNotifySubscription =
        flutterReactiveBle.subscribeToCharacteristic(characteristic).listen(
              (data) {
            print("📥 SMP NOTIFICATION");
            print("Bytes: $data");
            print(
              "HEX: ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
            );
          },
          onError: (error) {
            print("❌ SMP notification error: $error");
          },
        );

    print("✅ SMP notification subscription created");
  }
  Future<void> sendSmpImageStateRequest(String deviceId) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: smpServiceUuid,
      characteristicId: smpCharacteristicUuid,
      deviceId: deviceId,
    );

    // SMP Image State request
    // final request = <int>[
    //   0x00, 0x00, // Op: Read, Flags: 0
    //   0x00, 0x01, // Length = 1
    //   0x00, 0x06, // Group = Image Management
    //   0x00,       // Sequence = 0
    //   0x00,       // Command = Image State
    // ];
    final request = <int>[
      0x00, 0x00, // Op = Read, Flags = 0
      0x00, 0x00, // Length = 0
      0x00, 0x06, // Group = Image Management
      0x00,       // Sequence = 0
      0x00,       // Command = Image State
    ];

    print("📤 Sending SMP Image State request...");
    print(
      "HEX: ${request.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    try {
      await flutterReactiveBle.writeCharacteristicWithoutResponse(
        characteristic,
        value: request,
      );

      print("✅ SMP Image State request sent");
    } catch (e) {
      print("❌ SMP write failed: $e");
    }
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    bleStatusSub?.cancel();
    scanSub?.cancel();
    connection?.cancel();
    smpNotifySubscription?.cancel();

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
                  onTap: () async{
                    print("Tapped: ${device.name}");
                    connectToDevice(device);
                    // await SmpTest(
                    // ble: flutterReactiveBle,
                    // deviceId: device.id,
                    // ).imageStateTest();
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
                  children: service.characteristics.map((characteristic) {
                    // return ListTile(
                    //   leading: const Icon(Icons.memory),
                    //   title: Text(characteristic.characteristicId.toString()),
                    // );
                    return ListTile(
                      title: Text(characteristic.characteristicId.toString()),
                      subtitle: Text(
                        "Read: ${characteristic.isReadable}\n"
                            "Write: ${characteristic.isWritableWithResponse || characteristic.isWritableWithoutResponse}\n"
                            "Notify: ${characteristic.isNotifiable}",
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

}