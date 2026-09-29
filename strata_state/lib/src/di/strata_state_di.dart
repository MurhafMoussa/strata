import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:strata_core/strata_core.dart';

import '../config/localization_config_entity.dart';
import '../config/theme_config_entity.dart';
import '../localization/localization_cubit.dart';
import '../network/network_status_cubit.dart';
import '../platform/platform_cubit.dart';
import '../platform/platform_service_impl.dart';
import '../theme/theme_cubit.dart';

/// GetIt extension for registering `strata_state` dependencies.
extension StrataStateDiExtension on GetIt {
  /// Registers `strata_state` package dependencies.
  void registerStrataState({
    ThemeConfigEntity? themeConfig,
    LocalizationConfigEntity? localizationConfig,
    PlatformServiceInterface? platformService,
    NetworkStatusInterface? networkStatus,
  }) {
    if (networkStatus != null && !isRegistered<NetworkStatusInterface>()) {
      registerSingleton<NetworkStatusInterface>(networkStatus);
    }

    if (platformService != null && !isRegistered<PlatformServiceInterface>()) {
      registerSingleton<PlatformServiceInterface>(platformService);
    }

    if (!isRegistered<ThemeCubit>()) {
      registerLazySingleton<ThemeCubit>(
        () => ThemeCubit(initialConfig: themeConfig),
      );
    }

    if (localizationConfig != null && !isRegistered<LocalizationCubit>()) {
      registerLazySingleton<LocalizationCubit>(
        () => LocalizationCubit(config: localizationConfig),
      );
    }

    if (isRegistered<PlatformServiceInterface>() &&
        !isRegistered<PlatformCubit>()) {
      registerLazySingleton<PlatformCubit>(
        () => PlatformCubit(service: get<PlatformServiceInterface>()),
      );
    }

    if (isRegistered<NetworkStatusInterface>() &&
        !isRegistered<NetworkStatusCubit>()) {
      registerLazySingleton<NetworkStatusCubit>(
        () => NetworkStatusCubit(networkStatus: get<NetworkStatusInterface>()),
      );
    }
  }

  /// Registers default [PlatformServiceImpl] and [PlatformCubit] dependencies.
  void registerPlatformDependencies({
    DeviceInfoPlugin? deviceInfoPlugin,
    PackageInfo? packageInfo,
  }) {
    if (!isRegistered<PlatformServiceInterface>()) {
      registerLazySingleton<PlatformServiceInterface>(
        () => PlatformServiceImpl(
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
