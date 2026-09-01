import 'package:flutter/material.dart';

import '../../Core/app_colors.dart';
import '../../Util/helper_functions.dart';
import '../Providers/pot_provider.dart';

Widget homeHeader(int totalPots ,BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning 🌿",
              style: text.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            Text(
                totalPots == 0
                    ? "No pots added yet"
                    : "$totalPots ${totalPots == 1 ? 'pot' : 'pots'}, all happy",
             // "$totalPots pots, all happy",
              style: text.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),

    ],
  );
}


Widget summaryCard(
    PotProvider provider,
    BuildContext context,
    ) {
  final text = Theme.of(context).textTheme;

  final hasPots = provider.pots.isNotEmpty;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.12),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Image.asset(
              "images/plant.png",
            ),
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPots
                    ? "${provider.pots.length} Pots Active"
                    : "0 Pots Active",
                style: text.titleMedium?.copyWith(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                hasPots
                    ? "${provider.pots.first.plantName}: ${formatTimeMinutes(provider.pots.first.timeMinutes)}"
                    : "Add a pot to get started",
                style: text.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
Widget emptyPotsState(BuildContext context) {
  final text = Theme.of(context).textTheme;

  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              "images/plant.png",
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "No Pots Yet",
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Add your first smart pot to start monitoring your plant.",
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),


        ],
      ),
    ),
  );
}

Widget potCard({
  required BuildContext context,
  required String image,
  required String name,
  required String location,
  required String status,
  required Color statusColor,
  required double waterLevel,
  required Color progressColor,
  required String lastWatered,
  required bool isConnected,
  required bool isConnecting,
  VoidCallback? onConnect,
  VoidCallback? onTap,
}) {
  final text = Theme.of(context).textTheme;

  return Material(
    elevation: 4,
    shadowColor: Colors.black12,
    borderRadius: BorderRadius.circular(22),
    color: Colors.white,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 74,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Image.asset(image),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: text.titleLarge),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? Colors.green.withOpacity(.15)
                                  : Colors.red.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: isConnected
                                      ? Colors.green
                                      : Colors.red,
                                ),

                                const SizedBox(width: 4),

                                Text(
                                  isConnected
                                      ? "Connected"
                                      : "Offline",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isConnected
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 2),

                      Text(location, style: text.bodyMedium),

                      const SizedBox(height: 5),

                      Text(
                        status,
                        style: text.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      waterProgress(value: waterLevel, color: progressColor, context: context,),
                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 12),

            Divider(color: AppColors.divider, height: 1),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Last watered: $lastWatered",
                    style: text.bodySmall,
                  ),
                ),
                if (!isConnected)
                  SizedBox(
                    height: 32,
                    width: 80,

                    child: ElevatedButton(
                      onPressed: isConnecting
                          ? null
                          : onConnect,

                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor:
                        AppColors.accent.withOpacity(.7),
                      ),

                      child: isConnecting

                      // ------------------------------------------
                      // CONNECTING
                      // ------------------------------------------

                          ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )

                      // ------------------------------------------
                      // CONNECT
                      // ------------------------------------------

                          : const Text(
                        "Connect",
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget waterProgress({required double value, required Color color, required BuildContext context}) {
  return Row(
    children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),

      const SizedBox(width: 10),

      Text(
        "${(value * 100).toInt()}%",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}