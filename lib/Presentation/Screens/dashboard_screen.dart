import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vira_planter_app/Presentation/Providers/pot_provider.dart';
import 'package:vira_planter_app/Presentation/Screens/pairing_scanning%20_screen.dart';
import 'package:vira_planter_app/Presentation/Screens/pot_dashboard_screen.dart';
import 'package:vira_planter_app/Util/app_snackbar.dart';
import 'package:vira_planter_app/Util/helper_functions.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Core/enums.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../Providers/ble_provider.dart';
import '../Widgets/dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String userName = "Good morning";
  late PotProvider potProvider;


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      potProvider = context.read<PotProvider>();
      potProvider.clear();
      potProvider.loadAllPots();
    });
  }


  @override
  void dispose() {
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: AppColors.background,
  //
  //     body: Consumer<PotProvider>(
  //       builder: (context, provider, child) {
  //         final pots = provider.pots;
  //         return provider.isLoadingPots
  //             ? Center(
  //           child: CircularProgressIndicator(color: AppColors.primary),
  //         )
  //             : provider.pots.isEmpty
  //             ? Center(
  //           child: Text(
  //             "No Pots Available, Press the Add button to add Pots of your own desire",
  //           ),
  //         )
  //             : Stack(
  //           clipBehavior: Clip.none,
  //           children: [
  //             //---------------------------------------------------------
  //             // MAIN CONTENT
  //             //---------------------------------------------------------
  //             Column(
  //               children: [
  //                 Container(
  //                   height: 220,
  //                   width: double.infinity,
  //                   padding: const EdgeInsets.only(
  //                     top: 60,
  //                     left: AppSpacing.screenHorizontal,
  //                     right: AppSpacing.screenHorizontal,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     gradient: const LinearGradient(
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                       colors: [
  //                         AppColors.primary,
  //                         AppColors.primaryLight,
  //                       ],
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: AppColors.primary.withOpacity(.25),
  //                         blurRadius: 22,
  //                         offset: const Offset(0, 10),
  //                       ),
  //                     ],
  //                   ),
  //                   child: homeHeader(pots.length, context),
  //                 ),
  //
  //                 Consumer<BleProvider>(
  //                   builder: (context, bleProvider, child) {
  //
  //                     return Expanded(
  //                       child: Container(
  //                         width: double.infinity,
  //                         decoration: const BoxDecoration(
  //                           color: AppColors.background,
  //                           borderRadius: BorderRadius.vertical(
  //                             top: Radius.circular(30),
  //                           ),
  //                         ),
  //                         child: ListView.builder(
  //                           padding: const EdgeInsets.fromLTRB(
  //                             AppSpacing.screenHorizontal,
  //                             20,
  //                             AppSpacing.screenHorizontal,
  //                             20,
  //                           ),
  //                           itemCount: pots.length,
  //                           itemBuilder: (context, index) {
  //
  //                             final pot = pots[index];
  //
  //                             final isConnected = bleProvider.isPotConnected(pot.deviceId);
  //                             final isConnecting = bleProvider.isPotConnecting(pot.deviceId);
  //                             return Padding(
  //                               padding: const EdgeInsets.only(bottom: 18),
  //                               child: potCard(
  //                                 context: context,
  //                                 onTap: () {
  //                                   Navigator.push(
  //                                     context,
  //                                     MaterialPageRoute(
  //                                       builder: (context) =>
  //                                           PotDashboardScreen(pot: pot,),
  //                                     ),
  //                                   );
  //                                 },
  //                                 image: pot.plantImage,
  //                                 name: pot.plantName,
  //                                 location: "Living Room",
  //                                 status: parseTankStatus(pot),
  //                                 statusColor: tankStatusColor(pot),
  //                                 //waterLevel: pot.batteryLevel / 100,
  //                                 waterLevel: tankProgress(pot),
  //                                 progressColor: AppColors.success,
  //                                 lastWatered: formatLastWatered(
  //                                   pot.lastWatered,
  //                                 ),
  //                                 isConnected: isConnected,
  //                                 onConnect: () {
  //                                   _connectToPot(pot);
  //                                 },
  //                                 isConnecting: isConnecting,
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //
  //             //---------------------------------------------------------
  //             // FLOATING SUMMARY CARD
  //             //---------------------------------------------------------
  //             Positioned(
  //               left: AppSpacing.screenHorizontal,
  //               right: AppSpacing.screenHorizontal,
  //               top: 135,
  //               child: summaryCard(provider, context),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //
  //     floatingActionButton: FloatingActionButton(
  //       backgroundColor: AppColors.accent,
  //       onPressed: () {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => DevicePairingScreen()),
  //         );
  //       },
  //       child: const Icon(Icons.add),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Consumer<PotProvider>(
        builder: (context, provider, child) {
          final pots = provider.pots;

          return provider.isLoadingPots
              ? Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          )
              : Stack(
            clipBehavior: Clip.none,
            children: [
              //---------------------------------------------------------
              // MAIN CONTENT
              //---------------------------------------------------------
              Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: AppSpacing.screenHorizontal,
                      right: AppSpacing.screenHorizontal,
                    ),
                    decoration: BoxDecoration(
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
                    child: homeHeader(
                      pots.length,
                      context,
                    ),
                  ),

                  Consumer<BleProvider>(
                    builder: (context, bleProvider, child) {
                      return Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(0),
                            ),
                          ),

                          // 👇 IMPORTANT
                          child: pots.isEmpty
                              ? emptyPotsState(context)
                              : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenHorizontal,
                              20,
                              AppSpacing.screenHorizontal,
                              20,
                            ),
                            itemCount: pots.length,
                            itemBuilder: (context, index) {
                              final pot = pots[index];

                              final isConnected =
                              bleProvider.isPotConnected(
                                pot.deviceId,
                              );

                              final isConnecting =
                              bleProvider.isPotConnecting(
                                pot.deviceId,
                              );

                              return Padding(
                                padding:
                                const EdgeInsets.only(bottom: 18),
                                child: potCard(
                                  context: context,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PotDashboardScreen(
                                              pot: pot,
                                            ),
                                      ),
                                    );
                                  },
                                  image: pot.plantImage,
                                  name: pot.plantName,
                                  location: pot.getPlantCategory(pot.plantType),
                                  status: parseTankStatus(pot),
                                  statusColor:
                                  tankStatusColor(pot),
                                  waterLevel: tankProgress(pot),
                                  progressColor:
                                  AppColors.success,
                                  lastWatered:
                                  formatLastWatered(
                                    pot.lastWatered,
                                  ),
                                  isConnected: isConnected,
                                  onConnect: () {
                                    _connectToPot(pot);
                                  },
                                  isConnecting: isConnecting,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              //---------------------------------------------------------
              // SUMMARY CARD
              //---------------------------------------------------------
              Positioned(
                left: AppSpacing.screenHorizontal,
                right: AppSpacing.screenHorizontal,
                top: 135,
                child: summaryCard(
                  provider,
                  context,
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DevicePairingScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _connectToPot(PotModel pot) async {
    final bleProvider = context.read<BleProvider>();

    final result = await bleProvider.connectToPot(pot);

    if (!mounted) return;

    switch (result) {
      case ConnectResult.connected:
        print("✅ ${pot.plantName} connected");
        break;

      case ConnectResult.bluetoothNotReady:
        AppSnackbar.error(
          context,
          "Bluetooth is not ready. Please turn on Bluetooth.",
        );
        break;

      case ConnectResult.alreadyConnecting:
        AppSnackbar.info(
          context,
          "Another pot is already connecting.",
        );
        break;

      case ConnectResult.deviceNotFound:
        AppSnackbar.error(
          context,
          "${pot.plantName} could not be found.",
        );
        break;

      case ConnectResult.connectionFailed:
        AppSnackbar.error(
          context,
          "Could not connect to ${pot.plantName}.",
        );
        break;
    }
  }
}
