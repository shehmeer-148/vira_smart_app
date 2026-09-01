import 'dart:io';
import 'dart:ui';

import 'package:permission_handler/permission_handler.dart';

import '../Core/app_colors.dart';
import '../Core/enums.dart';
import '../Data/Model_classes/pot_model.dart';

Future<bool> checkAndRequestPermissions() async {
  if (Platform.isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  } else {
    final status = await Permission.bluetooth.request();
    return status.isGranted;
  }
}

String parseTankStatus(PotModel pot) {
  switch (pot.tankStatus) {
    case 0:
      return "Tank Full";
    case 1:
      return "Tank Low";
    case 2:
      return "Tank Empty";
    default:
      return "Unknown";
  }
}
Color tankStatusColor(PotModel pot) {
  switch (pot.tankStatus) {
    case 0:
      return AppColors.success;

    case 1:
      return AppColors.accent;

    case 2:
      return AppColors.error;

    default:
      return AppColors.primaryLight;
  }
}
String formatLastWatered(int timestamp) {

  if (timestamp == 0) {
    return "Never";
  }

  final date = DateTime.fromMillisecondsSinceEpoch(
    timestamp * 1000,
  );

  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) {
    return "Just now";
  }

  if (difference.inHours < 1) {
    return "${difference.inMinutes} min ago";
  }

  if (difference.inDays < 1) {
    return "${difference.inHours} hr ago";
  }

  if (difference.inDays == 1) {
    return "Yesterday";
  }

  return "${difference.inDays} days ago";
}
double tankProgress(PotModel pot) {
  switch (TankStatus.values[pot.tankStatus]) {
    case TankStatus.ok:
      return 1.0;

    case TankStatus.empty:
      return 0.0;
    case TankStatus.noSensor:
      return 0.0;
    case TankStatus.unknown:
      return 0.0;
  }
}

///////////////////////////////////////////////////////////////////

String formatDaysMask(int daysMask) {
  const days = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];

  final selected = <String>[];

  for (int i = 0; i < days.length; i++) {
    if ((daysMask & (1 << i)) != 0) {
      selected.add(days[i]);
    }
  }

  if (selected.isEmpty) {
    return "No days";
  }

  return selected.join(" / ");
}
String formatTimeMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;

  final period = hour >= 12 ? "PM" : "AM";

  final displayHour =
  hour % 12 == 0 ? 12 : hour % 12;

  return "$displayHour:${minute.toString().padLeft(2, '0')} $period";
}
String formatSetupDate(int timestamp) {
  if (timestamp == 0) {
    return "Unknown";
  }

  final date = DateTime.fromMillisecondsSinceEpoch(
    timestamp,
  );

  return "${_monthName(date.month)} "
      "${date.day}, "
      "${date.year}";
}
String _monthName(int month) {
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  return months[month - 1];
}
String formatNextWatering(PotModel pot) {
  return formatTimeMinutes(pot.timeMinutes);
}