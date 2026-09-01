import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../Core/app_colors.dart';

void handleBleNotReady(BleStatus status, BuildContext context) {
  // 🚫 Ignore unknown (initial state)
  if (status == BleStatus.unknown) return;

  String msg;

  if (status == BleStatus.poweredOff) {
    msg = "Please turn ON Bluetooth";
  } else if (status == BleStatus.locationServicesDisabled) {
    msg = "Please turn ON Location";
  } else {
    msg = "Bluetooth not ready";
  }


  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //====================================================
                // ICON
                //====================================================
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == BleStatus.poweredOff
                        ? Icons.bluetooth_disabled_rounded
                        : Icons.location_off_rounded,
                    size: 46,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  "Action Required",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);

                          if (status == BleStatus.poweredOff) {
                            AppSettings.openAppSettings(
                              type: AppSettingsType.bluetooth,
                            );
                          } else if (status ==
                              BleStatus.locationServicesDisabled) {
                            AppSettings.openAppSettings(
                              type: AppSettingsType.location,
                            );
                          }
                        },
                        child: const Text("Open Settings"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  });
}
