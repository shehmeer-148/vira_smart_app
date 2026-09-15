import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../../../Core/enums.dart';
import '../../../Core/plant_library.dart';
import '../../Model_classes/pot_model.dart';
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
    print("📥 RAW PLANT NAME BYTES: $bytes");
    print("📏 PLANT NAME BYTE LENGTH: ${bytes.length}");

    final name = BleParser.parseString(bytes);

    print("🌱 PARSED PLANT NAME: $name");
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
  Future<int> readScheduleDaysMask(String deviceId) async {

    print("");
    print("==============================================");
    print("📖 BLE SERVICE - READ SCHEDULE DAYS MASK");
    print("==============================================");

    print("Device ID      : $deviceId");
    print("Service        : ${BleConstants.serviceConfig}");
    print("Characteristic : ${BleConstants.daysMask}");

    print("");
    print("➡️ Reading schedule days mask from Vira...");

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.daysMask,
    );

    print("⬅️ Raw Days Mask Bytes : $bytes");

    if (bytes.length != 1) {
      throw Exception(
        "Invalid Days Mask length. Expected 1 byte, got ${bytes.length}",
      );
    }

    final daysMask = bytes[0];

    print("📅 Parsed Days Mask    : $daysMask");
    print(
      "📅 Days Binary         : "
          "${daysMask.toRadixString(2).padLeft(8, '0')}",
    );

    print("==============================================");

    return daysMask;
  }
  Future<int> readScheduleTime(String deviceId) async {

    print("");
    print("==============================================");
    print("📖 BLE SERVICE - READ SCHEDULE TIME");
    print("==============================================");

    print("Device ID      : $deviceId");
    print("Service        : ${BleConstants.serviceConfig}");
    print("Characteristic : ${BleConstants.schedule}");

    print("");
    print("➡️ Reading schedule time from Vira...");

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.schedule,
    );

    print("⬅️ Raw Schedule Time Bytes : $bytes");

    final timeMinutes = BleParser.parseUint16(bytes);

    print("⏰ Parsed Time Minutes     : $timeMinutes");
    print("⏰ Hour                    : ${timeMinutes ~/ 60}");
    print("⏰ Minute                  : ${timeMinutes % 60}");

    print("==============================================");

    return timeMinutes;
  }
  Future<PotModel?> readCurrentPot(String deviceId) async {
    try {
      print("");
      print("==================================================");
      print("📖 BLE SERVICE - READING CURRENT POT");
      print("Device : $deviceId");
      print("==================================================");

      //==================================================
      // 1. PLANT NAME
      //==================================================

      print("");
      print("1️⃣ Reading Plant Name...");

      final plantName =
      await readPlantName(deviceId);

      print("✅ Plant Name: $plantName");


      //==================================================
      // 2. PLANT TYPE
      //==================================================

      print("");
      print("2️⃣ Reading Plant Type...");

      final plantType =
      await readPlantType(deviceId);

      print("✅ Plant Type: $plantType");


      //==================================================
      // 3. DAYS MASK
      //==================================================

      print("");
      print("3️⃣ Reading Schedule Days Mask...");

      final daysMask =
      await readScheduleDaysMask(deviceId);

      print("✅ Days Mask: $daysMask");


      //==================================================
      // 4. SCHEDULE TIME
      //==================================================

      print("");
      print("4️⃣ Reading Schedule Time...");

      final timeMinutes =
      await readScheduleTime(deviceId);

      print("✅ Time Minutes: $timeMinutes");


      //==================================================
      // 5. WATER DURATION
      //==================================================

      print("");
      print("5️⃣ Reading Water Duration...");

      final waterDuration =
      await readWaterDuration(deviceId);

      print("✅ Water Duration: $waterDuration seconds");


      //==================================================
      // 6. BATTERY
      //==================================================

      print("");
      print("6️⃣ Reading Battery Level...");

      final batteryLevel =
      await readBatteryLevel(deviceId);

      print("✅ Battery: $batteryLevel%");


      //==================================================
      // 7. LAST WATERED
      //==================================================

      print("");
      print("7️⃣ Reading Last Watered...");

      final lastWatered =
      await readLastWatered(deviceId);

      print("✅ Last Watered: $lastWatered");


      //==================================================
      // 8. CYCLE COUNT
      //==================================================

      print("");
      print("8️⃣ Reading Cycle Count...");

      final cycleCount =
      await readCycleCount(deviceId);

      print("✅ Cycle Count: $cycleCount");


      //==================================================
      // 9. TANK STATUS
      //==================================================

      print("");
      print("9️⃣ Reading Tank Status...");

      final tankStatus =
      await readTankStatus(deviceId);

      print("✅ Tank Status: ${tankStatus.name}");


      //==================================================
      // 10. DEVICE UUID
      //==================================================

      print("");
      print("🔟 Reading Device UUID...");

      final deviceUuid =
      await readDeviceUuid(deviceId);

      print("✅ Device UUID: $deviceUuid");


      //==================================================
      // 11. FIRMWARE
      //==================================================

      print("");
      print("1️⃣1️⃣ Reading Firmware Version...");

      final firmware =
      await readFirmwareVersion(deviceId);

      print("✅ Firmware: $firmware");


      //==================================================
      // 12. LOW BATTERY FLAG
      //==================================================

      print("");
      print("1️⃣2️⃣ Reading Low Battery Flag...");

      final lowBattery =
      await readLowBatteryFlag(deviceId);

      print("✅ Low Battery: ${lowBattery.name}");


      //==================================================
      // PLANT LIBRARY
      //==================================================

      final libraryPlant =
      PlantLibrary.getById(plantType);


      //==================================================
      // FINAL DATA
      //==================================================

      print("");
      print("==================================================");
      print("📦 RAW DATA RECEIVED FROM VIRA POT");
      print("==================================================");

      print("🪴 Plant Name       : $plantName");
      print("🪴 Plant Type       : $plantType");

      print("");

      print("📅 Schedule");
      print("   Days Mask        : $daysMask");
      print("   Time Minutes     : $timeMinutes");
      print("   Water Duration   : $waterDuration sec");

      print("");

      print("📊 Status");
      print("   Battery          : $batteryLevel%");
      print("   Last Watered     : $lastWatered");
      print("   Cycle Count      : $cycleCount");
      print("   Tank Status      : ${tankStatus.name}");
      print("   Low Battery      : ${lowBattery.name}");

      print("");

      print("🔧 Device");
      print("   Device UUID      : $deviceUuid");
      print("   Firmware         : $firmware");

      print("");

      print("📚 Plant Library");
      print("   Image            : ${libraryPlant?.image}");
      print("   Category         : ${libraryPlant?.category}");
      print("   Water Interval   : ${libraryPlant?.wateringIntervalDays}");

      print("==================================================");


      //==================================================
      // CREATE POT MODEL
      //==================================================

      final pot = PotModel(
        deviceId: deviceId,

        //---------------- Plant ----------------//

        plantType: plantType,
        plantName: plantName,
        plantImage: libraryPlant?.image ?? "",
        wateringIntervalDays:
        libraryPlant?.wateringIntervalDays ?? 0,

        //---------------- Schedule ----------------//

        daysMask: daysMask,
        timeMinutes: timeMinutes,

        // Temporarily removed from Vira hardware
        wateringsPerDay: 0,

        waterDuration: waterDuration,

        //---------------- Status ----------------//

        batteryLevel: batteryLevel,
        tankStatus: tankStatus.index,
        lastWatered: lastWatered,
        cycleCount: cycleCount,
        firmwareVersion: firmware,
        lowBattery: lowBattery == LowBatteryFlag.low,

        //---------------- App ----------------//

        pairedAt: 0,
        lastSynced:
        DateTime.now().millisecondsSinceEpoch,
      );


      //==================================================
      // FINAL RESULT
      //==================================================

      print("");
      print("==================================================");
      print("🧱 POT MODEL CREATED BY BLE SERVICE");
      print("==================================================");
      print(pot);
      print("==================================================");

      return pot;

    } catch (e, stack) {

      print("");
      print("==================================================");
      print("❌ BLE SERVICE - READ CURRENT POT FAILED");
      print("==================================================");

      print("Device: $deviceId");
      print("Error: $e");

      print("");
      print("Stack Trace:");
      print(stack);

      print("==================================================");

      return null;
    }
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

    print("");
    print("==============================================");
    print("📖 BLE SERVICE - READ DEVICE UUID");
    print("==============================================");

    print("Device ID      : $deviceId");
    print("Service        : ${BleConstants.serviceStatus}");
    print("Characteristic : ${BleConstants.deviceUuid}");

    print("");
    print("➡️ Reading Device UUID from Vira...");

    final bytes = await read(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.deviceUuid,
    );

    print("⬅️ Raw Device UUID Bytes : $bytes");
    print("📏 BYTE LENGTH           : ${bytes.length}");

   // final uuid = BleParser.parseUuid(bytes);
    final uuid = BleParser.parseDeviceUuid(bytes);

    print("🔑 Parsed Device UUID    : $uuid");

    print("==============================================");

    return uuid;
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
    final nameWithSpace = '$name ';
    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.plantName,
      value: BleEncoder.string(nameWithSpace),
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
  Future<void> writeWaterDurationOld(
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
  Future<void> writeScheduleDaysMask(
      String deviceId,
      int daysMask,
      ) async {
    print("📤 Writing Days Mask: $daysMask");

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.daysMask,
      value: [daysMask],
    );
  }
  Future<void> writeScheduleTime(
      String deviceId,
      int timeMinutes,
      ) async {
    print("📤 Writing Time Minutes: $timeMinutes");

    final bytes = [
      timeMinutes & 0xFF,
      (timeMinutes >> 8) & 0xFF,
    ];

    print("📤 Time Bytes: $bytes");

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.schedule,
      value: bytes,
    );
  }
  Future<void> writeWaterDuration(
      String deviceId,
      int waterDuration,
      ) async {
    print("📤 Writing Water Duration: $waterDuration");

    final bytes = [
      waterDuration & 0xFF,
      (waterDuration >> 8) & 0xFF,
    ];

    print("📤 Duration Bytes: $bytes");

    await write(
      deviceId: deviceId,
      service: BleConstants.serviceConfig,
      characteristic: BleConstants.waterDuration,
      value: bytes,
    );
  }

  //* ================ NOTIFY =================== *//
  // Stream<List<int>> notify({
  //   required String deviceId,
  //   required Uuid service,
  //   required Uuid characteristic,
  // }) {
  //   final qualified = BleHelper.characteristic(
  //     deviceId: deviceId,
  //     service: service,
  //     characteristic: characteristic,
  //   );
  //
  //   return ble.subscribeToCharacteristic(
  //     qualified,
  //   );
  // }

  // Stream<int> batteryStream(String deviceId) {
  //   return notify(
  //     deviceId: deviceId,
  //     service: BleConstants.serviceStatus,
  //     characteristic: BleConstants.battery,
  //   ).map(BleParser.parseUint8);
  // }
  /// BLE NOTIFICATION
  Stream<int> batteryStream(String deviceId) {

    print("");
    print("🔋 Creating battery stream...");
    print("📱 Device: $deviceId");
    print("🔧 Battery Characteristic: ${BleConstants.battery}");

    return notify(
      deviceId: deviceId,
      service: BleConstants.serviceStatus,
      characteristic: BleConstants.battery,
    ).map((bytes) {

      print("🔋 Parsing battery bytes...");
      print("🔋 Raw bytes: $bytes");

      final battery = BleParser.parseUint8(bytes);

      print("🔋 Parsed battery: $battery%");

      return battery;
    });
  }
  Stream<List<int>> notify({
    required String deviceId,
    required Uuid service,
    required Uuid characteristic,
  }) {

    print("");
    print("==================================================");
    print("🔔 SUBSCRIBING TO BLE NOTIFICATION");
    print("==================================================");
    print("📱 Device       : $deviceId");
    print("🔧 Service      : $service");
    print("🔧 Characteristic: $characteristic");
    print("==================================================");

    final qualified = BleHelper.characteristic(
      deviceId: deviceId,
      service: service,
      characteristic: characteristic,
    );

    print("✅ Qualified Characteristic Created");
    print("   Device ID: ${qualified.deviceId}");
    print("   Service UUID: ${qualified.serviceId}");
    print("   Characteristic UUID: ${qualified.characteristicId}");

    print("📡 Calling subscribeToCharacteristic()...");

    return ble
        .subscribeToCharacteristic(qualified)
        .map((bytes) {

      print("");
      print("📥 ==========================================");
      print("📥 RAW BLE NOTIFICATION RECEIVED");
      print("📥 Bytes      : $bytes");
      print("📥 Length     : ${bytes.length}");
      print(
        "📥 HEX        : ${bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
      print("📥 ==========================================");

      return bytes;
    });
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