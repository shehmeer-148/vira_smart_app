//
// import 'dart:async';
//
// import 'package:app_settings/app_settings.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import '../../Core/app_colors.dart';
// import '../Screens/dashboard_screen.dart';
//
// class OnboardingPage extends StatefulWidget {
//   const OnboardingPage({super.key});
//
//   @override
//   State<OnboardingPage> createState() => _OnboardingPageState();
// }
//
// class _OnboardingPageState extends State<OnboardingPage> {
//   final PageController _pageController = PageController();
//
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//
//   StreamSubscription<BleStatus>? _bleStatusSubscription;
//
//   int _currentPage = 0;
//
//   bool _isBluetoothOn = false;
//   bool _isCheckingBluetooth = true;
//
//   PermissionStatus _locationStatus = PermissionStatus.denied;
//
//   bool _isRequestingLocation = false;
//
//   // ============================================================
//   // INIT
//   // ============================================================
//
//   @override
//   void initState() {
//     super.initState();
//
//     _listenBluetoothStatus();
//     _checkLocationPermission();
//   }
//
//   // ============================================================
//   // DISPOSE
//   // ============================================================
//
//   @override
//   void dispose() {
//     _bleStatusSubscription?.cancel();
//     _pageController.dispose();
//
//     super.dispose();
//   }
//
//   // ============================================================
//   // BLUETOOTH STATUS
//   // ============================================================
//
//   void _listenBluetoothStatus() {
//     _bleStatusSubscription = _ble.statusStream.listen(
//           (status) {
//         if (!mounted) return;
//
//         setState(() {
//           _isBluetoothOn = status == BleStatus.ready;
//           _isCheckingBluetooth = false;
//         });
//       },
//     );
//   }
//
//   // ============================================================
//   // LOCATION STATUS
//   // ============================================================
//
//   Future<void> _checkLocationPermission() async {
//     final status = await Permission.locationWhenInUse.status;
//
//     if (!mounted) return;
//
//     setState(() {
//       _locationStatus = status;
//     });
//   }
//
//   Future<void> _requestLocationPermission() async {
//     if (_isRequestingLocation) return;
//
//     setState(() {
//       _isRequestingLocation = true;
//     });
//
//     try {
//       final status =
//       await Permission.locationWhenInUse.request();
//
//       if (!mounted) return;
//
//       setState(() {
//         _locationStatus = status;
//       });
//
//       if (status.isPermanentlyDenied) {
//         await openAppSettings();
//       }
//     } finally {
//       if (!mounted) return;
//
//       setState(() {
//         _isRequestingLocation = false;
//       });
//     }
//   }
//
//   // ============================================================
//   // BLUETOOTH BUTTON
//   // ============================================================
//
//   Future<void> _turnOnBluetooth() async {
//     await AppSettings.openAppSettings(
//       type: AppSettingsType.bluetooth,
//     );
//   }
//
//   // ============================================================
//   // NAVIGATION
//   // ============================================================
//
//   void _nextPage() {
//     if (_currentPage < 2) {
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 350),
//         curve: Curves.easeOutCubic,
//       );
//     }
//   }
//
//   void _previousPage() {
//     if (_currentPage == 0) return;
//
//     _pageController.previousPage(
//       duration: const Duration(milliseconds: 350),
//       curve: Curves.easeOutCubic,
//     );
//   }
//
//   void _finishOnboarding() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const DashboardScreen(),
//       ),
//     );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//
//             Expanded(
//               child: PageView(
//                 controller: _pageController,
//                 physics: const NeverScrollableScrollPhysics(),
//
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentPage = index;
//                   });
//
//                   if (index == 2) {
//                     _checkLocationPermission();
//                   }
//                 },
//
//                 children: [
//                   _buildWelcomePage(),
//                   _buildBluetoothPage(),
//                   _buildLocationPage(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // TOP BAR
//   // ============================================================
//
//   Widget _buildTopBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 26,
//         vertical: 18,
//       ),
//       child: Row(
//         children: [
//           if (_currentPage > 0)
//             InkWell(
//               onTap: _previousPage,
//               borderRadius: BorderRadius.circular(30),
//               child: const Padding(
//                 padding: EdgeInsets.all(8),
//                 child: Icon(
//                   Icons.arrow_back_ios_new_rounded,
//                   size: 22,
//                   color: Color(0xFF264434),
//                 ),
//               ),
//             )
//           else
//             const SizedBox(width: 38),
//
//           const Spacer(),
//
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 10,
//             ),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(.08),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Text(
//               "${_currentPage + 1} / 3",
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF264434),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // PAGE 1 - WELCOME
//   // ============================================================
//
//   Widget _buildWelcomePage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Column(
//         children: [
//           const Spacer(),
//
//           // VIRPOT IMAGE
//           SizedBox(
//             height: 30,
//             child: Image.asset(
//               "images/onboardingPics/vira a.png",
//               fit: BoxFit.contain,
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           RichText(
//             textAlign: TextAlign.center,
//             text: TextSpan(
//               children: [
//                 const TextSpan(
//                   text: "Welcome to\n",
//                   style: TextStyle(
//                     fontSize: 30,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF264434),
//                   ),
//                 ),
//
//                 TextSpan(
//                   text: "VirPot",
//                   style: TextStyle(
//                     fontSize: 52,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.primary,
//                     height: 1.1,
//                   ),
//                 ),
//
//                 const TextSpan(
//                   text: " 🌿",
//                   style: TextStyle(fontSize: 35),
//                 ),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 18),
//
//           const Text(
//             "Connect your smart pots, monitor\n"
//                 "your plants and keep them healthy\n"
//                 "with ease.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 17,
//               height: 1.5,
//               color: Color(0xFF5E6460),
//             ),
//           ),
//
//           const SizedBox(height: 28),
//
//           // CONNECT / MONITOR / GROW CARD
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 10,
//               vertical: 18,
//             ),
//             decoration: _softCardDecoration(),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _buildFeatureItem(
//                     icon: Icons.photo_filter,
//                     title: "Connect",
//                   ),
//                 ),
//
//                 _buildVerticalDivider(),
//
//                 Expanded(
//                   child: _buildFeatureItem(
//                     icon: Icons.water_drop_rounded,
//                     title: "Monitor",
//                   ),
//                 ),
//
//                 _buildVerticalDivider(),
//
//                 Expanded(
//                   child: _buildFeatureItem(
//                     icon: Icons.bar_chart_rounded,
//                     title: "Grow",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           const Spacer(),
//
//           _buildDots(),
//
//           const SizedBox(height: 28),
//
//           _buildGoldButton(
//             text: "Get Started",
//             icon: Icons.arrow_forward_rounded,
//             onTap: _nextPage,
//           ),
//
//           const SizedBox(height: 28),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // PAGE 2 - BLUETOOTH
//   // ============================================================
//
//   Widget _buildBluetoothPage() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Column(
//         children: [
//           const Spacer(),
//
//           SizedBox(
//             height: 60,
//             child: Image.asset(
//               "images/onboardingPics/vira b.png",
//               fit: BoxFit.contain,
//             ),
//           ),
//
//           const SizedBox(height: 28),
//
//           const Text(
//             "Turn on Bluetooth",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.w800,
//               color: Color(0xFF264434),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           const Text(
//             "Bluetooth allows VirPot to discover\n"
//                 "and communicate with your nearby\n"
//                 "smart pots.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 17,
//               height: 1.5,
//               color: Color(0xFF5E6460),
//             ),
//           ),
//
//           const SizedBox(height: 30),
//
//           _buildStatusCard(
//             icon: Icons.bluetooth_rounded,
//             title: "Bluetooth",
//             enabled: _isBluetoothOn,
//             loading: _isCheckingBluetooth,
//             enabledText: "On",
//             disabledText: "Off",
//           ),
//
//           const SizedBox(height: 28),
//
//           _buildGreenButton(
//             text: _isBluetoothOn
//                 ? "Bluetooth Enabled"
//                 : "Turn On Bluetooth",
//             icon: _isBluetoothOn
//                 ? Icons.check_rounded
//                 : Icons.bluetooth_rounded,
//             onTap: _isBluetoothOn
//                 ? _nextPage
//                 : _turnOnBluetooth,
//           ),
//
//           const SizedBox(height: 16),
//
//           _buildInfoCard(
//             text: _isBluetoothOn
//                 ? "Your Bluetooth is ready to connect."
//                 : "You can change this later from Settings.",
//           ),
//
//           const Spacer(),
//
//           _buildDots(),
//
//           const SizedBox(height: 28),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // PAGE 3 - LOCATION
//   // ============================================================
//
//   Widget _buildLocationPage() {
//     final locationGranted = _locationStatus.isGranted;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       child: Column(
//         children: [
//           const Spacer(),
//
//           SizedBox(
//             height: 260,
//             child: Image.asset(
//               "images/location_onboarding.png",
//               fit: BoxFit.contain,
//             ),
//           ),
//
//           const SizedBox(height: 28),
//
//           const Text(
//             "Allow Location",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.w800,
//               color: Color(0xFF264434),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           const Text(
//             "Location permission is required to find\n"
//                 "and discover nearby Bluetooth\n"
//                 "devices.",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 17,
//               height: 1.5,
//               color: Color(0xFF5E6460),
//             ),
//           ),
//
//           const SizedBox(height: 30),
//
//           _buildStatusCard(
//             icon: Icons.location_on_rounded,
//             title: "Location Permission",
//             enabled: locationGranted,
//             loading: _isRequestingLocation,
//             enabledText: "Granted",
//             disabledText: "Not Granted",
//           ),
//
//           const SizedBox(height: 28),
//
//           _buildGreenButton(
//             text: locationGranted
//                 ? "Get Started"
//                 : "Allow Location",
//             icon: locationGranted
//                 ? Icons.check_rounded
//                 : Icons.location_on_rounded,
//             onTap: _isRequestingLocation
//                 ? null
//                 : locationGranted
//                 ? _finishOnboarding
//                 : _requestLocationPermission,
//           ),
//
//           const SizedBox(height: 16),
//
//           _buildInfoCard(
//             text: "We only use location to find\nnearby devices.",
//           ),
//
//           const Spacer(),
//
//           _buildDots(),
//
//           const SizedBox(height: 28),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // STATUS CARD
//   // ============================================================
//
//   Widget _buildStatusCard({
//     required IconData icon,
//     required String title,
//     required bool enabled,
//     required bool loading,
//     required String enabledText,
//     required String disabledText,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: _softCardDecoration(),
//       child: Row(
//         children: [
//           Container(
//             width: 56,
//             height: 56,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: AppColors.primary.withOpacity(.12),
//             ),
//             child: Icon(
//               icon,
//               color: AppColors.primary,
//               size: 28,
//             ),
//           ),
//
//           const SizedBox(width: 16),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF293A31),
//                   ),
//                 ),
//
//                 const SizedBox(height: 5),
//
//                 const Text(
//                   "Status",
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: Color(0xFF69716C),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           if (loading)
//             const SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2.5,
//               ),
//             )
//           else
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 13,
//                 vertical: 8,
//               ),
//               decoration: BoxDecoration(
//                 color: enabled
//                     ? AppColors.primary.withOpacity(.10)
//                     : Colors.red.withOpacity(.07),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 7,
//                     height: 7,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: enabled
//                           ? AppColors.primary
//                           : Colors.red,
//                     ),
//                   ),
//
//                   const SizedBox(width: 7),
//
//                   Text(
//                     enabled
//                         ? enabledText
//                         : disabledText,
//                     style: TextStyle(
//                       color: enabled
//                           ? AppColors.primary
//                           : Colors.red.shade700,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // GREEN BUTTON
//   // ============================================================
//
//   Widget _buildGreenButton({
//     required String text,
//     required IconData icon,
//     required VoidCallback? onTap,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 62,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           elevation: 5,
//           shadowColor: AppColors.primary.withOpacity(.30),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon),
//
//             const SizedBox(width: 12),
//
//             Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // GOLD BUTTON
//   // ============================================================
//
//   Widget _buildGoldButton({
//     required String text,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return SizedBox(
//       width: double.infinity,
//       height: 62,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.accent,
//           foregroundColor: Colors.white,
//           elevation: 6,
//           shadowColor: AppColors.accent.withOpacity(.30),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(22),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 19,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             Icon(
//               icon,
//               size: 25,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // INFO CARD
//   // ============================================================
//
//   Widget _buildInfoCard({
//     required String text,
//   }) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 18,
//         vertical: 17,
//       ),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withOpacity(.06),
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.info_outline_rounded,
//             color: AppColors.primary,
//           ),
//
//           const SizedBox(width: 14),
//
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 15,
//                 height: 1.4,
//                 color: Color(0xFF536059),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // FEATURE ITEM
//   // ============================================================
//
//   Widget _buildFeatureItem({
//     required IconData icon,
//     required String title,
//   }) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           size: 38,
//           color: AppColors.primary,
//         ),
//
//         const SizedBox(height: 8),
//
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 15,
//             color: Color(0xFF46504A),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ============================================================
//   // VERTICAL DIVIDER
//   // ============================================================
//
//   Widget _buildVerticalDivider() {
//     return Container(
//       width: 1,
//       height: 55,
//       color: Colors.black.withOpacity(.08),
//     );
//   }
//
//   // ============================================================
//   // PAGE DOTS
//   // ============================================================
//
//   Widget _buildDots() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(
//         3,
//             (index) {
//           final isActive = index == _currentPage;
//
//           return AnimatedContainer(
//             duration: const Duration(milliseconds: 250),
//             margin: const EdgeInsets.symmetric(horizontal: 7),
//             width: isActive ? 14 : 10,
//             height: isActive ? 14 : 10,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: isActive
//                   ? AppColors.primary
//                   : Colors.grey.withOpacity(.25),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   // ============================================================
//   // CARD DECORATION
//   // ============================================================
//
//   BoxDecoration _softCardDecoration() {
//     return BoxDecoration(
//       color: Colors.white.withOpacity(.72),
//       borderRadius: BorderRadius.circular(22),
//       border: Border.all(
//         color: Colors.white.withOpacity(.8),
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(.06),
//           blurRadius: 25,
//           offset: const Offset(0, 10),
//         ),
//       ],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/dashboard_screen.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Util/helper_dialogs.dart';

import '../Providers/ble_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  BleStatus? previousStatus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
      body: Column(
        children: [

          // ----------------------------------------------------------
          // TOP GREEN AREA
          // ----------------------------------------------------------

          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              //color: AppColors.primary,
              decoration: BoxDecoration(
                //  color: AppColors.primary
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(.25),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Stack(
                    children: [

                      //----------------------------------------------------
                      // Plant Card (Background)
                      //----------------------------------------------------

                      Positioned(
                        right: 20,
                        top: 65,
                        child: Container(
                          width: 155,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Image.asset(
                              "images/plant.png",
                              height: 125,
                            ),
                          ),
                        ),
                      ),

                      //----------------------------------------------------
                      // Text (Front Layer)
                      //----------------------------------------------------

                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.screenHorizontal,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "vira",
                                style: text.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: 270,
                                child: Text(
                                  "Your plants,\nalways cared for.",
                                  style: text.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      letterSpacing: 1
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Padding(
                                padding: const EdgeInsets.only(right: 30,left: 0),
                                child: Text(
                                  "Set a schedule once. Vira waters your plants automatically even when you're away.",
                                  style: text.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //----------------------------------------------------------
          // WHITE CARD
          //----------------------------------------------------------

          Expanded(
            flex: 5,
            child: Stack(
              children: [

                Container(
                  color: AppColors.background,
                ),

                Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.06),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Get started",
                            style: text.headlineSmall,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Pair your first Vira pot in 2 minutes",
                            style: text.bodyMedium,
                          ),

                          const SizedBox(height: 28),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context,MaterialPageRoute(builder: (context)=>DevicePairingScreen()));
                            },
                            child: const Text("Pair my first pot"),
                          ),

                          const SizedBox(height: 14),

                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>DashboardScreen()));
                            },
                            style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.accent.withOpacity(.2)
                            ),

                            child: const Text("I already have an account",style: TextStyle(color: AppColors.accentDark),),
                          ),


                          const SizedBox(height: 26),

                          Center(
                            child: Text(
                              "By continuing you agree to our Terms & Privacy Policy",
                              textAlign: TextAlign.center,
                              style: text.bodySmall,
                            ),
                          ),
                          /////////////////////////////////////
                          // const SizedBox(height: 4),
                          //
                          // OutlinedButton(
                          //   onPressed: () {
                          //     Navigator.push(context, MaterialPageRoute(builder: (context)=>BleScanScreen()));
                          //   },
                          //   style: OutlinedButton.styleFrom(
                          //       backgroundColor: AppColors.accent.withOpacity(.2)
                          //   ),
                          //
                          //   child: const Text("Temp Screen",style: TextStyle(color: AppColors.error),),
                          // ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}