import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';
import '../storage/flutter_secure_sensitive_storage.dart';

/// Extension on [GetIt] to register `strata_storage` dependencies.
extension StrataStorageDiExtension on GetIt {
  /// Registers [SensitiveStorageInterface] using [FlutterSecureSensitiveStorage].
  void registerStrataStorage() {
    if (!isRegistered<SensitiveStorageInterface>()) {
      registerLazySingleton<SensitiveStorageInterface>(
        () => const FlutterSecureSensitiveStorage(
          secureStorage: FlutterSecureStorage(),
        ),
      );
    }
  }
}
