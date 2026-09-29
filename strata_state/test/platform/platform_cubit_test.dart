import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

class MockPlatformServiceInterface extends Mock implements PlatformServiceInterface {}

void main() {
  late MockPlatformServiceInterface platformService;

  const mockDeviceInfo = DeviceInfoEntity(
    deviceId: 'test_device_123',
    platform: PlatformType.android,
    model: 'Pixel 8',
    manufacturer: 'Google',
    osVersion: '14.0',
    isPhysicalDevice: true,
    buildNumber: '10',
    versionNumber: '1.0.0',
  );

  const mockDesktopInfo = DeviceInfoEntity(
    deviceId: 'desktop_guid_456',
    platform: PlatformType.windows,
    model: 'Precision 5570',
    manufacturer: 'Dell',
    osVersion: 'Windows 11 Pro',
    isPhysicalDevice: true,
    buildNumber: '20',
    versionNumber: '2.0.0',
  );

  const mockWebInfo = DeviceInfoEntity(
    deviceId: 'web_agent_789',
    platform: PlatformType.web,
    model: 'chrome',
    manufacturer: 'Google Inc.',
    osVersion: 'Win32',
    isPhysicalDevice: true,
    buildNumber: '30',
    versionNumber: '3.0.0',
  );

  setUp(() {
    platformService = MockPlatformServiceInterface();
  });

  group('PlatformCubit', () {
    test('initializes and exposes correct getters for mobile platform', () async {
      when(() => platformService.getDeviceInfo()).thenAnswer((_) async => mockDeviceInfo);

      final cubit = PlatformCubit(service: platformService);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(mockDeviceInfo));
      expect(cubit.deviceInfo, equals(mockDeviceInfo));
      expect(cubit.currentPlatform, equals(PlatformType.android));
      expect(cubit.deviceId, equals('test_device_123'));
      expect(cubit.model, equals('Pixel 8'));
      expect(cubit.manufacturer, equals('Google'));
      expect(cubit.osVersion, equals('14.0'));
      expect(cubit.isPhysicalDevice, isTrue);
      expect(cubit.appVersion, equals('1.0.0'));
      expect(cubit.buildNumber, equals('10'));
      expect(cubit.isMobile, isTrue);
      expect(cubit.isDesktop, isFalse);
      expect(cubit.isWeb, isFalse);
    });

    test('initializes synchronously when initialInfo is provided (bootstrap pattern)', () {
      final cubit = PlatformCubit(
        service: platformService,
        initialInfo: mockDeviceInfo,
      );

      expect(cubit.state, equals(mockDeviceInfo));
      verifyNever(() => platformService.getDeviceInfo());
    });

    test('exposes correct desktop platform flags', () async {
      when(() => platformService.getDeviceInfo()).thenAnswer((_) async => mockDesktopInfo);

      final cubit = PlatformCubit(service: platformService);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isMobile, isFalse);
      expect(cubit.isDesktop, isTrue);
      expect(cubit.isWeb, isFalse);
    });

    test('exposes correct web platform flags', () async {
      when(() => platformService.getDeviceInfo()).thenAnswer((_) async => mockWebInfo);

      final cubit = PlatformCubit(service: platformService);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isMobile, isFalse);
      expect(cubit.isDesktop, isFalse);
      expect(cubit.isWeb, isTrue);
    });

    test('retains initial unknown state when getDeviceInfo fails', () async {
      when(() => platformService.getDeviceInfo()).thenThrow(Exception('Platform error'));

      final cubit = PlatformCubit(service: platformService);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, equals(DeviceInfoEntity.unknown));
    });

    test('retains provided initial state when fetch fails', () async {
      when(() => platformService.getDeviceInfo()).thenThrow(Exception('Platform error'));

      final cubit = PlatformCubit(
        service: platformService,
        initialInfo: mockDeviceInfo,
      );

      await cubit.refreshDeviceInfo();
      expect(cubit.state, equals(mockDeviceInfo));
    });

    blocTest<PlatformCubit, DeviceInfoEntity>(
      'emits resolved device info after automatic initialization',
      build: () {
        when(() => platformService.getDeviceInfo()).thenAnswer((_) async => mockDeviceInfo);
        return PlatformCubit(service: platformService);
      },
      expect: () => [mockDeviceInfo],
    );

    blocTest<PlatformCubit, DeviceInfoEntity>(
      'refreshDeviceInfo fetches updated info from service and emits',
      build: () {
        when(() => platformService.getDeviceInfo()).thenAnswer((_) async => mockDesktopInfo);
        return PlatformCubit(
          service: platformService,
          initialInfo: mockDeviceInfo,
        );
      },
      act: (cubit) => cubit.refreshDeviceInfo(),
      expect: () => [mockDesktopInfo],
    );
  });
}
