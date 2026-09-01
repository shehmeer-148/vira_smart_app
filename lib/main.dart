import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Data/Services/Ble_Vira/ble_services.dart';
import 'package:vira_planter_app/Presentation/Providers/ble_provider.dart';
import 'package:vira_planter_app/Presentation/Providers/plant_provider.dart';
import 'package:vira_planter_app/Presentation/Providers/pot_provider.dart';
import 'package:vira_planter_app/Presentation/Screens/intro_screens.dart';
import 'package:vira_planter_app/Presentation/Screens/onboarding_screen.dart';

import 'Core/app_colors.dart';
import 'Core/app_theme.dart';
import 'Data/Services/Database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
      MultiProvider(
        providers: [
          Provider(create: (_) => BleService(),),
         // ChangeNotifierProvider(create: (context) =>BleProvider(context.read<BleService>(),DatabaseHelper.instance) ),
          ChangeNotifierProvider(
            lazy: false,
            create: (context) {
              final provider = BleProvider(context.read<BleService>(), DatabaseHelper.instance,);
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

       // home: const OnboardingPage(),
        home: const OnboardingScreens(),
      ),
    );
  }
}