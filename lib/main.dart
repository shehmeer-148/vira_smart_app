import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Data/Services/Ble_Vira/ble_services.dart';
import 'package:vira_planter_app/Presentation/Client_Screens/pairing_screen.dart';
import 'package:vira_planter_app/Presentation/Providers/ble_provider.dart';
import 'package:vira_planter_app/Presentation/Providers/plant_provider.dart';
import 'package:vira_planter_app/Presentation/Providers/pot_provider.dart';
import 'package:vira_planter_app/Presentation/Screens/intro_screens.dart';
import 'package:vira_planter_app/Presentation/Screens/onboarding_screen.dart';
import 'package:vira_planter_app/firmware_download_test_screen.dart';
import 'package:vira_planter_app/temp2%20screen.dart';

import 'Core/app_colors.dart';
import 'Core/app_theme.dart';
import 'Data/Services/Database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => BleService(),),
          ChangeNotifierProvider(
            lazy: false,
            create: (context) {
              final provider = BleProvider(context.read<BleService>());
              provider.initialize();
              return provider;
            },
          ),
          ChangeNotifierProvider(create: (context)=>PlantProvider()),
          ChangeNotifierProvider(create: (context)=> PotProvider(DatabaseHelper.instance)),
        ],

        child: ViraPlantraApp(),
      ),
  );
}

class ViraPlantraApp extends StatelessWidget {
  const ViraPlantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primary,
        systemStatusBarContrastEnforced: false,
      ),
      child: MaterialApp(
        title: 'Vira Plantra',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,

       // home: const OnboardingScreens(),
        // home: const BleScanScreen(),
        //home: FirmwareTestScreen(),
       // home: PairingScreen(),
        home: OnboardingPage(),
      ),
    );
  }
}