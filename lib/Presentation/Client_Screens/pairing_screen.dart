// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../Providers/ble_provider.dart';
//
// class PairingScreen extends StatelessWidget {
//   const PairingScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8F7),
//       appBar: AppBar(
//         title: const Text(
//           'Pair Device',
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Connect your Vira Planter',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//
//               const SizedBox(height: 6),
//
//               Text(
//                 'Make sure your planter is nearby and Bluetooth is enabled.',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                   height: 1.4,
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               _scanCard(context),
//
//               const SizedBox(height: 28),
//
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Available Devices',
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//
//                   Consumer<BleProvider>(
//                     builder: (context, provider, _) {
//                       return Text(
//                         '${provider.devices.length} found',
//                         style: TextStyle(
//                           fontSize: 13,
//                           color: Colors.grey.shade600,
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 12),
//
//               Expanded(
//                 child: Consumer<BleProvider>(
//                   builder: (context, provider, _) {
//                     if (provider.devices.isEmpty) {
//                       return _emptyDevices();
//                     }
//
//                     return ListView.separated(
//                       itemCount: provider.devices.length,
//                       separatorBuilder: (_, __) =>
//                       const SizedBox(height: 10),
//                       itemBuilder: (context, index) {
//                         final device = provider.devices[index];
//
//                         return _deviceCard(
//                           context,
//                           device,
//                           provider,
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _scanCard(BuildContext context) {
//     return Consumer<BleProvider>(
//       builder: (context, provider, _) {
//         final isScanning = provider.connectionState ==
//             ConnectionStateEnum.scanning;
//
//         return Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Colors.grey.shade200,
//             ),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.10),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.bluetooth_searching,
//                   size: 30,
//                   color: Colors.green,
//                 ),
//               ),
//
//               const SizedBox(height: 14),
//
//               Text(
//                 isScanning
//                     ? 'Searching for devices...'
//                     : 'Find your planter',
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               const SizedBox(height: 6),
//
//               Text(
//                 isScanning
//                     ? 'Looking for nearby Vira devices'
//                     : 'Search for nearby Vira Planters',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//
//               const SizedBox(height: 18),
//
//               SizedBox(
//                 width: double.infinity,
//                 height: 48,
//                 child: ElevatedButton.icon(
//                   onPressed: isScanning
//                       ? null
//                       : provider.startScan,
//                   icon: Icon(
//                     isScanning
//                         ? Icons.sync
//                         : Icons.bluetooth_searching,
//                   ),
//                   label: Text(
//                     isScanning
//                         ? 'Scanning...'
//                         : 'Scan for Devices',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _deviceCard(
//       BuildContext context,
//       BleDevice device,
//       BleProvider provider,
//       ) {
//     final isConnecting =
//         provider.connectingPotId == device.id;
//
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.grey.shade200,
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 46,
//             height: 46,
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.10),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(
//               Icons.local_florist,
//               color: Colors.green,
//             ),
//           ),
//
//           const SizedBox(width: 12),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   device.name.isEmpty
//                       ? 'Unknown Device'
//                       : device.name,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//
//                 const SizedBox(height: 4),
//
//                 Text(
//                   device.id,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: Colors.grey.shade600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(width: 8),
//
//           SizedBox(
//             height: 38,
//             child: ElevatedButton(
//               onPressed: isConnecting
//                   ? null
//                   : () async {
//                 // Connect using your existing BLE method.
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 foregroundColor: Colors.white,
//                 elevation: 0,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(9),
//                 ),
//               ),
//               child: Text(
//                 isConnecting ? 'Connecting...' : 'Connect',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _emptyDevices() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.bluetooth_disabled,
//             size: 42,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No devices found',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Tap "Scan for Devices" to search again.',
//             style: TextStyle(
//               fontSize: 13,
//               color: Colors.grey.shade500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }