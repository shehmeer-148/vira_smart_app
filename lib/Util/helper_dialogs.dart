import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../Core/app_colors.dart';

void handleBleNotReady(BleStatus status, BuildContext context) {
  // 🚫 Ignore unknown (initial state)
  if (status == BleStatus.unknown) return;

  String title;
  String msg;

  if (status == BleStatus.poweredOff) {
    title = "Bluetooth Required";
    msg =
    "Bluetooth is currently turned off. Please enable it to scan for Vira pots.";
  } else if (status == BleStatus.locationServicesDisabled) {
    title = "Location Required";
    msg =
    "Location services are disabled. BLE scanning requires location to be active.";
  } else {
    title = "Hardware Alert";
    msg = "Bluetooth status: ${status
        .toString()
        .split('.')
        .last}. Please check your settings.";
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                status == BleStatus.poweredOff
                    ? Icons.bluetooth_disabled
                    : Icons.location_off,
                color: Colors.blueGrey[700],
              ),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(msg),
          actions: [
            // Basic Text Button for Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Dismiss",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            // Neutral Filled Button for Settings
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                if (status == BleStatus.poweredOff) {
                  AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
                } else if (status == BleStatus.locationServicesDisabled) {
                  AppSettings.openAppSettings(type: AppSettingsType.location);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  });
}