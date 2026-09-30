import 'package:get_it/get_it.dart';

import '../dev_tools/strata_logger_interface.dart';
import '../dev_tools/talker_strata_logger.dart';

/// Extension on [GetIt] to register `strata_core` dependencies.
extension StrataCoreDiExtension on GetIt {
  /// Registers `strata_core` dependencies.
  void registerStrataCore() {
    if (!isRegistered<StrataLoggerInterface>()) {
      registerLazySingleton<StrataLoggerInterface>(() => TalkerStrataLogger());
    }
  }
}
