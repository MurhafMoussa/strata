import 'dart:math';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerTestFallbacks();
  });

  group('RetryInterceptor Tests', () {
    late MockDio mockDio;
    late MockErrorInterceptorHandler mockHandler;
    late NetworkConfigEntity config;

    setUp(() {
      mockDio = MockDio();
      mockHandler = MockErrorInterceptorHandler();
      config = const NetworkConfigEntity(
        baseUrl: 'https://api.example.com',
        excludedPaths: [],
        refreshTokenApiEndpoint: '/refresh',
        accessTokenKey: 'access_token',
        refreshTokenKey: 'refresh_token',
        maxRetries: 3,
        retryInterval: Duration(milliseconds: 10),
        retryOnStatusCodes: [500, 502, 503, 504],
      );
    });

    test('retries on eligible status code (500) using exponential backoff and explicit Dio', () async {
      final interceptor = RetryInterceptor(
        dio: mockDio,
        networkConfigEntity: config,
        random: Random(42),
      );

      final options = RequestOptions(path: '/data');
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 500, requestOptions: options),
      );

      final successResponse = Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      );

      when(() => mockDio.fetch<dynamic>(any()))
          .thenAnswer((_) async => successResponse);
      when(() => mockHandler.resolve(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verify(() => mockDio.fetch<dynamic>(options)).called(1);
      verify(() => mockHandler.resolve(successResponse)).called(1);
      expect(options.extra['retry_count'], equals(1));
    });

    test('does not retry when enableRetry is false', () async {
      final interceptor = RetryInterceptor(
        dio: mockDio,
        networkConfigEntity: config,
      );

      final options = RequestOptions(
        path: '/data',
        extra: {'enableRetry': false},
      );
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 500, requestOptions: options),
      );

      when(() => mockHandler.next(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verifyZeroInteractions(mockDio);
      verify(() => mockHandler.next(error)).called(1);
    });

    test('does not retry when retry_count exceeds maxRetryAttempts', () async {
      final interceptor = RetryInterceptor(
        dio: mockDio,
        networkConfigEntity: config,
      );

      final options = RequestOptions(
        path: '/data',
        extra: {'retry_count': 3, 'maxRetryAttempts': 3},
      );
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 500, requestOptions: options),
      );

      when(() => mockHandler.next(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verifyZeroInteractions(mockDio);
      verify(() => mockHandler.next(error)).called(1);
    });

    test('retries with custom retryDelay and handles DioException during retry', () async {
      final interceptor = RetryInterceptor(
        dio: mockDio,
        networkConfigEntity: config,
      );

      final options = RequestOptions(
        path: '/data',
        extra: {'retryDelay': 1},
      );
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 500, requestOptions: options),
      );

      final retryException = DioException(requestOptions: options, message: 'Retry failed');
      when(() => mockDio.fetch<dynamic>(any())).thenThrow(retryException);
      when(() => mockHandler.next(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verify(() => mockHandler.next(retryException)).called(1);
    });
  });
}
