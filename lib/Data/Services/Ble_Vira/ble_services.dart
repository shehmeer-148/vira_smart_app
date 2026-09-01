import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../../Core/enums.dart';
import 'ble_constants.dart';
import 'ble_helper.dart';
import 'ble_commands.dart';
import 'ble_parser.dart';
import 'ble_encoder.dart';

class BleService {

  final FlutterReactiveBle ble = FlutterReactiveBle();


  //* ================== READ ======================= *//
  Future<List<int>> read({
    required String deviceId,
    required Uuid service,
    required Uuid characteristic,
  }) async {

    final qualified = BleHelper.characteristic(
      deviceId: deviceId,
      service: service,
      characteristic: characteristic,
    );

    return await ble.readCharacteristic(qualified);
  }

  Future<String> readPlantName(String deviceId) async {

    final bytes = await read(
        deviceId: deviceId,
        service: BleConstants.serviceConfig,
        characteristic: BleConstants.plantName,
    );
    return BleParser.parseString(bytes);

  }
  Future<int> readPlantType(String deviceId) async {

    final bytes = await read(
        deviceId: deviceId,
        service: BleConstants.serviceConfig,
        characteristic: BleConstants.plantType,
    );
    return BleParser.parseUint16(bytes);

  }
  Future<BleSchedule> readSchedule(
      String deviceId,
      ) async {

    print("");
    print("==============================================");
    print("📖 BLE SERVICE - READ SCHEDULE");
    print("==============================================");

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.schedule,
    );

    print("📥 RAW SCHEDULE BYTES: $bytes");
    print("📏 BYTE LENGTH: ${bytes.length}");

    // TEMPORARY:
    // Do NOT parse yet because we are testing
    // what Vira actually returns.

