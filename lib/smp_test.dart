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
    await diagnoseFirmwareImages();
  }



  Future<void> firmwareUploadTestOld() async {
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
      final trailData = await rootBundle.load('DFU-files/zephyr.signed(1).bin');

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
  Future<void> firmwareUploadTestWorking() async {
    print('');
    print('=================================================');
    print('🧪 AUTOMATIC FIRMWARE SELECTION & DFU TEST');
    print('=================================================');

    try {
      final imgMgmt = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );
      // =================================================
      // 1. CHECK CURRENT DEVICE FIRMWARE
      // =================================================

      print('');
      print('🔍 Checking current device firmware...');

      final slots = await imgMgmt.list();

      final runningSlot = slots.firstWhere(
            (s) => s.slot == 0,
        orElse: () => throw Exception('Running Slot 0 not found!'),
      );

      final deviceHashHex = runningSlot.hashHex;

      print('📱 Currently Running Firmware');
      print('   Slot:       ${runningSlot.slot}');
      print('   Version:    ${runningSlot.version}');
      print('   Hash:       $deviceHashHex');
      print('   Bootable:   ${runningSlot.bootable}');
      print('   Confirmed:  ${runningSlot.confirmed}');
      print('   Active:     ${runningSlot.active}');
      print('   Permanent:  ${runningSlot.permanent}');

      // =================================================
      // 2. LOAD ALL 3 FIRMWARE FILES
      // =================================================

      print('');
      print('📦 Loading firmware files...');

      const shehmirFile = 'DFU-files/shehmir.bin';
      const zephyrFile = 'DFU-files/zephyr.signed.bin';
      const zephyrBackupFile = 'DFU-files/zephyr.signed(1).bin';

      final shehmirData = await rootBundle.load(shehmirFile);
      final zephyrData = await rootBundle.load(zephyrFile);
      final zephyrBackupData = await rootBundle.load(zephyrBackupFile);
      //
      // final shehmirBytes = Uint8List.fromList(
      //   shehmirData.buffer.asUint8List(
      //     shehmirData.offsetInBytes,
      //     shehmirData.lengthInBytes,
      //   ),
      // );
      //
      // final zephyrBytes = Uint8List.fromList(
      //   zephyrData.buffer.asUint8List(
      //     zephyrData.offsetInBytes,
      //     zephyrData.lengthInBytes,
      //   ),
      // );
      //
      // final zephyrBackupBytes = Uint8List.fromList(
      //   zephyrBackupData.buffer.asUint8List(
      //     zephyrBackupData.offsetInBytes,
      //     zephyrBackupData.lengthInBytes,
      //   ),
      // );

      final shehmirBytes = shehmirData.buffer.asUint8List();
      final zephyrBytes = zephyrData.buffer.asUint8List();
      final zephyrBackupBytes = zephyrBackupData.buffer.asUint8List();



      // =================================================
      // 3. CALCULATE HASHES FOR ALL 3 FILES
      // =================================================

      final shehmirHashHex =
      crypto.sha256.convert(shehmirBytes).toString();

      final zephyrHashHex =
      crypto.sha256.convert(zephyrBytes).toString();

      final zephyrBackupHashHex =
      crypto.sha256.convert(zephyrBackupBytes).toString();

      print('');
      print('🔐 LOCAL FIRMWARE HASHES');
      print('-------------------------------------------------');

      print('📄 $shehmirFile');
      print('   Size: ${shehmirBytes.length} bytes');
      print('   SHA-256: $shehmirHashHex');

      print('');

      print('📄 $zephyrFile');
      print('   Size: ${zephyrBytes.length} bytes');
      print('   SHA-256: $zephyrHashHex');

      print('');

      print('📄 $zephyrBackupFile');
      print('   Size: ${zephyrBackupBytes.length} bytes');
      print('   SHA-256: $zephyrBackupHashHex');

      print('-------------------------------------------------');

      // =================================================
      // 4. DETERMINE WHICH FIRMWARE IS CURRENTLY RUNNING
      // =================================================

      String? currentlyRunningFile;

      if (deviceHashHex == shehmirHashHex) {
        currentlyRunningFile = 'shehmir.bin';
      } else if (deviceHashHex == zephyrHashHex) {
        currentlyRunningFile = 'zephyr.signed.bin';
      } else if (deviceHashHex == zephyrBackupHashHex) {
        currentlyRunningFile = 'zephyr.signed(1).bin';
      }

      print('');
      print('🧠 FIRMWARE MATCH RESULT');

      if (currentlyRunningFile != null) {
        print('✅ Device hash matches: $currentlyRunningFile');
      } else {
        print('⚠️ Device hash does NOT match any local firmware.');
        print('   Device hash: $deviceHashHex');
      }

      // =================================================
      // 5. SELECT ONE OF THE OTHER TWO FIRMWARE FILES
      // =================================================

      Uint8List firmwareToUpload;
      String fileName;

      if (currentlyRunningFile == 'shehmir.bin') {
        // Device has shehmir.bin.
        // Select zephyr.signed.bin for the test.

        firmwareToUpload = zephyrBytes;
        fileName = 'zephyr.signed.bin';

        print('');
        print('🔄 DEVICE HAS: shehmir.bin');
        print('➡️ SELECTING: zephyr.signed.bin');
      } else if (currentlyRunningFile == 'zephyr.signed.bin') {
        // Device has zephyr.signed.bin.
        // Select zephyr.signed(1).bin for the test.

        firmwareToUpload = zephyrBackupBytes;
        fileName = 'zephyr.signed(1).bin';

        print('');
        print('🔄 DEVICE HAS: zephyr.signed.bin');
        print('➡️ SELECTING: zephyr.signed(1).bin');
      } else if (currentlyRunningFile == 'zephyr.signed(1).bin') {
        // Device has zephyr.signed(1).bin.
        // Select shehmir.bin for the test.

        firmwareToUpload = shehmirBytes;
        fileName = 'shehmir.bin';

        print('');
        print('🔄 DEVICE HAS: zephyr.signed(1).bin');
        print('➡️ SELECTING: shehmir.bin');
      } else {
        // Device firmware is unknown.
        // Pick shehmir.bin as the default.

        firmwareToUpload = shehmirBytes;
        fileName = 'shehmir.bin';

        print('');
        print('⚠️ DEVICE FIRMWARE IS UNKNOWN');
        print('➡️ DEFAULTING TO: shehmir.bin');
      }

      // =================================================
      // 6. PRINT FINAL SELECTION DETAILS
      // =================================================

      print('');
      print('=================================================');
      print('🚀 FIRMWARE SELECTED FOR UPLOAD');
      print('=================================================');
      print('📄 File:        $fileName');
      print('📦 Size:        ${firmwareToUpload.length} bytes');
      print(
        '🔐 SHA-256:     ${crypto.sha256.convert(firmwareToUpload)}',
      );
      print(
        '📐 Chunk Size:  ${imgMgmt.steadyChunkSize} bytes',
      );
      print('=================================================');

      // =================================================
      // 7. UPLOAD
      // =================================================

      final List<int> responseSha = await imgMgmt.upload(
        firmwareToUpload,
        onProgress: (int sent, int total) {
          final double progressValue = sent / total;

          onProgress?.call(progressValue);

          if (sent % 5 == 0 || sent == total) {
            print(
              '⏳ Uploading $fileName: '
                  '${(progressValue * 100).toStringAsFixed(1)}%',
            );
          }
        },
      );

      // =================================================
      // 8. FINALIZE AND REBOOT
      // =================================================

      print('');
      print('📦 Upload completed successfully.');
      print(
        '🔐 Uploaded image SHA: '
            '${responseSha.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );

      await finalizeAndReboot(responseSha);

      print('');
      print('=================================================');
      print('✅ FIRMWARE UPDATE COMPLETED');
      print('📄 Firmware: $fileName');
      print('=================================================');
    } catch (e, stackTrace) {
      print('');
      print('❌ FIRMWARE UPDATE FAILED');
      print('Error: $e');
      print(stackTrace);
      rethrow;
    }
  }


  Future<void> firmwareUploadTest() async {
    print('');
    print('=================================================');
    print('🧪 AUTOMATIC FIRMWARE SELECTION & DFU TEST');
    print('=================================================');

    try {
      final imgMgmt = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );

      // =================================================
      // 1. CHECK CURRENT DEVICE FIRMWARE
      // =================================================
      print('');
      print('🔍 Checking current device firmware...');

      final slots = await imgMgmt.list();

      final runningSlot = slots.firstWhere(
            (s) => s.slot == 0,
        orElse: () => throw Exception('Running Slot 0 not found!'),
      );

      // Normalize device hash (MCUboot returns 64-byte/128-hex chars or lower/upper hex)
      final deviceHashHex = runningSlot.hashHex.toLowerCase().trim();

      print('📱 Currently Running Firmware');
      print('   Slot:       ${runningSlot.slot}');
      print('   Version:    ${runningSlot.version}');
      print('   Hash:       $deviceHashHex');
      print('   Bootable:   ${runningSlot.bootable}');
      print('   Confirmed:  ${runningSlot.confirmed}');
      print('   Active:     ${runningSlot.active}');
      print('   Permanent:  ${runningSlot.permanent}');

      // =================================================
      // 2. LOAD ALL 3 FIRMWARE FILES (EXACT BYTE SLICING)
      // =================================================
      print('');
      print('📦 Loading firmware files...');

      const shehmirFile = 'DFU-files/shehmir.bin';
      const zephyrFile = 'DFU-files/zephyr.signed.bin';
      const zephyrBackupFile = 'DFU-files/zephyr.signed(1).bin';

      final shehmirData = await rootBundle.load(shehmirFile);
      final zephyrData = await rootBundle.load(zephyrFile);
      final zephyrBackupData = await rootBundle.load(zephyrBackupFile);

      // Extract exact bytes for each file slice
      final shehmirBytes = shehmirData.buffer.asUint8List(
        shehmirData.offsetInBytes,
        shehmirData.lengthInBytes,
      );
      final zephyrBytes = zephyrData.buffer.asUint8List(
        zephyrData.offsetInBytes,
        zephyrData.lengthInBytes,
      );
      final zephyrBackupBytes = zephyrBackupData.buffer.asUint8List(
        zephyrBackupData.offsetInBytes,
        zephyrBackupData.lengthInBytes,
      );

// =================================================
// 3. CALCULATE LOCAL FIRMWARE HASHES
// =================================================
      final shehmirHashHex = getFirmwareHash(shehmirBytes);
      final zephyrHashHex = getFirmwareHash(zephyrBytes);
      final zephyrBackupHashHex = getFirmwareHash(zephyrBackupBytes);

// =================================================
// 4. DETERMINE WHICH FIRMWARE IS CURRENTLY RUNNING
// =================================================
      String? currentlyRunningFile;

      if (deviceHashHex == shehmirHashHex || deviceHashHex.startsWith(shehmirHashHex)) {
        currentlyRunningFile = 'shehmir.bin';
      } else if (deviceHashHex == zephyrHashHex || deviceHashHex.startsWith(zephyrHashHex)) {
        currentlyRunningFile = 'zephyr.signed.bin';
      } else if (deviceHashHex == zephyrBackupHashHex || deviceHashHex.startsWith(zephyrBackupHashHex)) {
        currentlyRunningFile = 'zephyr.signed(1).bin';
      }

      // =================================================
      // 5. SELECT ONE OF THE OTHER TWO FIRMWARE FILES
      // =================================================
      Uint8List firmwareToUpload;
      String fileName;

      if (currentlyRunningFile == 'shehmir.bin') {
        firmwareToUpload = zephyrBytes;
        fileName = 'zephyr.signed.bin';

        print('');
        print('🔄 DEVICE HAS: shehmir.bin');
        print('➡️ SELECTING: zephyr.signed.bin');
      } else if (currentlyRunningFile == 'zephyr.signed.bin') {
        firmwareToUpload = zephyrBackupBytes;
        fileName = 'zephyr.signed(1).bin';

        print('');
        print('🔄 DEVICE HAS: zephyr.signed.bin');
        print('➡️ SELECTING: zephyr.signed(1).bin');
      } else if (currentlyRunningFile == 'zephyr.signed(1).bin') {
        firmwareToUpload = shehmirBytes;
        fileName = 'shehmir.bin';

        print('');
        print('🔄 DEVICE HAS: zephyr.signed(1).bin');
        print('➡️ SELECTING: shehmir.bin');
      } else {
        firmwareToUpload = shehmirBytes;
        fileName = 'shehmir.bin';

        print('');
        print('⚠️ DEVICE FIRMWARE IS UNKNOWN');
        print('➡️ DEFAULTING TO: shehmir.bin');
      }

      // =================================================
      // 6. PRINT FINAL SELECTION DETAILS
      // =================================================
      print('');
      print('=================================================');
      print('🚀 FIRMWARE SELECTED FOR UPLOAD');
      print('=================================================');
      print('📄 File:        $fileName');
      print('📦 Size:        ${firmwareToUpload.length} bytes');
      print('🔐 SHA-256:     ${crypto.sha256.convert(firmwareToUpload)}');
      print('📐 Chunk Size:  ${imgMgmt.steadyChunkSize} bytes');
      print('=================================================');

      // =================================================
      // 7. UPLOAD
      // =================================================
      final List<int> responseSha = await imgMgmt.upload(
        firmwareToUpload,
        onProgress: (int sent, int total) {
          final double progressValue = sent / total;

          onProgress?.call(progressValue);

          if (sent % 5 == 0 || sent == total) {
            print(
              '⏳ Uploading $fileName: '
                  '${(progressValue * 100).toStringAsFixed(1)}%',
            );
          }
        },
      );

      // =================================================
      // 8. FINALIZE AND REBOOT
      // =================================================
      print('');
      print('📦 Upload completed successfully.');
      print(
        '🔐 Uploaded image SHA: '
            '${responseSha.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );

      await finalizeAndReboot(responseSha);

      print('');
      print('=================================================');
      print('✅ FIRMWARE UPDATE COMPLETED');
      print('📄 Firmware: $fileName');
      print('=================================================');
    } catch (e, stackTrace) {
      print('');
      print('❌ FIRMWARE UPDATE FAILED');
      print('Error: $e');
      print(stackTrace);
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

  Future<void> dispose() async {
    await transport.dispose();
  }

  Future<void> diagnoseFirmwareImages() async {
    print('');
    print('=================================================');
    print('🔎 FIRMWARE IMAGE HASH DIAGNOSTIC');
    print('=================================================');

    try {
      final imgMgmt = ImgMgmt(
        client,
        maxWriteLength: () => transport.maxWriteLength,
      );

      // =================================================
      // 1. GET ALL IMAGES FROM DEVICE
      // =================================================

      print('');
      print('📡 Reading image list from device...');

      final slots = await imgMgmt.list();

      print('');
      print('=================================================');
      print('📱 DEVICE IMAGES');
      print('=================================================');

      if (slots.isEmpty) {
        print('❌ No images returned by device.');
      } else {
        for (final slot in slots) {
          print('');
          print('---------------- IMAGE ----------------');
          print('Image:       ${slot.image}');
          print('Slot:        ${slot.slot}');
          print('Version:     ${slot.version}');
          print('Hash:        ${slot.hashHex}');
          print('Hash length: ${slot.hash.length} bytes');
          print('Bootable:    ${slot.bootable}');
          print('Pending:     ${slot.pending}');
          print('Confirmed:   ${slot.confirmed}');
          print('Active:      ${slot.active}');
          print('Permanent:   ${slot.permanent}');
          print('----------------------------------------');
        }
      }

      // =================================================
      // 2. LOAD THE THREE LOCAL FIRMWARE FILES
      // =================================================

      print('');
      print('=================================================');
      print('📦 LOCAL FIRMWARE FILES');
      print('=================================================');

      const shehmirFile = 'DFU-files/shehmir.bin';
      const zephyrFile = 'DFU-files/zephyr.signed.bin';
      const zephyrBackupFile = 'DFU-files/zephyr.signed(1).bin';

      final shehmirData = await rootBundle.load(shehmirFile);
      final zephyrData = await rootBundle.load(zephyrFile);
      final zephyrBackupData = await rootBundle.load(zephyrBackupFile);

      final shehmirBytes = Uint8List.fromList(
        shehmirData.buffer.asUint8List(
          shehmirData.offsetInBytes,
          shehmirData.lengthInBytes,
        ),
      );

      final zephyrBytes = Uint8List.fromList(
        zephyrData.buffer.asUint8List(
          zephyrData.offsetInBytes,
          zephyrData.lengthInBytes,
        ),
      );

      final zephyrBackupBytes = Uint8List.fromList(
        zephyrBackupData.buffer.asUint8List(
          zephyrBackupData.offsetInBytes,
          zephyrBackupData.lengthInBytes,
        ),
      );

      // =================================================
      // 3. CALCULATE SHA-256
      // =================================================

      final shehmirHash =
      crypto.sha256.convert(shehmirBytes).toString();

      final zephyrHash =
      crypto.sha256.convert(zephyrBytes).toString();

      final zephyrBackupHash =
      crypto.sha256.convert(zephyrBackupBytes).toString();

      print('');
      print('📄 $shehmirFile');
      print('   Size: ${shehmirBytes.length} bytes');
      print('   SHA-256: $shehmirHash');

      print('');
      print('📄 $zephyrFile');
      print('   Size: ${zephyrBytes.length} bytes');
      print('   SHA-256: $zephyrHash');

      print('');
      print('📄 $zephyrBackupFile');
      print('   Size: ${zephyrBackupBytes.length} bytes');
      print('   SHA-256: $zephyrBackupHash');

      // =================================================
      // 4. COMPARE DEVICE HASHES WITH LOCAL FILES
      // =================================================

      print('');
      print('=================================================');
      print('🧠 HASH COMPARISON');
      print('=================================================');

      for (final slot in slots) {
        print('');
        print('📍 Slot ${slot.slot}');
        print('   Device hash: ${slot.hashHex}');

        if (slot.hashHex == shehmirHash) {
          print('   ✅ MATCHES: shehmir.bin');
        } else if (slot.hashHex == zephyrHash) {
          print('   ✅ MATCHES: zephyr.signed.bin');
        } else if (slot.hashHex == zephyrBackupHash) {
          print('   ✅ MATCHES: zephyr.signed(1).bin');
        } else {
          print('   ❌ DOES NOT MATCH any local firmware');
        }
      }

      // =================================================
      // 5. COMPARE THE THREE LOCAL FILES WITH EACH OTHER
      // =================================================

      print('');
      print('=================================================');
      print('🔬 LOCAL FILE COMPARISON');
      print('=================================================');

      print(
        'shehmir.bin == zephyr.signed.bin: '
            '${shehmirHash == zephyrHash}',
      );

      print(
        'shehmir.bin == zephyr.signed(1).bin: '
            '${shehmirHash == zephyrBackupHash}',
      );

      print(
        'zephyr.signed.bin == zephyr.signed(1).bin: '
            '${zephyrHash == zephyrBackupHash}',
      );

      print('');
      print('=================================================');
      print('🏁 DIAGNOSTIC COMPLETE');
      print('=================================================');
    } catch (e, stackTrace) {
      print('');
      print('❌ DIAGNOSTIC FAILED');
      print('Error: $e');
      print(stackTrace);
    }
  }

  String getFirmwareHash(Uint8List binBytes) {
    if (binBytes.length < 32) {
      return crypto.sha256.convert(binBytes).toString().toLowerCase();
    }

    final byteData = ByteData.sublistView(binBytes);
    final magic = byteData.getUint32(0, Endian.little);

    // MCUboot Header Magic: 0x96f3b83d
    if (magic != 0x96f3b83d) {
      return crypto.sha256.convert(binBytes).toString().toLowerCase();
    }

    final hdrSize = byteData.getUint16(8, Endian.little);
    final imgSize = byteData.getUint32(12, Endian.little);
    final flags = byteData.getUint32(16, Endian.little);

    // TLV area starts right after (header + payload)
    int tlvOffset = hdrSize + imgSize;

    // Align offset to 8-byte boundary if needed by target arch
    if (tlvOffset % 8 != 0) {
      tlvOffset += (8 - (tlvOffset % 8));
    }

    if (tlvOffset + 4 > binBytes.length) {
      return crypto.sha256.convert(binBytes).toString().toLowerCase();
    }

    int currentOffset = tlvOffset;

    // Loop through TLV headers (handles Protected TLV 0x6908 and Main TLV 0x6907)
    while (currentOffset + 4 <= binBytes.length) {
      final tlvMagic = byteData.getUint16(currentOffset, Endian.little);
      final tlvAreaLen = byteData.getUint16(currentOffset + 2, Endian.little);

      if (tlvMagic != 0x6907 && tlvMagic != 0x6908) {
        // If alignment offset was wrong, try unaligned offset once
        if (currentOffset == tlvOffset && (hdrSize + imgSize) + 4 <= binBytes.length) {
          currentOffset = hdrSize + imgSize;
          continue;
        }
        break;
      }

      int entryOffset = currentOffset + 4;
      int endEntryOffset = currentOffset + tlvAreaLen;

      while (entryOffset + 4 <= endEntryOffset && entryOffset + 4 <= binBytes.length) {
        final type = byteData.getUint16(entryOffset, Endian.little);
        final len = byteData.getUint16(entryOffset + 2, Endian.little);
        entryOffset += 4;

        // 0x10 = SHA256 (32 bytes), 0x12 = SHA512 (64 bytes)
        if ((type == 0x10 || type == 0x12) && entryOffset + len <= binBytes.length) {
          final hashBytes = binBytes.sublist(entryOffset, entryOffset + len);
          return hashBytes
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join()
              .toLowerCase();
        }
        entryOffset += len;
      }

      // Move past this TLV section to check for next TLV block
      currentOffset += tlvAreaLen;
    }

    // Fallback if TLV parser didn't find hash entry
    return crypto.sha256.convert(binBytes).toString().toLowerCase();
  }


}
