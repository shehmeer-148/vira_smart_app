import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Presentation/Screens/dashboard_screen.dart';
import 'package:vira_planter_app/Util/app_snackbar.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../Providers/ble_provider.dart';
import '../Providers/plant_provider.dart';

class HubModeSetupScreen extends StatefulWidget {
  const HubModeSetupScreen({super.key});

  @override
  State<HubModeSetupScreen> createState() => _HubModeSetupScreenState();
}

class _HubModeSetupScreenState extends State<HubModeSetupScreen> {

  bool hubConnected = true;
  int selectedInterval = 1;

  final intervals = [
    "6h",
    "12h",
    "24h",
    "Off",
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            Expanded(child: Text("Connectivity", style: text.headlineSmall)),
            Text(
              "Step 3 of 3",
              style: text.bodySmall?.copyWith(
                color: AppColors.primary.withOpacity(.6),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            hubDeviceCard(
              connected: hubConnected,
              onChanged: (value) {
                setState(() {
                  hubConnected = value;
                });
              },
            ),
            SizedBox(height: 18,),
            updateIntervalCard(),
            SizedBox(height: 18,),
            noHubCard(),
            SizedBox(height: 20,),

            Consumer<BleProvider>(
              builder: (_, ble, __) {

                return ElevatedButton(

                  onPressed: ble.isSetupFinished
                      ? null
                      : () async {
                    final plant = context.read<PlantProvider>();

                    final success = await ble.finishSetup(plant);

                    if (!context.mounted) return;

                    if (success) {

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const DashboardScreen(),
                        ),
                      );
                    }
                    else{
                      AppSnackbar.error(context, "Connection Interrupted! Make sure your Vira pot is connected");
                    }
                  },

                  child: ble.isSetupFinished
                      ? LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.white,
                    size: 24,
                  )
                      : const Text("Finish Setup"),
                );
              },
            )
          ],
        ),
      ),
    );
  }
  Widget hubDeviceCard({
    required bool connected,
    required ValueChanged<bool> onChanged,
  }) {
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.cardBackground,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Hub Device",
                        style: text.titleMedium,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Connect a Vira Hub to monitor your pots from anywhere even when you're away from home.",
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: connected,
                  onChanged: onChanged,
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (connected)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Hub connected ✓",
                  style: text.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget updateIntervalCard() {
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Status Update Interval",
              style: text.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              "How often should your pot check in with the hub to report battery & water tank status?",
              style: text.bodyMedium,
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                "Every 12h means your hub log will never be more than 12 hours out of date.",
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: List.generate(
                intervals.length,
                    (index) {

                  final selected = selectedInterval == index;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {

                          setState(() {
                            selectedInterval = index;
                          });

                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              intervals[index],
                              style: text.titleSmall?.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget noHubCard() {
    final text = Theme.of(context).textTheme;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: AppColors.cardBackground,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "No Hub?",
              style: text.titleMedium,
            ),

            const SizedBox(height: 6),

            Text(
              "No problem. Your pot works fully standalone watering on schedule with no internet needed.",
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
