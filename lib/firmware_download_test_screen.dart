
import 'package:flutter/material.dart';
import 'package:vira_planter_app/smpbletransport.dart';

class FirmwareTestScreen extends StatefulWidget {
const FirmwareTestScreen({super.key});

@override
State<FirmwareTestScreen> createState() => _FirmwareTestScreenState();
}

class _FirmwareTestScreenState extends State<FirmwareTestScreen> {
final FirmwareService _firmwareService = FirmwareService();

String _version = 'Not checked yet';
bool _isLoading = false;

Future<void> _checkFirmwareVersion() async {
setState(() {
_isLoading = true;
_version = 'Checking...';
});

final version = await _firmwareService.getLatestVersion();

if (!mounted) return;

setState(() {
_isLoading = false;
_version = version ?? 'Failed to get version';
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Firmware Test'),
),
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Text(
'Latest GitHub Firmware:',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

Text(
_version,
style: const TextStyle(
fontSize: 24,
),
),

const SizedBox(height: 30),

ElevatedButton(
onPressed: _isLoading ? null : _checkFirmwareVersion,
child: Text(
_isLoading ? 'Checking...' : 'Check Firmware Version',
),
),
],
),
),
);
}
}
