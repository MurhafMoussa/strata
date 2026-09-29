import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('PlatformType', () {
    test('isMobile returns true only for android and ios', () {
      expect(PlatformType.android.isMobile, isTrue);
      expect(PlatformType.ios.isMobile, isTrue);
      expect(PlatformType.web.isMobile, isFalse);
      expect(PlatformType.macos.isMobile, isFalse);
      expect(PlatformType.windows.isMobile, isFalse);
      expect(PlatformType.linux.isMobile, isFalse);
      expect(PlatformType.fuchsia.isMobile, isFalse);
      expect(PlatformType.unknown.isMobile, isFalse);
    });

    test('isDesktop returns true only for windows, macos, and linux', () {
      expect(PlatformType.windows.isDesktop, isTrue);
      expect(PlatformType.macos.isDesktop, isTrue);
      expect(PlatformType.linux.isDesktop, isTrue);
      expect(PlatformType.android.isDesktop, isFalse);
      expect(PlatformType.ios.isDesktop, isFalse);
      expect(PlatformType.web.isDesktop, isFalse);
      expect(PlatformType.fuchsia.isDesktop, isFalse);
      expect(PlatformType.unknown.isDesktop, isFalse);
    });

    test('isWeb returns true only for web', () {
      expect(PlatformType.web.isWeb, isTrue);
      expect(PlatformType.android.isWeb, isFalse);
      expect(PlatformType.ios.isWeb, isFalse);
      expect(PlatformType.windows.isWeb, isFalse);
      expect(PlatformType.macos.isWeb, isFalse);
      expect(PlatformType.linux.isWeb, isFalse);
      expect(PlatformType.fuchsia.isWeb, isFalse);
      expect(PlatformType.unknown.isWeb, isFalse);
    });

    test('fromName resolves names case-insensitively', () {
      expect(PlatformType.fromName('android'), equals(PlatformType.android));
      expect(PlatformType.fromName('ANDROID'), equals(PlatformType.android));
      expect(PlatformType.fromName('iOS'), equals(PlatformType.ios));
      expect(PlatformType.fromName('Web'), equals(PlatformType.web));
      expect(PlatformType.fromName('macOS'), equals(PlatformType.macos));
      expect(PlatformType.fromName('windows'), equals(PlatformType.windows));
      expect(PlatformType.fromName('linux'), equals(PlatformType.linux));
      expect(PlatformType.fromName('fuchsia'), equals(PlatformType.fuchsia));
      expect(PlatformType.fromName('invalid_platform'), equals(PlatformType.unknown));
      expect(PlatformType.fromName(''), equals(PlatformType.unknown));
      expect(PlatformType.fromName(null), equals(PlatformType.unknown));
    });
  });

  group('DeviceInfoEntity', () {
    const entity = DeviceInfoEntity(
      deviceId: 'device-123',
      platform: PlatformType.android,
      model: 'Pixel 8',
      manufacturer: 'Google',
      osVersion: '14.0',
      isPhysicalDevice: true,
      buildNumber: '100',
      versionNumber: '1.2.3',
    );

    test('instantiates with specified properties', () {
      expect(entity.deviceId, equals('device-123'));
      expect(entity.platform, equals(PlatformType.android));
      expect(entity.model, equals('Pixel 8'));
      expect(entity.manufacturer, equals('Google'));
      expect(entity.osVersion, equals('14.0'));
      expect(entity.isPhysicalDevice, isTrue);
      expect(entity.buildNumber, equals('100'));
      expect(entity.versionNumber, equals('1.2.3'));
    });

    test('instantiates with defaults for optional parameters', () {
      const defaultEntity = DeviceInfoEntity(
        deviceId: 'device-456',
        platform: PlatformType.ios,
      );
      expect(defaultEntity.deviceId, equals('device-456'));
      expect(defaultEntity.platform, equals(PlatformType.ios));
      expect(defaultEntity.model, equals('Unknown'));
      expect(defaultEntity.manufacturer, equals('Unknown'));
      expect(defaultEntity.osVersion, equals('Unknown'));
      expect(defaultEntity.isPhysicalDevice, isTrue);
      expect(defaultEntity.buildNumber, equals('Unknown'));
      expect(defaultEntity.versionNumber, equals('Unknown'));
    });

    test('DeviceInfoEntity.unknown has standard fallback values', () {
      expect(DeviceInfoEntity.unknown.deviceId, equals('Unknown'));
      expect(DeviceInfoEntity.unknown.platform, equals(PlatformType.unknown));
      expect(DeviceInfoEntity.unknown.model, equals('Unknown'));
      expect(DeviceInfoEntity.unknown.manufacturer, equals('Unknown'));
      expect(DeviceInfoEntity.unknown.osVersion, equals('Unknown'));
      expect(DeviceInfoEntity.unknown.isPhysicalDevice, isFalse);
      expect(DeviceInfoEntity.unknown.buildNumber, equals('Unknown'));
      expect(DeviceInfoEntity.unknown.versionNumber, equals('Unknown'));
    });

    test('copyWith updates specified fields only', () {
      final updated = entity.copyWith(
        model: 'Pixel 9',
        osVersion: '15.0',
        isPhysicalDevice: false,
      );

      expect(updated.deviceId, equals('device-123'));
      expect(updated.platform, equals(PlatformType.android));
      expect(updated.model, equals('Pixel 9'));
      expect(updated.manufacturer, equals('Google'));
      expect(updated.osVersion, equals('15.0'));
      expect(updated.isPhysicalDevice, isFalse);
      expect(updated.buildNumber, equals('100'));
      expect(updated.versionNumber, equals('1.2.3'));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final json = entity.toJson();
      expect(json, equals({
        'deviceId': 'device-123',
        'platform': 'android',
        'model': 'Pixel 8',
        'manufacturer': 'Google',
        'osVersion': '14.0',
        'isPhysicalDevice': true,
        'buildNumber': '100',
        'versionNumber': '1.2.3',
      }));

      final restored = DeviceInfoEntity.fromJson(json);
      expect(restored, equals(entity));
    });

    test('fromJson provides safe fallbacks on empty or null json fields', () {
      final fromEmpty = DeviceInfoEntity.fromJson({});
      expect(fromEmpty.deviceId, equals('Unknown'));
      expect(fromEmpty.platform, equals(PlatformType.unknown));
      expect(fromEmpty.model, equals('Unknown'));
      expect(fromEmpty.manufacturer, equals('Unknown'));
      expect(fromEmpty.osVersion, equals('Unknown'));
      expect(fromEmpty.isPhysicalDevice, isFalse);
      expect(fromEmpty.buildNumber, equals('Unknown'));
      expect(fromEmpty.versionNumber, equals('Unknown'));
    });

    test('props equality and hash code', () {
      const duplicate = DeviceInfoEntity(
        deviceId: 'device-123',
        platform: PlatformType.android,
        model: 'Pixel 8',
        manufacturer: 'Google',
        osVersion: '14.0',
        isPhysicalDevice: true,
        buildNumber: '100',
        versionNumber: '1.2.3',
      );

      expect(entity, equals(duplicate));
      expect(entity.hashCode, equals(duplicate.hashCode));
      expect(entity.props, equals([
        'device-123',
        PlatformType.android,
        'Pixel 8',
        'Google',
        '14.0',
        true,
        '100',
        '1.2.3',
      ]));
    });
  });
}
