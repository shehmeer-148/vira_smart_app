
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