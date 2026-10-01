import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Providers/ble_provider.dart';

import '../../Core/app_colors.dart';
import '../../Data/Model_classes/pot_model.dart';

class ClientConfigurationScreen extends StatefulWidget {
  const ClientConfigurationScreen({
    super.key,
  });

  @override
  State<ClientConfigurationScreen> createState() =>
      _ClientConfigurationScreenState();
}

// class _ClientConfigurationScreenState extends State<ClientConfigurationScreen> {
//
//   final TextEditingController plantNameController = TextEditingController();
//
//   TimeOfDay? selectedTime;
//   int? selectedPlantType;
//   int? selectedWaterDuration;
//   int? timeMinutes;
//   int _daysMask = 0;
//
//   @override
//   void dispose() {
//     plantNameController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50], // Neutral background
//       appBar: AppBar(
//         title: const Text(
//           'Configuration Test',
//           style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: Colors.blueGrey[50],
//         foregroundColor: Colors.black87,
//         elevation: 0,
//         actions: [
//           TextButton.icon(
//             onPressed: () => /* TODO: Start DFU */ {},
//             icon: const Icon(Icons.system_update, size: 18),
//             label: const Text('DFU'),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader("Device Information"),
//             _buildInfoCard(),
//
//             const SizedBox(height: 24),
//
//             _buildSectionHeader("Configuration Settings"),
//             _buildConfigCard(),
//
//             const SizedBox(height: 24),
//
//             _buildSectionHeader("Live Status (Read Only)"),
//             _buildStatusCard(),
//
//             const SizedBox(height: 32),
//
//             // Action Buttons
//             Column(
//               children: [
//                 FilledButton.icon(
//                   onPressed: () {
//                     // TODO: Write configuration logic
//                   },
//                   style: FilledButton.styleFrom(
//                     backgroundColor: Colors.blueGrey[800],
//                     minimumSize: const Size.fromHeight(50),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   icon: const Icon(Icons.save),
//                   label: const Text("Write Configuration"),
//                 ),
//                 const SizedBox(height: 12),
//                 Consumer<BleProvider>(builder: (context, provider, child){
//                   return  OutlinedButton.icon(
//                     onPressed: (){
//                       provider.readConfiguration();
//                     }, // Disabled until first write as per your logic
//                     style: OutlinedButton.styleFrom(
//                       minimumSize: const Size.fromHeight(50),
//                       side: BorderSide(color: Colors.blueGrey[800]!),
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                     ),
//                     icon: const Icon(Icons.refresh),
//                     label: const Text("Read Configuration"),
//                   );
//                 })
//               ],
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 4, bottom: 8),
//       child: Text(
//         title.toUpperCase(),
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//           color: Colors.blueGrey[700],
//           letterSpacing: 1.1,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoCard() {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _infoRow('Device Name', 'VIRA-A3F2C1'),
//             const Divider(),
//             _infoRow('Device ID', 'xxxxxxxxxxxxxxxx'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildConfigCard() {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text("Plant Identity", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             TextField(
//               controller: plantNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Plant Name',
//                 border: OutlineInputBorder(),
//                 isDense: true,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//
//             DropdownButtonFormField<int>(
//               value: selectedPlantType,
//               hint: const Text('Select plant type'),
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               items: const [
//                 DropdownMenuItem(
//                   value: 1,
//                   child: Text('Flower'),
//                 ),
//                 DropdownMenuItem(
//                   value: 2,
//                   child: Text('Herb'),
//                 ),
//                 DropdownMenuItem(
//                   value: 3,
//                   child: Text('Vegetable'),
//                 ),
//                 DropdownMenuItem(
//                   value: 4,
//                   child: Text('Indoor Plant'),
//                 ),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   selectedPlantType = value;
//                 });
//               },
//             ),
//
//             const SizedBox(height: 6),
//
//             Text(
//               'Plant Type: ${selectedPlantType ?? 'Not selected'}',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 24),
//             const Text("Schedule Logic", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             Wrap(
//               spacing: 8,
//               children: [
//                 _dayButton('M', 1), _dayButton('T', 2), _dayButton('W', 4),
//                 _dayButton('T', 8), _dayButton('F', 16), _dayButton('S', 32), _dayButton('S', 64),
//               ],
//             ),
//             Text("Days Mask: $_daysMask", style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blueGrey)),
//             const SizedBox(height: 16),
//             ListTile(
//               contentPadding: EdgeInsets.zero,
//               title: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
//               subtitle: Text("Time Minutes: ${timeMinutes ?? 0}"),
//               trailing: const Icon(Icons.access_time),
//               onTap: _selectTime,
//             ),
//             const Divider(),
//             const SizedBox(height: 8),
//             // RESTORED: Water Duration Widget
//             const SizedBox(height: 12),
//             DropdownButtonFormField<int>(
//               value: selectedWaterDuration,
//               hint: const Text("Select Water Duration"),
//               decoration: const InputDecoration(
//                 labelText: 'Water Duration (Seconds)',
//                 border: OutlineInputBorder(),
//                 isDense: true,
//               ),
//               items: [5, 10, 15, 30, 45, 60].map((int value) {
//                 return DropdownMenuItem<int>(
//                   value: value,
//                   child: Text('$value Seconds'),
//                 );
//               }).toList(),
//               onChanged: (v) => setState(() => selectedWaterDuration = v),
//             ),
//             // Displaying the raw value for testing
//             Text(
//               "Duration Seconds: ${selectedWaterDuration ?? 0}",
//               style: const TextStyle(
//                 fontFamily: 'monospace',
//                 fontSize: 12,
//                 color: Colors.blueGrey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusCard() {
//     return Card(
//       elevation: 0,
//       color: Colors.white,
//       shape: RoundedRectangleBorder(
//         side: BorderSide(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         children: [
//           _statusRow('Battery', '85%', Icons.battery_std),
//           _statusRow('Tank', 'Normal', Icons.water_damage),
//           _statusRow('Cycles', '24', Icons.loop),
//           _statusRow('Firmware', '1.0.0', Icons.code),
//         ],
//       ),
//     );
//   }
//
//   Widget _infoRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
//           Text(value, style: const TextStyle(fontFamily: 'monospace')),
//         ],
//       ),
//     );
//   }
//
//   Widget _statusRow(String title, String value, IconData icon) {
//     return ListTile(
//       leading: Icon(icon, size: 20, color: Colors.blueGrey),
//       title: Text(title, style: const TextStyle(fontSize: 14)),
//       trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
//       dense: true,
//     );
//   }
//
//   Widget _dayButton(String day, int value) {
//     final isSelected = (_daysMask & value) != 0;
//     return ChoiceChip(
//       label: Text(day),
//       selected: isSelected,
//       selectedColor: Colors.blueGrey[200],
//       onSelected: (selected) {
//         setState(() {
//           if (selected) _daysMask |= value;
//           else _daysMask &= ~value;
//         });
//       },
//     );
//   }
//
//   Future<void> _selectTime() async {
//     final time = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
//     if (time != null) {
//       setState(() {
//         selectedTime = time;
//         timeMinutes = time.hour * 60 + time.minute;
//       });
//     }
//   }
//
//
//   ///////////////////////////////
//
// }
class _ClientConfigurationScreenState extends State<ClientConfigurationScreen> {
  final TextEditingController plantNameController = TextEditingController();

  late BleProvider _bleProvider;

  TimeOfDay? selectedTime;
  int? selectedPlantType;
  int? selectedWaterDuration;
  int? timeMinutes;
  int _daysMask = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bleProvider = Provider.of<BleProvider>(context, listen: false);
  }

  @override
  void dispose() {
    plantNameController.dispose();
    _bleProvider.disconnect();
    super.dispose();
  }

  // Helper to sync local UI state with what was just read from the BLE device
  void _syncLocalStateWithProvider(BleProvider provider) {
    setState(() {
      plantNameController.text = provider.plantName ?? '';
      selectedPlantType = provider.plantType;
      selectedWaterDuration = provider.waterDuration;
      _daysMask = provider.daysMask ?? 0;
      timeMinutes = provider.timeMinutes;

      if (provider.timeMinutes != null) {
        selectedTime = TimeOfDay(
          hour: provider.timeMinutes! ~/ 60,
          minute: provider.timeMinutes! % 60,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for live status updates
    final provider = context.watch<BleProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // appBar: AppBar(
      //   title: const Text(
      //     'Configuration Test',
      //     style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
      //   ),
      //   backgroundColor: Colors.blueGrey[50],
      //   foregroundColor: Colors.black87,
      //   elevation: 0,
      //   actions: [
      //     TextButton.icon(
      //       onPressed: provider.isDfuUpdating ? null : () {
      //         // TODO: Trigger DFU logic in provider
      //
      //       },
      //       icon: provider.isDfuUpdating
      //           ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
      //           : const Icon(Icons.system_update, size: 18),
      //       label: Text(provider.isDfuUpdating ? 'Updating...' : 'DFU'),
      //     ),
      //   ],
      // ),
      appBar: AppBar(
        title: const Text("BLE Scanner"),
        actions: [
          // Show the Update button only if connected

            Consumer<BleProvider>(
              builder: (context, provider, child) {
                return // Inside your AppBar actions
                  IconButton(
                    onPressed: provider.isUpdating
                        ? null
                        : () async {
                      // 1. Show the progress dialog
                      _showUpdateProgressDialog(context);

                      try {
                        // 2. Start the update
                        await provider.startFirmwareUpdate();

                        // 3. Close dialog on success
                        if (context.mounted) Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Update Completed Successfully")),
                        );
                      } catch (e) {
                        // 4. Close dialog on failure
                        if (context.mounted) Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Update Failed: $e"), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.system_update_alt_rounded),
                  );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Device Information"),
            _buildInfoCard(provider),

            const SizedBox(height: 24),

            _buildSectionHeader("Configuration Settings"),
            _buildConfigCard(),

            const SizedBox(height: 24),

            _buildSectionHeader("Live Status (Read Only)"),
            _buildStatusCard(provider),

            const SizedBox(height: 32),

            // Action Buttons
            // Action Buttons
            Column(
              children: [
                // WRITE BUTTON
                // WRITE BUTTON
                FilledButton.icon(
                  onPressed: provider.isReadingConfiguration ? null : () async {
                    if (provider.connectedDevice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Device Disconnected: Please reconnect to write configuration."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final success = await provider.writeConfiguration(
                      plantType: selectedPlantType ?? 0,
                      plantName: plantNameController.text,
                      daysMask: _daysMask,
                      timeMinutes: timeMinutes ?? 0,
                      wateringsPerDay: 1,
                      waterDuration: selectedWaterDuration ?? 5,
                    );

                    if (success && mounted) {
                      // --- RESET LOCAL UI STATE HERE ---
                      _resetLocalState();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Configuration Written & Local UI Reset. Click 'Read' to verify."),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text("Write Configuration"),
                ),

                const SizedBox(height: 12),

                // READ BUTTON
                OutlinedButton.icon(
                  onPressed: provider.isReadingConfiguration ? null : () async {
                    // 1. Check Connection Status
                    if (provider.connectedDevice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Device Disconnected: Please reconnect to read configuration."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    final success = await provider.readConfiguration();
                    if (success && mounted) {
                      _syncLocalStateWithProvider(provider);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: BorderSide(color: Colors.blueGrey[800]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: provider.isReadingConfiguration
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text(provider.isReadingConfiguration ? "Reading..." : "Read Configuration"),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BleProvider provider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Using real ID from provider if available
            _infoRow('Device Name', provider.connectedDevice?.name ?? 'VIRA Pot'),
            const Divider(),
            _infoRow('Device ID', provider.connectedDevice?.id ?? '00:00:00:00:00:00'),
            const Divider(),
            _infoRow('Firmware', provider.firmwareVersion),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BleProvider provider) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _statusRow(
            'Battery',
            '${provider.batteryLevel}%',
            provider.lowBattery ? Icons.battery_alert : Icons.battery_std,
            color: provider.lowBattery ? Colors.red : null,
          ),
          _statusRow(
            'Tank Status',
            provider.tankStatus == 1 ? 'Normal' : 'Low',
            Icons.water_damage,
            color: provider.tankStatus == 1 ? null : Colors.red,
          ),
          _statusRow(
              'Last Watered',
              provider.lastWatered == 0 ? 'Never' : '${provider.lastWatered} min ago',
              Icons.history
          ),
          _statusRow('Cycles', '${provider.cycleCount}', Icons.loop),
        ],
      ),
    );
  }

  // ... Keep _buildConfigCard, _dayButton, _selectTime, _infoRow as they were ...
  // Ensure _buildConfigCard uses the local variables (selectedPlantType, etc.)
  // so the user can edit them before hitting "Write".
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[700],
          letterSpacing: 1.1,
        ),
      ),
    );
  }


  Widget _buildConfigCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Plant Identity", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: plantNameController,
              decoration: const InputDecoration(
                labelText: 'Plant Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),


            DropdownButtonFormField<int>(
              value: selectedPlantType,
              hint: const Text('Select plant type'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Flower'),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text('Herb'),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('Vegetable'),
                ),
                DropdownMenuItem(
                  value: 4,
                  child: Text('Indoor Plant'),
                ),
                DropdownMenuItem(
                  value: 65535,
                  child: Text('Default Plant'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedPlantType = value;
                });
              },
            ),

            const SizedBox(height: 6),

            Text(
              'Plant Type: ${selectedPlantType ?? 'Not selected'}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text("Schedule Logic", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _dayButton('M', 1), _dayButton('T', 2), _dayButton('W', 4),
                _dayButton('T', 8), _dayButton('F', 16), _dayButton('S', 32), _dayButton('S', 64),
              ],
            ),
            Text("Days Mask: $_daysMask", style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(selectedTime == null ? 'Select Time' : selectedTime!.format(context)),
              subtitle: Text("Time Minutes: ${timeMinutes ?? 0}"),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),
            const Divider(),
            const SizedBox(height: 8),
            // RESTORED: Water Duration Widget
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: selectedWaterDuration,
              hint: const Text("Select Water Duration"),
              decoration: const InputDecoration(
                labelText: 'Water Duration (Seconds)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [5, 10, 15, 30, 45, 60].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value Seconds'),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedWaterDuration = v),
            ),
            // Displaying the raw value for testing
            Text(
              "Duration Seconds: ${selectedWaterDuration ?? 0}",
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
  Widget _dayButton(String day, int value) {
    final isSelected = (_daysMask & value) != 0;
    return ChoiceChip(
      label: Text(day),
      selected: isSelected,
      selectedColor: Colors.blueGrey[200],
      onSelected: (selected) {
        setState(() {
          if (selected) _daysMask |= value;
          else _daysMask &= ~value;
        });
      },
    );
  }
  Future<void> _selectTime() async {
    final time = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
    if (time != null) {
      setState(() {
        selectedTime = time;
        timeMinutes = time.hour * 60 + time.minute;
      });
    }
  }
  void _resetLocalState() {
    setState(() {
      plantNameController.clear();
      selectedPlantType = null;
      selectedWaterDuration = null;
      selectedTime = null;
      timeMinutes = null;
      _daysMask = 0;
    });
  }

  Widget _statusRow(String title, String value, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      dense: true,
    );
  }
  void _showUpdateDialogOld(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent closing via back button
          child: AlertDialog(
            title: const Text("Updating Firmware"),
            content: Consumer<BleProvider>(
              builder: (context, provider, child) {
                final percent = (provider.updateProgress * 100).toStringAsFixed(0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Please keep the device close and do not close the app."),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: provider.updateProgress,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blueGrey[800],
                    ),
                    const SizedBox(height: 10),
                    Text("$percent%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
  void _showUpdateProgressDialog(BuildContext context) {
    // Capture the provider before opening the dialog
    final bleProvider = context.read<BleProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Use .value to pass the EXISTING provider instance into the dialog route
        return ChangeNotifierProvider.value(
          value: bleProvider,
          child: PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text("Updating Firmware"),
              content: Consumer<BleProvider>(
                builder: (context, ble, _) {
                  // This will now react to notifyListeners()
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(
                        value: ble.updateProgress,
                        backgroundColor: Colors.grey[200],
                        color: Colors.blueGrey[800],
                      ),
                      const SizedBox(height: 10),
                      Text("${(ble.updateProgress * 100).toStringAsFixed(0)}%"),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }}