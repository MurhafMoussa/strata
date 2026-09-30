import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('StrataCoreDiExtension', () {
    late GetIt getIt;

    setUp(() async {
      getIt = GetIt.asNewInstance();
    });

    tearDown(() async {
      await getIt.reset();
    });

    test('registerStrataCore executes without error', () {
      expect(() => getIt.registerStrataCore(), returnsNormally);
    });
  });
}
