import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:strata_core/strata_core.dart';

/// Implementation of platform service providing comprehensive device and platform information.
class DeviceInfoPlatformService implements PlatformServiceInterface {
  DeviceInfoPlatformService({
    DeviceInfoPlugin? deviceInfoPlugin,
    PackageInfo? packageInfo,
    bool? isWebOverride,
  })  : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin() {
    _packageInfo = packageInfo;
    _isWebOverride = isWebOverride;
  }

  final DeviceInfoPlugin _deviceInfoPlugin;
  PackageInfo? _packageInfo;
  bool? _isWebOverride;

  bool get _isWeb => _isWebOverride ?? kIsWeb;

  @override
  Future<DeviceInfoEntity> getDeviceInfo() async {
    try {
      return await _collectDeviceInfo();
    } catch (_) {
      return DeviceInfoEntity.unknown;
    }
  }

  PlatformType _resolvePlatform() {
    if (_isWeb) return PlatformType.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformType.android;
      case TargetPlatform.iOS:
        return PlatformType.ios;
      case TargetPlatform.windows:
        return PlatformType.windows;
      case TargetPlatform.macOS:
        return PlatformType.macos;
      case TargetPlatform.linux:
        return PlatformType.linux;
      case TargetPlatform.fuchsia:
        return PlatformType.fuchsia;
    }
  }

  Future<DeviceInfoEntity> _collectDeviceInfo() async {
    final platform = _resolvePlatform();
    final packageInfo = _packageInfo ??= await PackageInfo.fromPlatform();
    final versionNumber = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

    String deviceId = 'Unknown';
    String model = 'Unknown';
    String manufacturer = 'Unknown';
    String osVersion = 'Unknown';
    bool isPhysicalDevice = true;

    final baseInfo = await _deviceInfoPlugin.deviceInfo;

    if (_isWeb) {
      if (baseInfo is WebBrowserInfo) {
        deviceId = baseInfo.userAgent ?? 'Unknown Web Browser';
        model = baseInfo.browserName.name;
        manufacturer = baseInfo.vendor?.isNotEmpty == true ? baseInfo.vendor! : 'Unknown';
        osVersion = baseInfo.platform ?? 'Unknown';
        isPhysicalDevice = true;
      }
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          if (baseInfo is AndroidDeviceInfo) {
            deviceId = baseInfo.id;
            model = baseInfo.model;
            manufacturer = baseInfo.manufacturer;
            osVersion = baseInfo.version.release;
            isPhysicalDevice = baseInfo.isPhysicalDevice;
          }
          break;
        case TargetPlatform.iOS:
          if (baseInfo is IosDeviceInfo) {
            deviceId = baseInfo.identifierForVendor ?? 'Unknown iOS Device';
            model = baseInfo.utsname.machine;
            manufacturer = 'Apple';
            osVersion = baseInfo.systemVersion;
            isPhysicalDevice = baseInfo.isPhysicalDevice;
          }
          break;
        case TargetPlatform.windows:
          if (baseInfo is WindowsDeviceInfo) {
            deviceId = baseInfo.deviceId;
            model = baseInfo.computerName;
            manufacturer = 'Microsoft';
            osVersion = baseInfo.productName;
            isPhysicalDevice = true;
          }
          break;
        case TargetPlatform.macOS:
          if (baseInfo is MacOsDeviceInfo) {
            deviceId = baseInfo.systemGUID ?? 'Unknown macOS Device';
            model = baseInfo.model;
            manufacturer = 'Apple';
            osVersion = baseInfo.osRelease;
            isPhysicalDevice = true;
          }
          break;
        case TargetPlatform.linux:
          if (baseInfo is LinuxDeviceInfo) {
            deviceId = baseInfo.machineId ?? 'Unknown Linux Device';
            model = baseInfo.name;
            manufacturer = 'Linux';
            osVersion = baseInfo.versionId ?? 'Unknown';
            isPhysicalDevice = true;
          }
          break;
        case TargetPlatform.fuchsia:
          deviceId = 'Fuchsia Device';
          model = 'Fuchsia';
          manufacturer = 'Google';
          osVersion = 'Fuchsia';
          isPhysicalDevice = true;
          break;
      }
    }

    return DeviceInfoEntity(
      deviceId: deviceId,
      platform: platform,
      model: model,
      manufacturer: manufacturer,
      osVersion: osVersion,
      isPhysicalDevice: isPhysicalDevice,
      buildNumber: buildNumber,
      versionNumber: versionNumber,
    );
  }
}
