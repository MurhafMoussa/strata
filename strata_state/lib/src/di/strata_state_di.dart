import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';

import '../config/localization_config_entity.dart';
import '../config/theme_config_entity.dart';
import '../localization/localization_cubit.dart';
import '../network/network_status_cubit.dart';
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

    if (isRegistered<NetworkStatusInterface>() &&
        !isRegistered<NetworkStatusCubit>()) {
      registerLazySingleton<NetworkStatusCubit>(
        () => NetworkStatusCubit(networkStatus: get<NetworkStatusInterface>()),
      );
    }
  }
}
