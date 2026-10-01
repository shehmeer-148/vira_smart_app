import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mcumgr_dart/mcumgr_dart.dart';
import 'package:http/http.dart' as http;


class SmpBleTransport implements SmpTransport {
  SmpBleTransport({
    required this.ble,
    required this.deviceId,
  });

  final FlutterReactiveBle ble;
  final String deviceId;

  static final Uuid smpServiceUuid =
  Uuid.parse('8d53dc1d-1db7-4cd3-868b-8a527460aa84');

  static final Uuid smpCharacteristicUuid =
  Uuid.parse('da2e7828-fbce-4e01-ae9e-261174997c48');

  final StreamController<Uint8List> _notificationController =
  StreamController<Uint8List>.broadcast();

  final StreamController<SmpConnectionState> _stateController =
  StreamController<SmpConnectionState>.broadcast();

  StreamSubscription<List<int>>? _notificationSubscription;

  SmpConnectionState _state = SmpConnectionState.disconnected;

  @override
  String? get deviceLabel => deviceId;

  @override
  SmpConnectionState get state => _state;

  @override
  Stream<SmpConnectionState> get stateChanges =>
      _stateController.stream;

  @override
  Stream<Uint8List> get notifications =>
      _notificationController.stream;

  @override
  int? get maxWriteLength => 244;

  QualifiedCharacteristic get _smpCharacteristic {
    return QualifiedCharacteristic(
      serviceId: smpServiceUuid,
      characteristicId: smpCharacteristicUuid,
      deviceId: deviceId,
    );
  }

  @override
  Future<void> connect() async {
    print('📡 SMP transport connecting...');

    _state = SmpConnectionState.connecting;
    _stateController.add(_state);

    await _notificationSubscription?.cancel();

    print('📡 About to subscribe to SMP characteristic...');

    _notificationSubscription =
        ble.subscribeToCharacteristic(_smpCharacteristic).listen(
              (data) {
            print(
              '📥 SMP RX: '
                  '${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}',
            );

            _notificationController.add(
              Uint8List.fromList(data),
            );
          },
          onError: (error) {
            print('❌ SMP notification error: $error');
          },
        );

    print('📡 SMP subscription created');
    await checkMtu();
  }

  @override
  Future<void> write(Uint8List frame) async {
    print('');
    print('📤 SMP WRITE');
    print('   Frame size: ${frame.length} bytes');
    print(
      '   First bytes: '
          '${frame.take(16).map(
            (e) => e.toRadixString(16).padLeft(2, '0'),
      ).join(' ')}',
    );

    await ble.writeCharacteristicWithoutResponse(
      _smpCharacteristic,
      value: frame,
    );

    print('   ✅ BLE write completed');
  }

  @override
  Future<void> disconnect() async {
    print('🔌 SMP transport disconnecting...');

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    _state = SmpConnectionState.disconnected;
    _stateController.add(_state);
  }

  Future<void> dispose() async {
    await disconnect();

    await _notificationController.close();
    await _stateController.close();
  }
  Future<void> checkMtu() async {
    try {
      final mtu = await ble.requestMtu(
        deviceId: deviceId,
        mtu: 247,
      );

      print('📏 Negotiated BLE MTU: $mtu');
      print('📏 Maximum ATT payload: ${mtu - 3} bytes');
    } catch (e) {
      print('❌ MTU request failed: $e');
    }
  }

  /////////////////////////////////////////////////////////////////

}


