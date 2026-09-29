import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata_core/strata_core.dart';

/// Cubit for managing device and platform information state.
class PlatformCubit extends Cubit<DeviceInfoEntity> {
  PlatformCubit({
    required this.service,
    DeviceInfoEntity? initialInfo,
  }) : super(initialInfo ?? DeviceInfoEntity.unknown) {
    if (initialInfo == null) {
      _initialize();
    }
  }

  final PlatformServiceInterface service;

  Future<void> _initialize() async {
    await fetchDeviceInfo();
  }

  /// Fetches latest device information from the underlying platform service.
  Future<void> fetchDeviceInfo() async {
    try {
      final deviceInfo = await service.getDeviceInfo();
      emit(deviceInfo);
    } catch (_) {
      if (state == DeviceInfoEntity.unknown) {
        emit(DeviceInfoEntity.unknown);
      }
    }
  }

  /// Refreshes device information asynchronously.
  Future<void> refreshDeviceInfo() async {
    await fetchDeviceInfo();
  }

  /// Convenient accessor for the device info entity.
  DeviceInfoEntity get deviceInfo => state;

  /// Current platform type.
  PlatformType get currentPlatform => state.platform;

  /// Device hardware ID or vendor ID.
  String get deviceId => state.deviceId;

  /// Hardware model name.
  String get model => state.model;

  /// Hardware manufacturer.
  String get manufacturer => state.manufacturer;

  /// Operating system release or kernel version.
  String get osVersion => state.osVersion;

  /// Whether running on a physical device.
  bool get isPhysicalDevice => state.isPhysicalDevice;

  /// Application version name/number.
  String get appVersion => state.versionNumber;

  /// Application package build number.
  String get buildNumber => state.buildNumber;

  /// Whether current platform is Android or iOS.
  bool get isMobile => state.platform.isMobile;

  /// Whether current platform is Windows, macOS, or Linux.
  bool get isDesktop => state.platform.isDesktop;

  /// Whether running in a web browser.
  bool get isWeb => state.platform.isWeb;
}
