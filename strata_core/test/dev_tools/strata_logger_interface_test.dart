import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('StrataLoggerInterface', () {
    test('NoOpStrataLogger methods execute without throwing errors', () {
      const logger = NoOpStrataLogger();

      expect(() => logger.verbose('verbose log'), returnsNormally);
      expect(() => logger.debug('debug log'), returnsNormally);
      expect(() => logger.info('info log'), returnsNormally);
      expect(() => logger.warning('warning log'), returnsNormally);
      expect(
        () => logger.error('error log', Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
