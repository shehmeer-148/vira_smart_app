import 'package:flutter/material.dart';
import 'package:vira_planter_app/Presentation/Screens/schedule_builder_screen.dart';

import '../../Core/app_colors.dart';
import '../../Data/Model_classes/pot_model.dart';
import '../../Util/helper_functions.dart';
bool hubEnabled = true;

Widget plantInfoCard(BuildContext context , PotModel pot ,TextEditingController controller) {
  final text = Theme.of(context).textTheme;
  final category = pot.getPlantCategory(pot.plantType);
  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //--------------------------------------------------------
          // Top Row
          //--------------------------------------------------------

          Row(
            children: [

              plantIcon(pot.plantImage),

              const SizedBox(width: 4),

              Expanded(
                child: plantNameField(pot.plantName,context,controller),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            "Tap name to rename",
            style: text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          Divider(
            color: AppColors.divider,
            height: 1,
          ),

          const SizedBox(height: 14),

          plantTypeRow(category,context),
        ],
      ),
    ),
  );
}
Widget plantIcon(String image) {
  return Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      // color: AppColors.primary.withOpacity(.10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(0),
      child: Image.asset(
        image,
      ),
    ),
  );
}
Widget plantNameField(String plantName, BuildContext context, TextEditingController plantNameController) {
  return TextField(
    controller: plantNameController,
    style: Theme.of(context).textTheme.labelLarge,

    decoration: InputDecoration(
      hintText: plantName,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(.5),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    ),
  );
}
Widget plantTypeRow(String plantType, BuildContext context) {
  final text = Theme.of(context).textTheme;

  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () {},
    child: Row(
      children: [

        Text(
          "Plant type:",
          style: text.bodyMedium,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            plantType,
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Text(
          "Change",
          style: text.bodyMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(width: 4),

        const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.primary,
        ),
      ],
    ),
  );
}
Widget scheduleCard(PotModel pot, BuildContext context) {
  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [

          settingRow(
            title: "Watering Days",
            value:  formatDaysMask(pot.daysMask),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>WateringScheduleScreen()));

            }, context: context,
          ),

          settingRow(
            title: "Time",
            value: formatTimeMinutes(pot.timeMinutes),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>WateringScheduleScreen()));

            },
            context: context
          ),

          settingRow(
            title: "Duration",
            value: "${pot.waterDuration} seconds",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>WateringScheduleScreen()));

            },
            context: context
          ),

          settingRow(
            title: "Times per Day",
            value: "${pot.wateringsPerDay}x",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>WateringScheduleScreen()));

            },
            isLast: true,
            context: context
          ),

        ],
      ),
    ),
  );
}
Widget settingRow({
  required BuildContext context,
  required String title,
  required String value,
  VoidCallback? onTap,
  bool isLast = false,
}) {
  final text = Theme.of(context).textTheme;

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [

          Expanded(
            child: Text(
              title,
              style: text.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: Text(
              textAlign: TextAlign.right,
              value,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(width: 6),

          Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textSecondary.withOpacity(.6),
          ),

        ],
      ),
    ),
  );
}
Widget sectionTitle(String title, BuildContext context) {
  return Text(
    title,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: AppColors.textSecondary,
    ),
  );
}
Widget connectivityCard(BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [

          //----------------------------------------------------
          // Hub Mode
          //----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Hub Mode",
                        style: text.titleSmall,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Connected to Vira Hub",
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: hubEnabled,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  onChanged: (value) {
                  },
                ),
              ],
            ),
          ),

          Divider(
            color: AppColors.divider,
            height: 1,
          ),

          //----------------------------------------------------
          // Status Interval
          //----------------------------------------------------

          settingRow(
            title: "Status Interval",
            value: "Every 12 hours",
            isLast: true,
            onTap: () {},
            context: context
          ),
        ],
      ),
    ),
  );
}
Widget deviceInfoCard(PotModel pot ,BuildContext context) {
  return Material(
    elevation: 3,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [

          deviceInfoRow(
            context,
            title: "Device ID",
            value: pot.deviceId,
          ),

          deviceInfoRow(
            context,
            title: "Firmware",
            value: pot.firmwareVersion,
          ),

          deviceInfoRow(
            context,
            title: "Paired",
            value: formatSetupDate(pot.pairedAt),
            isLast: true,
          ),

        ],
      ),
    ),
  );
}
Widget deviceInfoRow(BuildContext context, {
  required String title,
  required String value,
  bool isLast = false,
}) {
  final text = Theme.of(context).textTheme;

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : Border(
        bottom: BorderSide(
          color: AppColors.divider,
        ),
      ),
    ),
    child: Row(
      children: [

        Expanded(
          child: Text(
            title,
            style: text.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),

        SelectableText(
          value,
          style: text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}