// class FirmwareService {
//   static const String latestReleaseUrl =
//       'https://api.github.com/repos/Hamas888/Planter/releases/latest';
//
//   Future<String?> getLatestVersion() async {
//     try {
//       print('========================================');
//       print('GITHUB FIRMWARE CHECK STARTED');
//       print('URL: $latestReleaseUrl');
//
//       final response = await http.get(
//         Uri.parse(latestReleaseUrl),
//         headers: {
//           'Authorization': 'Bearer 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',
//           'Accept': 'application/vnd.github+json',
//         },
//       );
//
//
//       print('GitHub response status: ${response.statusCode}');
//       print('GitHub response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         print('GitHub request successful');
//
//         final data = jsonDecode(response.body);
//
//         print('Release tag: ${data['tag_name']}');
//         print('Release name: ${data['name']}');
//
//         final tagName = data['tag_name'] as String?;
//
//         if (tagName == null) {
//           print('ERROR: tag_name is missing');
//           return null;
//         }
//
//         final version = tagName.replaceFirst('v', '');
//
//         print('Latest firmware version: $version');
//
//         // Let's inspect the assets too, but we won't download anything yet.
//         final assets = data['assets'] as List<dynamic>?;
//
//         print('Number of assets: ${assets?.length ?? 0}');
//
//         if (assets != null) {
//           for (final asset in assets) {
//             print('Asset name: ${asset['name']}');
//             print('Asset ID: ${asset['id']}');
//           }
//         }
//
//         print('GITHUB FIRMWARE CHECK COMPLETED');
//         print('========================================');
//
//         return version;
//       }
//
//       print('ERROR: GitHub request failed');
//       print('Status code: ${response.statusCode}');
//       print('Response: ${response.body}');
//       print('========================================');
//
//       return null;
//     } catch (e) {
//       print('ERROR: GitHub request exception');
//       print('Exception: $e');
//       print('========================================');
//
//       return null;
//     }
//   }
// }

class FirmwareService {
  static const String latestReleaseUrl =
      'https://api.github.com/repos/Hamas888/Planter/releases/latest';

  static const String githubToken = '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';

  // STEP 1:
  // Get latest release and find the firmware asset ID.
  Future<int?> getLatestAssetId() async {
    try {
      print('========================================');
      print('GITHUB RELEASE CHECK STARTED');
      print('URL: $latestReleaseUrl');

      final response = await http.get(
        Uri.parse(latestReleaseUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/vnd.github+json',
        },
      );

      print('GitHub response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('ERROR: GitHub request failed');
        print('Response: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body);

      print('GitHub request successful');
      print('Release tag: ${data['tag_name']}');
      print('Release name: ${data['name']}');

      final assets = data['assets'] as List<dynamic>?;

      if (assets == null || assets.isEmpty) {
        print('ERROR: No assets found in release');
        return null;
      }

      // Find the .bin firmware asset
      for (final asset in assets) {
        final assetName = asset['name'] as String?;

        print('Asset name: $assetName');
        print('Asset ID: ${asset['id']}');

        if (assetName != null && assetName.endsWith('.bin')) {
          final assetId = asset['id'] as int;

          print('Firmware asset found!');
          print('Firmware asset ID: $assetId');
          print('========================================');

          return assetId;
        }
      }

      print('ERROR: No .bin firmware asset found');
      print('========================================');

      return null;
    } catch (e) {
      print('ERROR: GitHub release exception');
      print('Exception: $e');
      print('========================================');

      return null;
    }
  }

  // STEP 2:
  // Download the actual firmware using the asset ID.
  Future<List<int>?> downloadFirmware(int assetId) async {
    final downloadUrl =
        'https://api.github.com/repos/Hamas888/Planter/releases/assets/$assetId';

    try {
      print('========================================');
      print('FIRMWARE DOWNLOAD STARTED');
      print('Asset ID: $assetId');
      print('URL: $downloadUrl');

      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $githubToken',
          'Accept': 'application/octet-stream',
        },
      );

      print('Download response status: ${response.statusCode}');
      print('Downloaded bytes: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        print('FIRMWARE DOWNLOAD SUCCESSFUL');
        print('Firmware size: ${response.bodyBytes.length} bytes');
        print('========================================');

        return response.bodyBytes;
      }

      print('ERROR: Firmware download failed');
      print('Status code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('========================================');

      return null;
    } catch (e) {
      print('ERROR: Firmware download exception');
      print('Exception: $e');
      print('========================================');

      return null;
    }
  }
}
