import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mcumgr_dart/mcumgr_dart.dart';
import 'package:vira_planter_app/smpbletransport.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cbor/cbor.dart';

class SmpTest {
  SmpTest({
    required this.ble,
    required this.deviceId,
    required this.onProgress,
  });

  final FlutterReactiveBle ble;
  final String deviceId;
  final void Function(double progress)? onProgress;

  late final SmpBleTransport transport;
  late final SmpClient client;

  Future<void> start() async {
    transport = SmpBleTransport(ble: ble, deviceId: deviceId);

    client = SmpClient(transport);

    print('🔗 [SmpTest] Connecting transport...');
    await transport.connect();

    // 🌟 FIX: GATT STABILIZATION DELAY
    // The first time a connection is made, the BLE stack needs a moment
    // to finalize service discovery and MTU exchange before sending
    // heavy SMP data.
    print('⏳ [SmpTest] Waiting for GATT stabilization...');
    await Future.delayed(const Duration(milliseconds: 1000));

    print('✅ [SmpTest] SmpClient created and transport ready');

    await firmwareUploadTest();
  }

  Future<void> firmwareUploadTestOld() async {
    print('');
    print('=================================================');
    print('🧪 FIRMWARE IMAGE UPLOAD VIA IMGMGMT');
    print('=================================================');

    try {
      // 1. Load the firmware binary file
      final data = await rootBundle.load('DFU-files/original.bin');
      final firmware = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      print('📦 Loaded Firmware: ${firmware.length} bytes');

      // 2. Instantiate the high-level Image Management handler
      final imgMgmt = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );
      print(
        '📤 Starting firmware upload with chunk size: ${imgMgmt.steadyChunkSize}',
      );

      // 3. Run the upload natively.
      final List<int> responseSha = await imgMgmt.upload(
        firmware,
        onProgress: (int sent, int total) {
          final double progressValue = sent / total;

          // Trigger the callback for the UI Dialog
          if (onProgress != null) {
            onProgress!(progressValue);
          }

          print(
            '⏳ Upload Progress: ${(progressValue * 100).toStringAsFixed(1)}% ($sent/$total bytes)',
          );
        },
      );

      // 4. Finalize and Reboot
      await finalizeAndReboot(responseSha);

      final hexSha = responseSha
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      print('✅ FIRMWARE UPLOAD COMPLETED. SHA: $hexSha');
    } catch (e, stackTrace) {
      print('❌ UPLOAD FAILED: $e');
      print(stackTrace);
      // 🌟 CRITICAL: Rethrow the error so the Provider/UI knows it failed
      rethrow;
    }
  }

  Future<void> firmwareUploadTest() async {
    print('');
    print('=================================================');
    print('🧪 AUTOMATIC ALTERNATING FIRMWARE UPLOAD');
    print('=================================================');

    try {
      final imgMgmt = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );

      // 1. Get the hash of the firmware currently running on the device
      print('🔍 Checking current device firmware hash...');
      final slots = await imgMgmt.list();
      final runningSlot = slots.firstWhere((s) => s.slot == 0);
      final deviceHashHex = runningSlot.hashHex;
      print('📱 Device is currently running hash: $deviceHashHex');

      // 2. Load both files and calculate their hashes
      final originalData = await rootBundle.load('DFU-files/zephyr.signed.bin');
      final trailData = await rootBundle.load('DFU-files/original.bin');

      final trailBytes = trailData.buffer.asUint8List();
      final originalBytes = originalData.buffer.asUint8List();

      // Calculate local hashes to compare
      final trailHashHex = crypto.sha256.convert(trailBytes).toString();
      final originalHashHex = crypto.sha256.convert(originalBytes).toString();

      // 3. Logic: Select the file that is DIFFERENT from what is on the device
      Uint8List firmwareToUpload;
      String fileName;

      if (deviceHashHex == originalHashHex) {
        print(
          '🔄 Device has "original.bin". Switching to "trail.bin" for test.',
        );
        firmwareToUpload = trailBytes;
        fileName = 'trail.bin';
      } else {
        print(
          '🔄 Device has "trail.bin" (or unknown). Switching to "original.bin" for test.',
        );
        firmwareToUpload = originalBytes;
        fileName = 'original.bin';
      }

      print('📦 Selected File: $fileName (${firmwareToUpload.length} bytes)');
      print(
        '📤 Starting firmware upload with chunk size: ${imgMgmt.steadyChunkSize}',
      );

      // 4. Run the upload
      final List<int> responseSha = await imgMgmt.upload(
        firmwareToUpload,
        onProgress: (int sent, int total) {
          final double progressValue = sent / total;
          if (onProgress != null) {
            onProgress!(progressValue);
          }
          // Optional: reduce logging frequency to speed up UI
          if (sent % 5 == 0 || sent == total) {
            print(
              '⏳ Uploading $fileName: ${(progressValue * 100).toStringAsFixed(1)}%',
            );
          }
        },
      );

      // 5. Finalize and Reboot
      await finalizeAndReboot(responseSha);

      print('✅ FIRMWARE UPLOAD COMPLETED: $fileName is now staged.');
    } catch (e, stackTrace) {
      print('❌ UPLOAD FAILED: $e');
      rethrow;
    }
  }

  Future<void> finalizeAndReboot(List<int> localSha) async {
    print('🔄 FINALIZING DFU AND REBOOTING DEVICE');

    try {
      final imgMgmt = ImgMgmt(client);

      // Small delay before final commands to ensure flash is ready
      await Future.delayed(const Duration(milliseconds: 500));

      final slots = await imgMgmt.list();
      ImageSlot? secondarySlot;
      for (var slot in slots) {
        if (slot.slot == 1) secondarySlot = slot;
      }

      if (secondarySlot == null || secondarySlot.hash.isEmpty) {
        throw Exception('Secondary slot (Slot 1) is empty! Upload failed.');
      }

      final Uint8List flashHash = secondarySlot.hash;
      print('Testing new firmware image: ${secondarySlot.hashHex}');

      await imgMgmt.test(flashHash);
      print('✅ Image marked for boot test!');

      print('Sending reset command...');
      final osMgmt = OsMgmt(client);
      await osMgmt.reset();
      print('🚀 Reset command sent!');
    } catch (e, stackTrace) {
      print('❌ FINALIZATION FAILED: $e');
      rethrow;
    }
  }

  /// 🌟 NEW: Permanent Confirmation Function
  /// Run this command ONLY after the device has rebooted from an update
  /// and your phone reconnects to it over BLE!
  Future<void> confirmNewFirmwarePermanent() async {
    print('');
    print('=================================================');
    print('🔐 LOCKING IN FIRMWARE PERMANENTLY');
    print('=================================================');

    try {
      final img = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );

      print('Reading image slot list from device...');
      final slots = await img.list();

      ImageSlot? runningSlot;
      for (var slot in slots) {
        if (slot.slot == 0) runningSlot = slot;
      }

      if (runningSlot != null) {
        print('Current Running Hash: ${runningSlot.hashHex}');

        if (runningSlot.confirmed) {
          print('✅ Image is already permanently confirmed!');
          return;
        }

        print('Sending permanent confirmation instruction to chip...');
        // Passing the active running hash locks this slot in permanently
        await img.confirm(runningSlot.hash);
        print(
          '🎉 SUCCESS! Firmware update is permanent and will not roll back on power cycles.',
        );
      } else {
        print('⚠️ Could not identify active Slot 0 context.');
      }
    } catch (e, stackTrace) {
      print('❌ Permanent confirmation failed');
      print('Error: $e');
      print(stackTrace);
    }
  }
}
