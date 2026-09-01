import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Core/app_colors.dart';
import '../../Data/Model_classes/plant_model.dart';
import '../../Data/Model_classes/plant_schedule_model.dart';
import '../Providers/plant_provider.dart';

final List<String> weekDays = ["M", "T", "W", "T", "F", "S", "S"];

Widget selectedPlantCard(PlantModel plant ,BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Material(
    elevation: 2,
    borderRadius: BorderRadius.circular(16),
    color: AppColors.cardBackground,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(plant.image),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plant.name, style: text.titleMedium),

                const SizedBox(height: 2),

                Text(
                  "Defaults loaded from library",
                  style: text.bodySmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget daysSelector(PlantSchedule plantSchedule ,BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(weekDays.length, (index) {
      return dayChip(
        context,
        label: weekDays[index],
        selected: plantSchedule.isDaySelected(index),

        onTap: () {
          context.read<PlantProvider>().toggleDay(index);
        },
      );
    }),
  );
}

Widget dayChip(BuildContext context,{
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(50),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),

      height: 42,
      width: 42,

      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,

        shape: BoxShape.circle,

        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),

      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

Widget timeCard(PlantSchedule plantSchedule ,BuildContext context) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: plantSchedule.time,
      );

      if (time != null) {
        context.read<PlantProvider>().updateTime(time);
      }
    },
    child: Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              plantSchedule.time.format(context),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Container(width: 100, height: 1, color: AppColors.border),

            const SizedBox(height: 4),

            Text(
              plantSchedule.time.period == DayPeriod.am ? "AM" : "PM",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget timesPerDaySelector(PlantSchedule plantSchedule ,BuildContext context) {
  return Material(
    elevation: 2,
    borderRadius: BorderRadius.circular(18),
    color: AppColors.cardBackground,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          final value = index + 1;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: frequencyChip(value, plantSchedule,context),
            ),
          );
        }),
      ),
    ),
  );
}

Widget frequencyChip(int value, PlantSchedule schedule ,BuildContext context) {
  final selected = schedule.wateringsPerDay == value;

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      context.read<PlantProvider>().updateTimesPerDay(value);
    },
    child: AnimatedContainer(
      padding: EdgeInsets.all(8),
      duration: const Duration(milliseconds: 250),
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "${value}x",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

Widget durationSlider(PlantSchedule schedule ,BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text("Water Duration", style: text.titleMedium),

          const Spacer(),

          Text(
            "${schedule.waterDuration} seconds",
            style: text.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),

      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.primary,
          overlayColor: Colors.transparent,
          trackHeight: 5,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 9,
            elevation: 2,
          ),
        ),
        child: Slider(
          value: schedule.waterDuration.toDouble(),
          min: 10,
          max: 120,
          onChanged: (value) {
            context.read<PlantProvider>().updateWaterDuration(value.toInt());
          },
        ),
      ),
    ],
  );
}

Widget infoCard(PlantModel plant ,BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(.10),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("💡", style: TextStyle(fontSize: 18)),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            plant.tip,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
          ),
        ),
      ],
    ),
  );
}