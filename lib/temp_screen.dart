import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Presentation/Providers/Native_Provider/native_provider.dart';


class NativeTestScreen extends StatelessWidget {
  const NativeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NativeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.message.isEmpty
                  ? 'No response yet'
                  : provider.message,
            ),

            const SizedBox(height: 20),
            Text("Battery Value: ${provider.battery}" ),

            ElevatedButton(
              onPressed: () {
                context.read<NativeProvider>().getNativeMessage();
                context.read<NativeProvider>().getBatteryInfo();
              },
              child: const Text('Call Kotlin'),
            ),
          ],
        ),
      ),
    );
  }
}