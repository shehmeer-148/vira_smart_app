import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mcumgr_dart/mcumgr_dart.dart';

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
}