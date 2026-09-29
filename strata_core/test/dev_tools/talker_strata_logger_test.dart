import 'package:strata_core/strata_core.dart';
import 'package:talker/talker.dart';
import 'package:test/test.dart';

void main() {
  group('TalkerStrataLogger', () {
    late Talker talker;
    late TalkerStrataLogger logger;

    setUp(() {
      talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      logger = TalkerStrataLogger(talker);
    });

    test('default constructor initializes Talker instance', () {
      final defaultLogger = TalkerStrataLogger();
      expect(defaultLogger.talker, isA<Talker>());
    });

    test('verbose logs message to talker history', () {
      logger.verbose('verbose test');
      expect(talker.history.length, equals(1));
      expect(talker.history.first.message, contains('verbose test'));
    });

    test('debug logs message to talker history', () {
      logger.debug('debug test');
      expect(talker.history.length, equals(1));
      expect(talker.history.first.message, contains('debug test'));
    });

    test('info logs message to talker history', () {
      logger.info('info test');
      expect(talker.history.length, equals(1));
      expect(talker.history.first.message, contains('info test'));
    });

    test('warning logs message to talker history', () {
      logger.warning('warning test');
      expect(talker.history.length, equals(1));
      expect(talker.history.first.message, contains('warning test'));
    });

    test('error logs message and exception to talker history', () {
      final exception = Exception('test exception');
      final stack = StackTrace.current;
      logger.error('error test', exception, stack);

      expect(talker.history.length, equals(1));
      expect(talker.history.first.message, contains('error test'));
      expect(talker.history.first.exception, equals(exception));
    });
  });
}
