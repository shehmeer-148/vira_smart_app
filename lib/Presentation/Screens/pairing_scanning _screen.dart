import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text("Add a Pot"),
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            pairingCard(
              context: context,
              image: "images/scan.png",
              title: "Hold long press (3s) on your Vira pot button",
              subtitle:
                  "The pot will enter pairing mode.\nKeep your phone close.",
            ),

            const SizedBox(height: 24),

            Expanded(
              child: Consumer<BleProvider>(
                builder: (_, ble, __) {
                  if (ble.isScanning && ble.devices.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (ble.devices.isEmpty) {
                    return const Center(child: Text("No VIRA Pots Found"));
                  }

                  return RefreshIndicator(
                    onRefresh: (){
                      return bleProvider.initialize();
                    },
                    child: ListView.builder(
                      itemCount: ble.devices.length,
                      itemBuilder: (_, index) {
                        final device = ble.devices[index];

                        return deviceTile(
                          context: context,

                          name: device.name.isEmpty
                              ? "Unknown Device"
                              : device.name,

                          status: "Ready to Pair",

                          selected: ble.selectedDevice?.id == device.id,

                          onTap: () {
                            ble.selectDevice(device);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            Consumer<BleProvider>(
              builder: (_, ble, __) {
                return ElevatedButton(
                  onPressed: ble.selectedDevice == null
                      ? null
                      : () async {
                          print("====================================");
                          print("🟢 Connect Button Pressed");
                          print("Selected Device: ${ble.selectedDevice!.name}");
                          print("Device ID: ${ble.selectedDevice!.id}");
                          print("Current State: ${ble.connectionState}");
                          print("====================================");

                          final connected = await ble.connect();

                          if (!mounted) return;

                          if (connected) {

                             await ble.syncRtcNow();

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChoosePlantScreen(),
                              ),
                            );

                          } else {

                            AppSnackbar.error(
                                context,
                                "Unable to connect to your VIRA Pot. Please try again \nKeep the pot within 1–2 meters"
                            );

                          }

                        },

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
                            Text("Connecting..."),
                          ],
                        )
                      : Text(
                          ble.selectedDevice == null
                              ? "Select a Pot"
                              : "Connect to ${ble.selectedDevice!.name}",
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