    return BleParser.parseSchedule(bytes);
  }
  Future<int> readWaterDuration(String deviceId) async {

    print("");
    print("==============================================");
    print("📖 BLE SERVICE - READ WATER DURATION");
    print("==============================================");

    print("Device ID      : $deviceId");
    print("Service        : ${BleConstants.serviceConfig}");
    print("Characteristic : ${BleConstants.waterDuration}");

    print("");
    print("➡️ Reading water duration from Vira...");

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.waterDuration,
    );

    print("⬅️ Raw Water Duration Bytes : $bytes");

    final duration = BleParser.parseUint16(bytes);

    print("💧 Parsed Water Duration    : $duration seconds");

    print("==============================================");

    return duration;
  }


  Future<int> readBatteryLevel(String deviceId) async {

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.battery,
    );
    return BleParser.parseUint8(bytes);

  }
  Future<int> readLastWatered(String deviceId) async {

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.lastWatered,
    );
    return BleParser.parseUint32(bytes);

  }
  Future<int> readCycleCount(String deviceId) async {

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.cycleCount,
    );
    return BleParser.parseUint32(bytes);

  }
  Future<TankStatus> readTankStatus(String deviceId) async {
    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.tankStatus,
    );

    return BleParser.parseTankStatus(bytes);
  }
  Future<String> readDeviceUuid(String deviceId) async {
    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.deviceUuid,
    );

    return BleParser.parseUuid(bytes);
  }
  Future<String> readFirmwareVersion(String deviceId) async {
    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.firmwareVersion,
    );

    return BleParser.parseFirmwareVersion(bytes);
  }
  Future<LowBatteryFlag> readLowBatteryFlag(String deviceId) async {
    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.lowBatteryFlag,
    );

    return BleParser.parseLowBatteryFlag(bytes);
  }

  //* ================== WRITE =================== *//
  Future<void> write({
    required String deviceId,
    required Uuid service,
    required Uuid characteristic,
    required List<int> value,
  }) async {

    final qualified = BleHelper.characteristic(
      deviceId: deviceId,
      service: service,
      characteristic: characteristic,
    );

    await ble.writeCharacteristicWithResponse(
      qualified,
      value: value,
    );
  }

  Future<void> writePlantName(
      String deviceId,
      String name,
      ) async {

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.plantName,
      value: BleEncoder.string(name),
    );
  }
  Future<void> writePlantType(
      String deviceId,
      int type,
      ) async {

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.plantType,
      value: BleEncoder.uint16(type),
    );
  }
  Future<void> waterNow(String deviceId) async {
    await write(
        deviceId: deviceId,
        service: BleConstants.serviceConfig,
        characteristic: BleConstants.controlPoint,
        value: BleEncoder.uint8(BleCommands.waterNow),
    );

  }
  Future<void> writeWaterDuration(
      String deviceId,
      int seconds,
      ) async {

    print("Schedule data comes from user for water duration:=========== $seconds ");
    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.waterDuration,
      value: BleEncoder.uint16(seconds),
    );
  }
  Future<void> syncRtc(
      String deviceId,
      int unixTime,
      ) async {

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.rtcSync,
      value: BleEncoder.uint32(unixTime),
    );
  }
  Future<void> writeScheduleConfig(
      String deviceId, {
        required int daysMask,
        required int timeMinutes,
        required int wateringsPerDay,
      }) async {
    print("Schedule data comes from user is:=============== ");
    print("DaysMask is:======   $daysMask");
    print("Time Minute is:======   $timeMinutes");
    print("Watering Per Day is:======   $wateringsPerDay");
    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.schedule,
      value: BleEncoder.scheduleConfig(
        daysMask: daysMask,
        timeMinutes: timeMinutes,
        wateringsPerDay: wateringsPerDay,
      ),
    );
  }

  //* ================ NOTIFY =================== *//
  Stream<List<int>> notify({
    required String deviceId,
    required Uuid service,
    required Uuid characteristic,
  }) {
    final qualified = BleHelper.characteristic(
      deviceId: deviceId,
      service: service,
      characteristic: characteristic,
    );

    return ble.subscribeToCharacteristic(
      qualified,
    );
  }

  Stream<int> batteryStream(String deviceId) {
    return notify(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.battery,
    ).map(BleParser.parseUint8);
  }
  Stream<TankStatus> tankStatusStream(String deviceId) {
    return notify(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.tankStatus,
    ).map(BleParser.parseTankStatus);
  }
  Stream<LowBatteryFlag> lowBatteryFlagStream(String deviceId) {
    return notify(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.lowBatteryFlag,
    ).map(BleParser.parseLowBatteryFlag);
  }

  //* ================ FACTORY RESET =================== *//
  Future<void> factoryReset(String deviceId) async {

    final characteristic = BleHelper.characteristic(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.controlPoint,
    );

    await ble.writeCharacteristicWithResponse(
      characteristic,
      value: BleEncoder.uint8(
        BleCommands.factoryReset,
      ),
    );
  }

  //* ================= SETUP DONE ==================== *//
  Future<void> setupDone(String deviceId) async {

    final characteristic = BleHelper.characteristic(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.controlPoint,
    );

    await ble.writeCharacteristicWithResponse(
      characteristic,
      value: BleEncoder.uint8(
        BleCommands.setupDone,
      ),
    );
  }

  //* =================== SCAN CONNECT STATUS Streams ============*//
  Stream<DiscoveredDevice> scan() {
    return ble.scanForDevices(
      withServices: [
        BleConstants.serviceStatus,
        Uuid.parse("0000ffc0"),

      ],
      scanMode: ScanMode.lowLatency,
    );
  }
  Stream<ConnectionStateUpdate> connect(
      DiscoveredDevice device,
      ) {

    print("================================");
    print("BleService.connect()");
    print("Device Name : ${device.name}");
    print("Device Id   : ${device.id}");
    print("RSSI            : ${device.rssi} dBm");

    print("================================");

    print("");
    print(" ADVERTISEMENT DATA");

    print("Service UUIDs   : ${device.serviceUuids}");
    print("Manufacturer    : ${device.manufacturerData}");
    print("Service Data    : ${device.serviceData}");
    print("Connectable     : ${device.connectable}");

    return ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(
        seconds: 10,
      ),
    );
  }
  Stream<BleStatus> getStatusStream() {
    return ble.statusStream;
  }
}