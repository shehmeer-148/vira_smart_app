import 'package:flutter/material.dart';

import '../../Core/app_colors.dart';
import '../../Core/app_spacing.dart';
import '../../Core/enums.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../../Util/helper_functions.dart';
import '../Screens/setting_screen.dart';

Widget plantOverviewCard(PotModel pot, BuildContext context) {

  final text = Theme.of(context).textTheme;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //--------------------------------------------------
          // Plant Info
          //--------------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  // color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    pot.plantImage,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      pot.plantName,
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                     "Type: ${pot.getPlantCategory(pot.plantType)}",
                      style: text.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          nextWaterCard(pot,context),
          const SizedBox(height: 8),

          Row(
            children: [

              const Icon(
                Icons.circle,
                color: Colors.white70,
                size: 8,
              ),

              const SizedBox(width: 8),

              Text(
                "Last watered ${formatLastWatered(pot.lastWatered)}",
                style: text.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
Widget nextWaterCard(PotModel pot, BuildContext context) {

  final text = Theme.of(context).textTheme;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.12),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          "NEXT WATERING",
          style: text.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          formatNextWatering(pot),
          style: text.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          "${formatDaysMask(pot.daysMask)} schedule",
          style: text.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),

      ],
    ),
  );
}
Widget batteryCard(int batteryLevel, BuildContext context) {
  final text = Theme.of(context).textTheme;

  return SizedBox(
    height: 120,
    child: Material(
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Battery",
              style: text.labelLarge?.copyWith(
                color: AppColors.textPrimary.withOpacity(.5),
              ),
            ),

            const Spacer(),

            Text(
              "${batteryLevel}%",
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: batteryLevel/100,
                minHeight: 7,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget tankCard(PotModel pot, BuildContext context) {
  final text = Theme.of(context).textTheme;
  final tankStatus = TankStatus.values[pot.tankStatus];

  final bool tankOk =
      tankStatus == TankStatus.ok;

  return SizedBox(
    height: 120,
    child: Material(
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Tank",
              style: text.labelLarge?.copyWith(
                color: AppColors.textPrimary.withOpacity(.5),
              ),
            ),


            const Spacer(),

            Text(
              tankOk ? "OK" : tankStatus.name,
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Water Present",
              style: text.bodyMedium,
            ),

            //const Spacer(),
          ],
        ),
      ),
    ),
  );
}
Widget wateringCyclesCard(PotModel pot, BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Total Watering Cycles",
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold,fontSize: 13),
                ),

                const SizedBox(height: 6),

                Text(
                  "Since setup on ${formatSetupDate(pot.pairedAt)}",
                  style: text.bodySmall,
                ),
              ],
            ),
          ),

          Text(
            pot.cycleCount.toString(),
            style: text.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
Widget waterNowButton( BuildContext context) {
  final text = Theme.of(context).textTheme;

  return SizedBox(
    width: double.infinity,
    height: 58,
    child: ElevatedButton.icon(
      onPressed: () {},
      icon: const Text(
        "💧",
        style: TextStyle(fontSize: 18),
      ),
      label: Text(
        "Water Now",
        style: text.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}
Widget manualWaterHint(BuildContext context) {
  return Center(
    child: Text(
      "Double-press the pot button for manual watering",
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}
Widget scheduleCard(PotModel pot, BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Schedule",
            // style: text.titleMedium,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold,fontSize: 13),

          ),

          const SizedBox(height: 12),

          Row(
            children: [

              Expanded(
                child: Text(
                  // "Mon / Wed / Sat  •  09:00 AM   •  45 sec",
                  "  •  ${formatDaysMask(pot.daysMask)}\n"
                      "  •  ${formatTimeMinutes(pot.timeMinutes)}\n"
                      "  •  ${pot.waterDuration} sec\n"
                      "  •  ${pot.wateringsPerDay}x/day",
                  style: text.labelMedium,
                ),
              ),

            ],
          ),

          const SizedBox(height: 14),

          Divider(
            color: AppColors.divider,
            height: 1,
          ),

          const SizedBox(height: 12),

          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SettingScreen(pot: pot,)));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Edit Schedule",
                style: text.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}