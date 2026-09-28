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
  });

  final FlutterReactiveBle ble;
  final String deviceId;

  late final SmpBleTransport transport;
  late final SmpClient client;

  Future<void> start() async {
    transport = SmpBleTransport(
      ble: ble,
      deviceId: deviceId,
    );

    client = SmpClient(transport);

    await transport.connect();

    print('✅ SmpClient created and transport connected');

    await echoTest();
    await imageStateTest();
    await imageStateTest1();
    await firmwareFileTest();
    await firmwareUploadTest();
  }
  Future<void> echoTest() async {
    final os = OsMgmt(client);

    print('');
    print('================ SMP ECHO TEST ================');

    try {
      // Using the native OsMgmt helper class
      final response = await os.echo('hello');

      print('✅ SMP Echo succeeded');
      print('Response: $response');
    } catch (e, stackTrace) {
      print('❌ SMP Echo failed');
      print('Error: $e');
      print(stackTrace);
    }
  }
  Future<void> imageStateTest1() async {
    final img = ImgMgmt(
      client,
      maxWriteLength: () => transport.maxWriteLength,
    );

    print('');
    print('================ IMAGE STATE TEST ================');

    try {
      final response = await img.list();

      print('✅ Image State succeeded');
      print('Found ${response.length} slots:');

      for (final image in response) {
        print(
          '📸 Image: ${image.image} | '
              'Slot: ${image.slot} | '
              'Version: ${image.version} | '
              'Active: ${image.active} | '
              'Confirmed: ${image.confirmed} | '
              'Pending: ${image.pending} | '
              'Bootable: ${image.bootable}',
        );
        print('      Hash: ${image.hashHex}');
      }
    } catch (e, stackTrace) {
      print('❌ Image State failed');
      print('Error: $e');
      print(stackTrace);
    }
  }
  Future<void> firmwareFileTest() async {
    print('');
    print('================ FIRMWARE FILE TEST ================');

    try {
      // Updated to load the actual distinct binary file
      final ByteData data = await rootBundle.load('DFU-files/demo.bin');

      final Uint8List firmware = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      print('✅ demo.bin loaded successfully');
      print('📦 Firmware size: ${firmware.length} bytes');
      print('🔢 First bytes: ${firmware.take(16).toList()}');
    } catch (e) {
      print('❌ Failed to load firmware file: $e');
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
        print('🎉 SUCCESS! Firmware update is permanent and will not roll back on power cycles.');
      } else {
        print('⚠️ Could not identify active Slot 0 context.');
      }
    } catch (e, stackTrace) {
      print('❌ Permanent confirmation failed');
      print('Error: $e');
      print(stackTrace);
    }
  }


///////////////////////////////////////////////////////////

  Future<void> firmwareUploadTest() async {
    print('');
    print('=================================================');
    print('🧪 FIRMWARE IMAGE UPLOAD VIA IMGMGMT');
    print('=================================================');

    try {
      // 1. Load the firmware binary file completely
      final data = await rootBundle.load('DFU-files/demo.bin');
      final firmware = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );

      print('📦 Loaded Firmware: ${firmware.length} bytes');

      // 2. Instantiate the high-level Image Management handler
      final imgMgmt = ImgMgmt(client);

      print('📤 Starting firmware upload...');

      // 3. Run the upload natively.
      // mcumgr_dart automatically chunks the binary, updates offsets,
      // applies proper CBOR byte string tags, and returns the final SHA hash.
      final List<int> responseSha = await imgMgmt.upload(
        firmware,
        onProgress: (int sent, int total) {
          final double percentage = (sent / total) * 100;
          print('⏳ Upload Progress: ${percentage.toStringAsFixed(1)}% ($sent/$total bytes)');
        },
      );

      await finalizeAndReboot(responseSha);
      // Convert response hash to a hex string for confirmation
      final hexSha = responseSha.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      print('');
      print('=================================================');
      print('✅ FIRMWARE UPLOAD COMPLETED');
      print('=================================================');
      print('Device confirmed SHA-256: $hexSha');
      print('=================================================');

    } catch (e, stackTrace) {
      print('');
      print('=================================================');
      print('❌ UPLOAD FAILED');
      print('=================================================');
      print('Error: $e');
      print('');
      print(stackTrace);
      print('=================================================');
    }
  }
  Future<void> finalizeAndReboot(List<int> localSha) async {
    print('=================================================');
    print('🔄 FINALIZING DFU AND REBOOTING DEVICE');
    print('=================================================');

    try {
      final imgMgmt = ImgMgmt(client);

      print('Reading image slot list from device...');
      final slots = await imgMgmt.list();
      print('Slots found: ${slots.length}');

      // Find Slot 1 (the newly uploaded image)
      ImageSlot? secondarySlot;
      for (var slot in slots) {
        print(' Slot ${slot.slot}: Hash=${slot.hashHex}, Active=${slot.active}');
        if (slot.slot == 1) {
          secondarySlot = slot;
        }
      }

      if (secondarySlot == null || secondarySlot.hash.isEmpty) {
        throw Exception('Secondary slot (Slot 1) is empty! Upload failed or rejected.');
      }

      // 🌟 THE FIX: Use the exact hash the chip read into its flash memory!
      final Uint8List flashHash = secondarySlot.hash;
      print('Testing new firmware image using its actual flash hash: ${secondarySlot.hashHex}');

      await imgMgmt.test(flashHash);
      print('✅ Image successfully marked for boot test!');

      // Trigger Reset
      print('Sending reset command to nRF device...');
      final osMgmt = OsMgmt(client);
      await osMgmt.reset();
      print('🚀 Reset command sent! The device will reboot.');

    } catch (e, stackTrace) {
      print('❌ FINALIZATION FAILED');
      print('Error: $e');
      print(stackTrace);

      try {
        print('Attempting direct reset fallback...');
        final osMgmt = OsMgmt(client);
        await osMgmt.reset();
      } catch (_) {}
    }
  }

  Future<void> imageStateTest() async {
    final img = ImgMgmt(
      client,
      maxWriteLength: () => transport.maxWriteLength,
    );

    print('');
    print('================ IMAGE STATE CHECK ================');

    try {
      // Read the active slot table directly from the nRF chip's memory
      final response = await img.list();

      print('✅ Image State successfully fetched');

      for (final image in response) {
        print(
          '📸 Slot: ${image.slot} | '
              'Version: ${image.version} | '
              'Active: ${image.active} | '
              '👀 CONfIRMED: ${image.confirmed} | ' // 🌟 WATCH THIS VALUE
              'Pending: ${image.pending}',
        );
        print('   Hash Hex: ${image.hashHex}');
      }
      print('==================================================');

    } catch (e, stackTrace) {
      print('❌ Image State check failed');
      print('Error: $e');
      print(stackTrace);
    }
  }



}