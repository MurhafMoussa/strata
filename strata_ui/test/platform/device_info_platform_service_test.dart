import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_ui/strata_ui.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}
class MockBaseDeviceInfo extends Mock implements BaseDeviceInfo {}
class MockAndroidDeviceInfo extends Mock implements AndroidDeviceInfo {}
class MockAndroidBuildVersion extends Mock implements AndroidBuildVersion {}
class MockIosDeviceInfo extends Mock implements IosDeviceInfo {}
class MockIosUtsname extends Mock implements IosUtsname {}
class MockWindowsDeviceInfo extends Mock implements WindowsDeviceInfo {}
class MockMacOsDeviceInfo extends Mock implements MacOsDeviceInfo {}
class MockLinuxDeviceInfo extends Mock implements LinuxDeviceInfo {}
class MockWebBrowserInfo extends Mock implements WebBrowserInfo {}

void main() {
  late MockDeviceInfoPlugin mockDeviceInfoPlugin;
  late PackageInfo mockPackageInfo;

  setUp(() {
    mockDeviceInfoPlugin = MockDeviceInfoPlugin();
    mockPackageInfo = PackageInfo(
      appName: 'TestApp',
      packageName: 'com.strata.test',
      version: '1.2.0',
      buildNumber: '42',
      buildSignature: '',
      installerStore: '',
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('DeviceInfoPlatformService', () {
    test('collects Android device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final androidInfo = MockAndroidDeviceInfo();
      final androidVersion = MockAndroidBuildVersion();

      when(() => androidVersion.release).thenReturn('14.0');
      when(() => androidInfo.id).thenReturn('android-id-123');
      when(() => androidInfo.model).thenReturn('Pixel 8');
      when(() => androidInfo.manufacturer).thenReturn('Google');
      when(() => androidInfo.version).thenReturn(androidVersion);
      when(() => androidInfo.isPhysicalDevice).thenReturn(true);
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => androidInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.android));
      expect(result.deviceId, equals('android-id-123'));
      expect(result.model, equals('Pixel 8'));
      expect(result.manufacturer, equals('Google'));
      expect(result.osVersion, equals('14.0'));
      expect(result.isPhysicalDevice, isTrue);
      expect(result.versionNumber, equals('1.2.0'));
      expect(result.buildNumber, equals('42'));
    });

    test('collects iOS device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iosInfo = MockIosDeviceInfo();
      final utsname = MockIosUtsname();

      when(() => utsname.machine).thenReturn('iPhone15,2');
      when(() => iosInfo.identifierForVendor).thenReturn('ios-vendor-id-456');
      when(() => iosInfo.utsname).thenReturn(utsname);
      when(() => iosInfo.systemVersion).thenReturn('17.2');
      when(() => iosInfo.isPhysicalDevice).thenReturn(true);
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => iosInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.ios));
      expect(result.deviceId, equals('ios-vendor-id-456'));
      expect(result.model, equals('iPhone15,2'));
      expect(result.manufacturer, equals('Apple'));
      expect(result.osVersion, equals('17.2'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects iOS device info with fallback when vendor id is null', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final iosInfo = MockIosDeviceInfo();
      final utsname = MockIosUtsname();

      when(() => utsname.machine).thenReturn('iPhone15,2');
      when(() => iosInfo.identifierForVendor).thenReturn(null);
      when(() => iosInfo.utsname).thenReturn(utsname);
      when(() => iosInfo.systemVersion).thenReturn('17.2');
      when(() => iosInfo.isPhysicalDevice).thenReturn(false);
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => iosInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.deviceId, equals('Unknown iOS Device'));
      expect(result.isPhysicalDevice, isFalse);
    });

    test('collects Windows device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final winInfo = MockWindowsDeviceInfo();

      when(() => winInfo.deviceId).thenReturn('win-guid-789');
      when(() => winInfo.computerName).thenReturn('DESKTOP-TEST');
      when(() => winInfo.productName).thenReturn('Windows 11 Pro');
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => winInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.windows));
      expect(result.deviceId, equals('win-guid-789'));
      expect(result.model, equals('DESKTOP-TEST'));
      expect(result.manufacturer, equals('Microsoft'));
      expect(result.osVersion, equals('Windows 11 Pro'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects macOS device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final macInfo = MockMacOsDeviceInfo();

      when(() => macInfo.systemGUID).thenReturn('mac-guid-001');
      when(() => macInfo.model).thenReturn('MacBookPro18,1');
      when(() => macInfo.osRelease).thenReturn('Version 14.1');
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => macInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.macos));
      expect(result.deviceId, equals('mac-guid-001'));
      expect(result.model, equals('MacBookPro18,1'));
      expect(result.manufacturer, equals('Apple'));
      expect(result.osVersion, equals('Version 14.1'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects macOS device info with fallback when systemGUID is null', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final macInfo = MockMacOsDeviceInfo();

      when(() => macInfo.systemGUID).thenReturn(null);
      when(() => macInfo.model).thenReturn('MacBookPro18,1');
      when(() => macInfo.osRelease).thenReturn('Version 14.1');
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => macInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();
      expect(result.deviceId, equals('Unknown macOS Device'));
    });

    test('collects Linux device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final linuxInfo = MockLinuxDeviceInfo();

      when(() => linuxInfo.machineId).thenReturn('linux-machine-002');
      when(() => linuxInfo.name).thenReturn('Ubuntu');
      when(() => linuxInfo.versionId).thenReturn('24.04');
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => linuxInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.linux));
      expect(result.deviceId, equals('linux-machine-002'));
      expect(result.model, equals('Ubuntu'));
      expect(result.manufacturer, equals('Linux'));
      expect(result.osVersion, equals('24.04'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects Linux device info with fallbacks when fields are null', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final linuxInfo = MockLinuxDeviceInfo();

      when(() => linuxInfo.machineId).thenReturn(null);
      when(() => linuxInfo.name).thenReturn('Arch Linux');
      when(() => linuxInfo.versionId).thenReturn(null);
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => linuxInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.deviceId, equals('Unknown Linux Device'));
      expect(result.osVersion, equals('Unknown'));
    });

    test('collects Fuchsia device info successfully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      final baseInfo = MockBaseDeviceInfo();
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => baseInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.fuchsia));
      expect(result.deviceId, equals('Fuchsia Device'));
      expect(result.model, equals('Fuchsia'));
      expect(result.manufacturer, equals('Google'));
      expect(result.osVersion, equals('Fuchsia'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects Web device info successfully when isWebOverride is true', () async {
      final webInfo = MockWebBrowserInfo();

      when(() => webInfo.userAgent).thenReturn('Mozilla/5.0 (Chrome)');
      when(() => webInfo.browserName).thenReturn(BrowserName.chrome);
      when(() => webInfo.vendor).thenReturn('Google');
      when(() => webInfo.platform).thenReturn('Win32');
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => webInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
        isWebOverride: true,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.web));
      expect(result.deviceId, equals('Mozilla/5.0 (Chrome)'));
      expect(result.model, equals('chrome'));
      expect(result.manufacturer, equals('Google'));
      expect(result.osVersion, equals('Win32'));
      expect(result.isPhysicalDevice, isTrue);
    });

    test('collects Web device info with fallbacks when fields are null or empty', () async {
      final webInfo = MockWebBrowserInfo();

      when(() => webInfo.userAgent).thenReturn(null);
      when(() => webInfo.browserName).thenReturn(BrowserName.safari);
      when(() => webInfo.vendor).thenReturn('');
      when(() => webInfo.platform).thenReturn(null);
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => webInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
        isWebOverride: true,
      );

      final result = await service.getDeviceInfo();

      expect(result.deviceId, equals('Unknown Web Browser'));
      expect(result.model, equals('safari'));
      expect(result.manufacturer, equals('Unknown'));
      expect(result.osVersion, equals('Unknown'));
    });

    test('returns DeviceInfoEntity.unknown when deviceInfoPlugin throws', () async {
      when(() => mockDeviceInfoPlugin.deviceInfo).thenThrow(Exception('Native plugin error'));

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result, equals(DeviceInfoEntity.unknown));
    });

    test('handles unrecognized BaseDeviceInfo gracefully', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final baseInfo = MockBaseDeviceInfo();
      when(() => mockDeviceInfoPlugin.deviceInfo).thenAnswer((_) async => baseInfo);

      final service = DeviceInfoPlatformService(
        deviceInfoPlugin: mockDeviceInfoPlugin,
        packageInfo: mockPackageInfo,
      );

      final result = await service.getDeviceInfo();

      expect(result.platform, equals(PlatformType.android));
      expect(result.deviceId, equals('Unknown'));
      expect(result.model, equals('Unknown'));
      expect(result.manufacturer, equals('Unknown'));
      expect(result.osVersion, equals('Unknown'));
    });
  });
}
