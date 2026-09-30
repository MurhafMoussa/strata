import 'package:strata_core/strata_core.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('TalkerDioLogger Integration Tests', () {
    late Talker talker;
    late TalkerStrataLogger logger;
    late TalkerDioLogger interceptor;

    setUp(() {
      talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      logger = TalkerStrataLogger(talker);
      interceptor = TalkerDioLogger(
        talker: logger.talker,
        settings: const TalkerDioLoggerSettings(
          printRequestData: true,
          printResponseData: true,
        ),
      );
    });

    test('onRequest logs HTTP request details to talker history', () {
      final options = createTestRequestOptions(path: '/test', method: 'GET');
      final handler = MockRequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      expect(talker.history.isNotEmpty, isTrue);
      expect(talker.history.first.message, contains('/test'));
    });

    test('onResponse logs HTTP response details to talker history', () {
      final options = createTestRequestOptions(path: '/test');
      final response = createTestResponse<dynamic>(
        requestOptions: options,
        statusCode: 200,
      );
      final handler = MockResponseInterceptorHandler();

      interceptor.onResponse(response, handler);

      expect(talker.history.isNotEmpty, isTrue);
    });

    test('onError logs HTTP error details to talker history', () {
      final options = createTestRequestOptions(path: '/test');
      final dioException = createTestDioException(
        requestOptions: options,
        statusCode: 500,
      );
      final handler = MockErrorInterceptorHandler();

      interceptor.onError(dioException, handler);

      expect(talker.history.isNotEmpty, isTrue);
    });
  });
}
