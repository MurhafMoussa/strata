import 'device_info_entity.dart';

/// Interface for platform service providing device and platform information.
abstract interface class PlatformServiceInterface {
  /// Get comprehensive device information asynchronously.
  Future<DeviceInfoEntity> getDeviceInfo();
}
