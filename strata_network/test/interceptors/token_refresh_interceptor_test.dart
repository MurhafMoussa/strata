import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

class TestTokenRefreshInterceptor extends TokenRefreshInterceptorInterface {
  TestTokenRefreshInterceptor({
    required super.dio,
    required super.tokenManager,
    required super.networkConfigEntity,
    required this.refreshResultSupplier,
  });

  final Future<bool> Function() refreshResultSupplier;

  @override
  Future<bool> handleRefresh(DioException err) {
    return refreshResultSupplier();
  }
}

void main() {
  setUpAll(() {
    registerTestFallbacks();
  });

  group('TokenRefreshInterceptorInterface Tests', () {
    late MockDio mockDio;
    late MockTokenManager mockTokenManager;
    late MockErrorInterceptorHandler mockHandler;
    late NetworkConfigEntity config;

    setUp(() {
      mockDio = MockDio();
      mockTokenManager = MockTokenManager();
      mockHandler = MockErrorInterceptorHandler();

      config = const NetworkConfigEntity(
        baseUrl: 'https://api.example.com',
        excludedPaths: <String>[],
        refreshTokenApiEndpoint: '/auth/refresh',
        accessTokenKey: 'access_token',
        refreshTokenKey: 'refresh_token',
      );

      when(() => mockTokenManager.clearTokens()).thenAnswer((_) async {});
      when(() => mockTokenManager.notifyUnauthenticated()).thenAnswer((_) {});
    });

    test('clears tokens and notifies unauthenticated on 401 refresh failure', () async {
      final interceptor = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
        refreshResultSupplier: () async => false, // Refresh returns false (failure)
      );

      final options = RequestOptions(
        path: '/user/profile',
        extra: {'isAuthorized': true},
      );
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 401, requestOptions: options),
      );

      when(() => mockHandler.reject(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verify(() => mockTokenManager.clearTokens()).called(1);
      verify(() => mockTokenManager.notifyUnauthenticated()).called(1);
      verify(() => mockHandler.reject(any())).called(1);
    });

    test('does not handle refresh when conditions for 401 refresh are not met', () async {
      final interceptor = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
        refreshResultSupplier: () async => true,
      );

      when(() => mockHandler.reject(any())).thenAnswer((_) {});

      // 1. enableRefreshTokenBehavior is false
      final configDisabled = const NetworkConfigEntity(
        baseUrl: 'https://api.example.com',
        excludedPaths: <String>[],
        refreshTokenApiEndpoint: '/auth/refresh',
        accessTokenKey: 'access_token',
        refreshTokenKey: 'refresh_token',
        enableRefreshTokenBehavior: false,
      );
      final interceptorDisabled = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: configDisabled,
        refreshResultSupplier: () async => true,
      );
      final errDisabled = DioException(
        requestOptions: RequestOptions(path: '/user', extra: {'isAuthorized': true}),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/user')),
      );
      await interceptorDisabled.onError(errDisabled, mockHandler);
      verify(() => mockHandler.reject(errDisabled)).called(1);

      // 2. Status code is not 401
      final err500 = DioException(
        requestOptions: RequestOptions(path: '/user', extra: {'isAuthorized': true}),
        response: Response(statusCode: 500, requestOptions: RequestOptions(path: '/user')),
      );
      await interceptor.onError(err500, mockHandler);
      verify(() => mockHandler.reject(err500)).called(1);

      // 3. isAuthorized is false/null
      final errNotAuth = DioException(
        requestOptions: RequestOptions(path: '/user', extra: {'isAuthorized': false}),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/user')),
      );
      await interceptor.onError(errNotAuth, mockHandler);
      verify(() => mockHandler.reject(errNotAuth)).called(1);

      // 4. isRetry is true
      final errRetry = DioException(
        requestOptions: RequestOptions(path: '/user', extra: {'isAuthorized': true, 'isRetry': true}),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/user')),
      );
      await interceptor.onError(errRetry, mockHandler);
      verify(() => mockHandler.reject(errRetry)).called(1);

      // 5. Path is refresh endpoint
      final errRefreshPath = DioException(
        requestOptions: RequestOptions(path: '/auth/refresh', extra: {'isAuthorized': true}),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/auth/refresh')),
      );
      await interceptor.onError(errRefreshPath, mockHandler);
      verify(() => mockHandler.reject(errRefreshPath)).called(1);

      // 6. Path is in excludedPaths
      final configExcluded = const NetworkConfigEntity(
        baseUrl: 'https://api.example.com',
        excludedPaths: ['/excluded'],
        refreshTokenApiEndpoint: '/auth/refresh',
        accessTokenKey: 'access_token',
        refreshTokenKey: 'refresh_token',
      );
      final interceptorExcluded = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: configExcluded,
        refreshResultSupplier: () async => true,
      );
      final errExcluded = DioException(
        requestOptions: RequestOptions(path: '/excluded/data', extra: {'isAuthorized': true}),
        response: Response(statusCode: 401, requestOptions: RequestOptions(path: '/excluded/data')),
      );
      await interceptorExcluded.onError(errExcluded, mockHandler);
      verify(() => mockHandler.reject(errExcluded)).called(1);
    });

    test('retries original request on refresh success', () async {
      final interceptor = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
        refreshResultSupplier: () async => true,
      );

      final options = RequestOptions(path: '/user/profile', extra: {'isAuthorized': true});
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 401, requestOptions: options),
      );

      final mockResponse = Response(statusCode: 200, requestOptions: options, data: {'id': 123});
      when(() => mockDio.fetch<dynamic>(any())).thenAnswer((_) async => mockResponse);
      when(() => mockHandler.resolve(any())).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verify(() => mockDio.fetch<dynamic>(any())).called(1);
      verify(() => mockHandler.resolve(mockResponse)).called(1);
    });

    test('rejects with retry exception when retry fetch fails with DioException', () async {
      final interceptor = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
        refreshResultSupplier: () async => true,
      );

      final options = RequestOptions(path: '/user/profile', extra: {'isAuthorized': true});
      final error = DioException(
        requestOptions: options,
        response: Response(statusCode: 401, requestOptions: options),
      );

      final retryError = DioException(requestOptions: options, message: 'Retry network failure');
      when(() => mockDio.fetch<dynamic>(any())).thenThrow(retryError);
      when(() => mockHandler.reject(retryError)).thenAnswer((_) {});

      await interceptor.onError(error, mockHandler);

      verify(() => mockHandler.reject(retryError)).called(1);
    });

    test('getNestedValue and getNestedString helpers extract deeply nested fields correctly', () {
      final interceptor = TestTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
        refreshResultSupplier: () async => true,
      );

      final data = {
        'data': {
          'tokens': {
            'access': 'acc_token_val',
            'empty': '',
            'number': 123,
          }
        }
      };

      expect(interceptor.getNestedValue(null, 'data.tokens'), isNull);
      expect(interceptor.getNestedValue(data, ''), isNull);
      expect(interceptor.getNestedValue(data, 'data.tokens.missing'), isNull);
      expect(interceptor.getNestedValue(data, 'data.tokens.access.foo'), isNull);
      expect(interceptor.getNestedValue(data, 'data.tokens.access'), equals('acc_token_val'));

      expect(interceptor.getNestedString(data, 'data.tokens.access'), equals('acc_token_val'));
      expect(interceptor.getNestedString(data, 'data.tokens.empty'), isNull);
      expect(interceptor.getNestedString(data, 'data.tokens.number'), isNull);
    });

    test('BearerTokenRefreshInterceptor handleRefresh handles success, empty RT, and failures', () async {
      final bearerInterceptor = BearerTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
      );

      final err = DioException(requestOptions: RequestOptions(path: '/test'));

      // 1. RT is empty
      when(() => mockTokenManager.refreshToken).thenAnswer((_) async => '');
      expect(await bearerInterceptor.handleRefresh(err), isFalse);

      // 2. RT present, dio.post returns success with tokens
      when(() => mockTokenManager.refreshToken).thenAnswer((_) async => 'rt_123');
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': 'rt_123'},
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            data: {'access_token': 'new_acc', 'refresh_token': 'new_ref'},
          ));
      when(() => mockTokenManager.setTokens(accessToken: 'new_acc', refreshToken: 'new_ref'))
          .thenAnswer((_) async {});

      expect(await bearerInterceptor.handleRefresh(err), isTrue);
      verify(() => mockTokenManager.setTokens(accessToken: 'new_acc', refreshToken: 'new_ref')).called(1);

      // 3. dio.post returns missing access token
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': 'rt_123'},
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            data: {'refresh_token': 'new_ref'},
          ));
      expect(await bearerInterceptor.handleRefresh(err), isFalse);

      // 4. dio.post throws exception
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': 'rt_123'},
            options: any(named: 'options'),
          )).thenThrow(Exception('Refresh error'));
      expect(await bearerInterceptor.handleRefresh(err), isFalse);
    });

    test('CookieTokenRefreshInterceptor handleRefresh handles success and failures', () async {
      final cookieInterceptor = CookieTokenRefreshInterceptor(
        dio: mockDio,
        tokenManager: mockTokenManager,
        networkConfigEntity: config,
      );

      final err = DioException(requestOptions: RequestOptions(path: '/test'));

      // 1. dio.post returns success
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            data: {'access_token': 'new_acc', 'refresh_token': 'new_ref'},
          ));
      when(() => mockTokenManager.setTokens(accessToken: 'new_acc', refreshToken: 'new_ref'))
          .thenAnswer((_) async {});

      expect(await cookieInterceptor.handleRefresh(err), isTrue);

      // 2. dio.post returns null data or no tokens
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/refresh'),
            data: null,
          ));
      expect(await cookieInterceptor.handleRefresh(err), isFalse);

      // 3. dio.post throws exception
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/refresh',
            options: any(named: 'options'),
          )).thenThrow(Exception('Cookie refresh error'));
      expect(await cookieInterceptor.handleRefresh(err), isFalse);
    });
  });
}
