import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_ui/strata_ui.dart';

void main() {
  group('StrataUiDiExtension', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.asNewInstance();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('registerStrataUi executes without error', () {
      expect(() => getIt.registerStrataUi(), returnsNormally);
    });

    test('registerPlatformDependencies registers PlatformServiceInterface and PlatformCubit', () {
      getIt.registerPlatformDependencies();

      expect(getIt.isRegistered<PlatformServiceInterface>(), isTrue);
      expect(getIt.isRegistered<PlatformCubit>(), isTrue);
      expect(getIt.get<PlatformServiceInterface>(), isA<DeviceInfoPlatformService>());
    });
  });
}
