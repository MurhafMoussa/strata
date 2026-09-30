import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerTestFallbacks();
  });

  group('TokenInjectorInterceptor Tests', () {
    late MockTokenManager mockTokenManager;
    late MockRequestInterceptorHandler mockHandler;

    setUp(() {
      mockTokenManager = MockTokenManager();
      mockHandler = MockRequestInterceptorHandler();
      when(() => mockHandler.next(any())).thenAnswer((_) {});
      when(() => mockHandler.reject(any())).thenAnswer((_) {});
    });

    test('BearerTokenInjectorInterceptor injects token header when isAuthorized is true and token is non-empty', () async {
      when(() => mockTokenManager.accessToken).thenAnswer((_) async => 'test_access_token');
      final interceptor = BearerTokenInjectorInterceptor(mockTokenManager);
      final options = RequestOptions(path: '/user', extra: {'isAuthorized': true});

      await interceptor.onRequest(options, mockHandler);

      expect(options.headers[HttpHeaders.authorizationHeader], equals('Bearer test_access_token'));
      verify(() => mockHandler.next(options)).called(1);
    });

    test('BearerTokenInjectorInterceptor does not inject header when token is empty or isAuthorized is false', () async {
      when(() => mockTokenManager.accessToken).thenAnswer((_) async => '');
      final interceptor = BearerTokenInjectorInterceptor(mockTokenManager);

      final optionsAuthorized = RequestOptions(path: '/user', extra: {'isAuthorized': true});
      await interceptor.onRequest(optionsAuthorized, mockHandler);
      expect(optionsAuthorized.headers.containsKey(HttpHeaders.authorizationHeader), isFalse);

      final optionsUnauthorized = RequestOptions(path: '/user', extra: {'isAuthorized': false});
      await interceptor.onRequest(optionsUnauthorized, mockHandler);
      expect(optionsUnauthorized.headers.containsKey(HttpHeaders.authorizationHeader), isFalse);
    });

    test('BearerTokenInjectorInterceptor handles DioException and generic exception during token retrieval', () async {
      final dioErr = DioException(requestOptions: RequestOptions(path: '/test'));
      when(() => mockTokenManager.accessToken).thenThrow(dioErr);

      final interceptor = BearerTokenInjectorInterceptor(mockTokenManager);
      final options1 = RequestOptions(path: '/user', extra: {'isAuthorized': true});

      await interceptor.onRequest(options1, mockHandler);
      verify(() => mockHandler.reject(dioErr)).called(1);

      when(() => mockTokenManager.accessToken).thenThrow(Exception('Generic error'));
      final options2 = RequestOptions(path: '/user', extra: {'isAuthorized': true});

      await interceptor.onRequest(options2, mockHandler);
      verify(() => mockHandler.reject(any(that: isA<DioException>()))).called(1);
    });

    test('CookieTokenInjectorInterceptor sets withCredentials and delegates to super', () async {
      when(() => mockTokenManager.accessToken).thenAnswer((_) async => 'cookie_access_token');
      final interceptor = CookieTokenInjectorInterceptor(mockTokenManager);
      final options = RequestOptions(path: '/user', extra: {'isAuthorized': true});

      await interceptor.onRequest(options, mockHandler);

      expect(options.extra['withCredentials'], isTrue);
      expect(options.headers[HttpHeaders.authorizationHeader], equals('Bearer cookie_access_token'));
      verify(() => mockHandler.next(options)).called(1);
    });
  });
}
