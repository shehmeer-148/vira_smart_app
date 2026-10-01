
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/dashboard_screen.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Util/helper_dialogs.dart';
import '../../temp_screen.dart';
import '../Providers/ble_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';

import '../../Core/app_colors.dart';
import '../../Util/helper_dialogs.dart';
import '../Providers/ble_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';

import '../../Core/app_colors.dart';
import '../../Util/helper_dialogs.dart';
import '../Providers/ble_provider.dart';

// class OnboardingPage extends StatefulWidget {
//   const OnboardingPage({super.key});
//
//   @override
//   State<OnboardingPage> createState() => _OnboardingPageState();
// }
//
// class _OnboardingPageState extends State<OnboardingPage> {
//   BleStatus? previousStatus;
//
//   // Simplified Test Dialog
//   void _showTestBleDialog(BuildContext context, BleStatus status) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("BLE Status Alert"),
//         content: Text("Current Bluetooth State: ${status.toString().split('.').last}.\n\nPlease ensure Bluetooth and Location are enabled."),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<BleProvider>();
//
//     // --- BLE Status Monitoring ---
//     if (provider.bleStatus != previousStatus) {
//       previousStatus = provider.bleStatus;
//
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//
//         // Trigger the test dialog if BLE is not ready
//         if (provider.bleStatus != BleStatus.ready &&
//             provider.bleStatus != BleStatus.unknown) {
//           _showTestBleDialog(context, provider.bleStatus);
//         }
//       });
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Vira Test Onboarding"),
//         backgroundColor: AppColors.background,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "App Logic Test Mode",
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//
//             // BLE Status Card
//             Card(
//               elevation: 2,
//               child: ListTile(
//                 leading: Icon(
//                   provider.bleStatus == BleStatus.ready
//                       ? Icons.bluetooth_connected
//                       : Icons.bluetooth_disabled,
//                   color: provider.bleStatus == BleStatus.ready ? Colors.green : Colors.red,
//                 ),
//                 title: const Text("BLE Status"),
//                 subtitle: Text(provider.bleStatus.toString()),
//               ),
//             ),
//
//             const SizedBox(height: 20),
//             const Text(
//               "Description: This is a simplified version of the onboarding screen to test BLE connectivity and navigation logic.",
//             ),
//
//             const Spacer(),
//
//             // Navigation Button
//             Column(
//               children: [
//                 // Primary Test Action: Go to Pairing
//                 FilledButton.icon(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const DevicePairingScreen(),
//                       ),
//                     );
//                   },
//                   style: FilledButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     minimumSize: const Size.fromHeight(50), // Full width, comfortable height
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
//                   label: const Text(
//                     "Test Pairing Flow",
//                     style: TextStyle(color: Colors.white, fontSize: 16),
//                   ),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 // Secondary Test Action: Skip straight to Dashboard
//                 OutlinedButton.icon(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const DashboardScreen(),
//                       ),
//                     );
//                   },
//                   style: OutlinedButton.styleFrom(
//                     minimumSize: const Size.fromHeight(50),
//                     side: const BorderSide(color: AppColors.primary),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.dashboard, color: AppColors.primary),
//                   label: const Text(
//                     "Skip to Dashboard",
//                     style: TextStyle(color: AppColors.primary, fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/dashboard_screen.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';

import '../Providers/ble_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  BleStatus? previousStatus;

  // Simplified Test Dialog for the "Test Phase"
  void _showTestBleDialog(BuildContext context, BleStatus status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("BLE Status Alert"),
        content: Text("Current Bluetooth State: ${status.toString().split('.').last}.\n\nPlease ensure Bluetooth and Location are enabled."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BleProvider>();

    // --- BLE Status Monitoring Logic ---
    if (provider.bleStatus != previousStatus) {
      previousStatus = provider.bleStatus;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (provider.bleStatus != BleStatus.ready &&
            provider.bleStatus != BleStatus.unknown) {
          _showTestBleDialog(context, provider.bleStatus);
        }
      });
    }

    return Scaffold(
      // Basic neutral background
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Vira Test Mode"),
        // Basic grey App Bar instead of Green
        backgroundColor: Colors.blueGrey[50],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Logic Verification",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // BLE Status Card - Visual feedback for testing
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  provider.bleStatus == BleStatus.ready
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: provider.bleStatus == BleStatus.ready ? Colors.green : Colors.red,
                ),
                title: const Text("BLE Status"),
                subtitle: Text(provider.bleStatus.toString()),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "This page is currently in 'Basic Mode' to test core functionality without UI distractions.",
              style: TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            // Updated Button UI with Neutral Theme
            Column(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevicePairingScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    // Using BlueGrey for a basic "Test" look
                    backgroundColor: Colors.blueGrey[800],
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text("Test Pairing Flow"),
                ),


              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
