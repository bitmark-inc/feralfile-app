import 'package:autonomy_flutter/service/bluetooth_notification_service.dart';
import 'package:autonomy_flutter/service/bluetooth_service.dart';
import 'package:autonomy_flutter/util/bluetooth_device_ext.dart';
import 'package:autonomy_flutter/util/bluetooth_manager.dart';
import 'package:autonomy_flutter/util/flutter_blue_plus_base.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes cho mocktail
class MockFlutterBluePlusMockable extends Mock
    implements FlutterBluePlusMockable {}

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

class MockScanResult extends Mock implements ScanResult {}

class MockBluetoothCharacteristic extends Mock
    implements BluetoothCharacteristic {}

class MockBluetoothNotificationService extends Mock
    implements BluetoothNotificationService {}

class MockBluetoothResponse extends Mock implements BluetoothResponse {}

class MockBluetoothManager extends Mock implements BluetoothManager {}

void main() {
  late MockFlutterBluePlusMockable mockBlue;
  late FFBluetoothService bluetoothService;
  late MockBluetoothDevice mockDevice;
  late MockScanResult mockScanResult;
  late MockBluetoothCharacteristic mockCharacteristic;
  late MockBluetoothManager mockBluetoothManager;

  final testDeviceName = 'Test Device';

  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(const DeviceIdentifier('test_id'));
  });

  setUp(() {
    mockBlue = MockFlutterBluePlusMockable();
    bluetoothService = FFBluetoothService(mockBlue);
    mockDevice = MockBluetoothDevice();
    mockCharacteristic = MockBluetoothCharacteristic();
    mockBluetoothManager = MockBluetoothManager();
    mockScanResult = MockScanResult();

    when(() => mockDevice.name).thenReturn(testDeviceName);

    when(() => mockBlue.isSupported).thenAnswer((_) async => true);
    when(() => mockBlue.adapterStateNow).thenReturn(BluetoothAdapterState.on);
    when(() => mockBlue.adapterState).thenAnswer((_) => Stream.empty());

    when(() => mockDevice.isDisconnected).thenReturn(false);
    when(() => mockBluetoothManager.getWifiConnectCharacteristic(any()))
        .thenReturn(mockCharacteristic);

    // when(() => mockDevice.wifiConnectCharacteristic)
    //     .thenReturn(mockCharacteristic);
    when(() => mockDevice.remoteId)
        .thenReturn(const DeviceIdentifier('test_id'));
    when(() => mockDevice.advName).thenReturn('test_adv_name');

    when(() => mockCharacteristic.write(any())).thenAnswer((_) async {
      log.info('writeWithRetry called');
    });
  });

  group('startScan', () {
    setUpAll(() {});
    test('Case 1: Target device is connected', () async {
      // Giả lập đang không scan
      when(() => mockBlue.isScanningNow).thenReturn(false);

      // Giả lập connectedDevices trả về rỗng
      when(() => mockBlue.connectedDevices).thenReturn([mockDevice]);

      // Giả lập onScanResults trả về stream với 1 device
      when(() => mockBlue.onScanResults).thenAnswer(
        (_) => Stream.value([mockScanResult]),
      );
      when(() => mockScanResult.device).thenReturn(mockDevice);

      // Giả lập startScan và stopScan
      when(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).thenAnswer((_) async {});
      when(() => mockBlue.stopScan()).thenAnswer((_) async {});

      // Gọi startScan và kiểm tra callback onData
      bool onDataCalled = false;
      await bluetoothService.startScan(
        forceScan: true,
        timeout: Duration(seconds: 10),
        onData: (devices) {
          onDataCalled = true;
          return true; // Dừng scan sau khi nhận được device
        },
      );

      expect(onDataCalled, isTrue);
      verifyNever(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )); // vì đã có thiết bị kết nối nên không gọi startScan
      verify(() => mockBlue.stopScan()).called(1);
    });
    test('Case 2: Target device is not connected', () async {
      when(() => mockBlue.isScanningNow).thenReturn(false);
      when(() => mockBlue.connectedDevices).thenReturn([]);
      when(() => mockBlue.onScanResults).thenAnswer(
        (_) => Stream.value([mockScanResult]),
      );
      when(() => mockScanResult.device).thenReturn(mockDevice);
      when(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).thenAnswer((_) async {});
      when(() => mockBlue.stopScan()).thenAnswer((_) async {});
      bool onDataCalled = false;
      await bluetoothService.startScan(
        forceScan: true,
        timeout: Duration(seconds: 10),
        onData: (devices) {
          onDataCalled = true;
          if (devices.contains(mockDevice)) {
            return true;
          } else {
            return false;
          }
        },
      );
      expect(onDataCalled, isTrue);
      verify(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).called(1);
      verify(() => mockBlue.stopScan()).called(greaterThanOrEqualTo(1));
    });
    test('Case 3: Not found any device', () async {
      when(() => mockBlue.isScanningNow).thenReturn(false);
      when(() => mockBlue.connectedDevices).thenReturn([]);
      when(() => mockBlue.onScanResults).thenAnswer(
        (_) => Stream.value([]),
      );
      when(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).thenAnswer((_) async {});
      when(() => mockBlue.stopScan()).thenAnswer((_) async {});
      bool onDataCalled = false;
      await bluetoothService.startScan(
        forceScan: true,
        onData: (devices) {
          onDataCalled = true;
          if (devices.contains(mockDevice)) {
            return true;
          } else {
            return false;
          }
        },
      );
      expect(onDataCalled, isTrue);
      verify(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).called(1);
      verify(() => mockBlue.stopScan()).called(greaterThanOrEqualTo(1));
    });
    test('Case 4: found devices but not target device', () async {
      when(() => mockBlue.isScanningNow).thenReturn(false);
      final mockDevice1 = MockBluetoothDevice();
      when(() => mockBlue.connectedDevices).thenReturn([]);
      when(() => mockBlue.onScanResults).thenAnswer(
        (_) => Stream.value([mockScanResult]),
      );
      when(() => mockScanResult.device).thenReturn(mockDevice1);
      when(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).thenAnswer((_) async {});
      when(() => mockBlue.stopScan()).thenAnswer((_) async {});
      bool onDataCalled = false;
      await bluetoothService.startScan(
        forceScan: true,
        onData: (devices) {
          onDataCalled = true;
          if (devices.contains(mockDevice)) {
            return true;
          } else {
            return false;
          }
        },
      );
      expect(onDataCalled, isTrue);
      verify(() => mockBlue.startScan(
            timeout: any(named: 'timeout'),
            withServices: any(named: 'withServices'),
          )).called(1);
      verify(() => mockBlue.stopScan()).called(1);
    });
  });

  group('sendCommand', () {
    test('sendCommand: gửi lệnh thành công và nhận phản hồi', () async {
      final command = BluetoothCommand.sendWifiCredentials;
      final request = {'ssid': 'test', 'password': '12345678'};
      final notificationService = MockBluetoothNotificationService();
      // inject notificationService vào singleton nếu cần
      when(() => notificationService.subscribe(any(), any()))
          .thenAnswer((invocation) {
        final cb = invocation.positionalArguments[1] as NotificationCallback;
        cb(RawData(errorCode: 0, data: ['topicId123'], topic: ''));
      });

      final chr = mockDevice.wifiConnectCharacteristic;
      final res = await bluetoothService.sendCommand(
        device: mockDevice,
        command: command,
        request: request,
      );
      expect(res, isA<SendWifiCredentialResponse>());
      expect((res as SendWifiCredentialResponse).topicId, 'topicId123');
    });
    // Thêm các test case khác tương tự cho các trường hợp lỗi, timeout, ...
  });
}
