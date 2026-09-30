import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:strata_core/strata_core.dart';

import '../platform/platform_cubit.dart';
import '../platform/device_info_platform_service.dart';

/// Extension on [GetIt] to register `strata_ui` dependencies.
extension StrataUiDiExtension on GetIt {
  /// Registers `strata_ui` dependencies.
  void registerStrataUi() {
    // Component registrations if any UI dependencies are needed.
  }

  /// Registers default [DeviceInfoPlatformService] and [PlatformCubit] dependencies.
  void registerPlatformDependencies({
    DeviceInfoPlugin? deviceInfoPlugin,
    PackageInfo? packageInfo,
  }) {
    if (!isRegistered<PlatformServiceInterface>()) {
      registerLazySingleton<PlatformServiceInterface>(
        () => DeviceInfoPlatformService(
          deviceInfoPlugin: deviceInfoPlugin,
          packageInfo: packageInfo,
        ),
      );
    }

    if (!isRegistered<PlatformCubit>()) {
      registerLazySingleton<PlatformCubit>(
        () => PlatformCubit(service: get<PlatformServiceInterface>()),
      );
    }
  }
}
