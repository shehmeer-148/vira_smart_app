import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Client_Screens/configuration_screen.dart';
import 'package:vira_planter_app/Presentation/Screens/plant_selection_screen.dart';

import '../../Core/app_colors.dart';
import '../../Util/app_snackbar.dart';
import '../../Core/enums.dart';
import '../Providers/ble_provider.dart';
import '../Widgets/pairing&scanning_widgets.dart';
import '../../Util/helper_dialogs.dart';

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  late BleProvider bleProvider;
  BleStatus? previousStatus;
  BleConnectionState? previousConnectionState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bleProvider = context.read<BleProvider>();
      await bleProvider.initializePairing();
    });
  }

  @override
  void dispose() {
    bleProvider.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BleProvider>();

    // --- BLE Status Monitoring ---
    if (provider.bleStatus != previousStatus) {
      previousStatus = provider.bleStatus;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (provider.bleStatus != BleStatus.ready &&
            provider.bleStatus != BleStatus.unknown) {
          handleBleNotReady(provider.bleStatus, context);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Neutral background
      appBar: AppBar(
        automaticallyImplyLeading: true,
        // Allows going back to test onboarding
        title: const Text(
          "Pairing Verification",
          style: TextStyle(
              color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueGrey[50],
        // Neutral app bar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified Instruction Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hardware Test Instructions:",
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                        "1. Long press (3s) the Vira pot button to enter pairing mode."),
                    Text("2. Keep your phone close to the hardware module."),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Discovered Devices:",
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Device List Area
            Expanded(
              child: Consumer<BleProvider>(
                builder: (_, ble, __) {
                  if (ble.isScanning && ble.devices.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blueGrey),
                          SizedBox(height: 16),
                          Text("Scanning for BLE advertisements..."),
                        ],
                      ),
                    );
                  }

                  if (ble.devices.isEmpty) {
                    return Center(
                      child: Text(
                        "No VIRA Pots Found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    );
                  }

                  // 1. Create a copy and reverse it to get "newest first" base order
                  final displayDevices = ble.devices.reversed.toList();

                  // 2. Sort: Named devices first, Unknown devices last
                  // Dart's sort is stable, so newest-first order is preserved within groups
                  displayDevices.sort((a, b) {
                    final aHasName = a.name.trim().isNotEmpty;
                    final bHasName = b.name.trim().isNotEmpty;

                    if (aHasName && !bHasName) return -1; // a comes before b
                    if (!aHasName && bHasName) return 1;  // b comes before a
                    return 0; // maintain relative order
                  });

                  return RefreshIndicator(
                    color: Colors.blueGrey,
                    onRefresh: () async {
                      return await bleProvider.initializePairing();
                    },
                    child: ListView.builder(
                      itemCount: displayDevices.length,
                      itemBuilder: (_, index) {
                        final device = displayDevices[index];
                        final isSelected = ble.selectedDevice?.id == device.id;
                        final isUnknown = device.name.trim().isEmpty;

                        return Card(
                          elevation: 0,
                          color: isSelected ? Colors.blueGrey[50] : Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isSelected ? Colors.blueGrey[700]! : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(
                              isUnknown ? Icons.bluetooth_disabled : Icons.bluetooth,
                              color: isSelected ? Colors.blueGrey[700] : Colors.grey[500],
                            ),
                            title: Text(
                              isUnknown ? "Unknown Device" : device.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isUnknown ? Colors.grey[600] : Colors.black87,
                              ),
                            ),
                            subtitle: Text("ID: ${device.id}\nStatus: Ready to Pair"),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blueGrey[700])
                                : const Icon(Icons.circle_outlined),
                            onTap: () {
                              ble.selectDevice(device);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),

            // Simplified Connection Action Button
            Consumer<BleProvider>(
              builder: (_, ble, __) {
                return FilledButton(

                  onPressed: ble.selectedDevice == null || ble.isConnecting
                      ? null
                      : () async {
                    // 1. Trigger connection
                    final connected = await ble.connect();

                    if (!mounted) return;

                    // 2. Double-check state (handles edge-case timing)
                    if (connected || ble.isConnected) {
                      print("🚀 [UI] Connection Verified. Syncing RTC...");

                      try {
                        await ble.syncRtcNow();
                      } catch (e) {
                        print("⚠️ [UI] RTC Sync failed: $e");
                      }

                      // 3. Move to Config
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientConfigurationScreen(),
                        ),
                      );
                    } else {
                      AppSnackbar.error(
                          context,
                          "Connection failed. Please ensure the pot is in pairing mode and try again."
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    disabledBackgroundColor: Colors.grey[300],
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: ble.isConnecting
                      ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text("Connecting to Module..."),
                    ],
                  )
                      : Text(
                    ble.selectedDevice == null
                        ? "Select a Device"
                        : "Connect to ${ble.selectedDevice!.name}",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}