import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vira_planter_app/Data/Model_classes/plant_model.dart';
import 'package:vira_planter_app/Data/Model_classes/plant_schedule_model.dart';
import 'package:vira_planter_app/Presentation/Providers/plant_provider.dart';
import 'package:vira_planter_app/Presentation/Screens/hub_mode_setup_screen.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Util/app_snackbar.dart';
import '../Providers/ble_provider.dart';
import '../Widgets/schedule_builder_widgets.dart';

class WateringScheduleScreen extends StatefulWidget {
  const WateringScheduleScreen({super.key});

  @override
  State<WateringScheduleScreen> createState() => _WateringScheduleScreenState();
}

class _WateringScheduleScreenState extends State<WateringScheduleScreen> {

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
            Expanded(
              child: Text("Watering Schedule", style: text.headlineSmall),
            ),
            Text(
              "Step 2 of 3",
              style: text.bodySmall?.copyWith(
                color: AppColors.primary.withOpacity(.6),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.lg,
        ),
        child: Consumer<PlantProvider>(
          builder: (context, provider, child) {
            final schedule = provider.schedule!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                selectedPlantCard(provider.selectedPlant!,context),

                const SizedBox(height: 20),

                Text("Watering Days", style: text.titleSmall),

                const SizedBox(height: 14),

                daysSelector(schedule,context),

                const SizedBox(height: 20),

                Text("Time of Day", style: text.titleSmall),

                const SizedBox(height: 14),

                timeCard(schedule,context),

                const SizedBox(height: 20),

                Text("Times per Day", style: text.titleSmall),

                const SizedBox(height: 14),

                timesPerDaySelector(schedule,context),

                const SizedBox(height: 20),

                durationSlider(schedule,context),

                const SizedBox(height: 20),

                infoCard(provider.selectedPlant!,context),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () async {
                    final ble = context.read<BleProvider>();
                    final plant = context.read<PlantProvider>();

                    final success = await ble.saveSchedule(
                      schedule: plant.schedule!,
                    );

                    if (success) {

                      await ble.setupDone();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HubModeSetupScreen(),
                        ),
                      );
                    } else {
                      AppSnackbar.error(
                        context,
                        "Unable to save schedule. Make Sure connection is established",
                      );
                    }
                  },
                  child: const Text("Continue"),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }


}
