import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_network/strata_network.dart';

// --- Common Mocks ---
class MockDio extends Mock implements Dio {}

class MockTokenManager extends Mock implements TokenManagerInterface {}

class MockSensitiveStorage extends Mock implements SensitiveStorageInterface {}

class MockCookieJar extends Mock implements CookieJar {}

class MockStrataLogger extends Mock implements StrataLoggerInterface {}
typedef MockCoreLogger = MockStrataLogger;

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockResponseInterceptorHandler extends Mock
    implements ResponseInterceptorHandler {}

class MockCancelRequestManager extends Mock
    implements NetworkCancelRequestManagerInterface {}

class MockNetworkExceptionMapper extends Mock
    implements NetworkExceptionMapperInterface {}

class MockInternetConnection extends Mock implements InternetConnection {}

// --- Dummy Error Model for Testing ---
class TestErrorResponseModel extends BaseErrorResponseModel {
  TestErrorResponseModel({
    required super.status,
    required super.developerMessage,
    required super.timestamp,
  });

  @override
  Map<String, String> get validationErrors => {};
}

// --- Common Fallbacks ---
void registerTestFallbacks() {
  registerFallbackValue(CancelToken());
  registerFallbackValue(Options());
  registerFallbackValue(RequestOptions(path: ''));
  registerFallbackValue(
    Response<dynamic>(requestOptions: RequestOptions(path: '')),
  );
  registerFallbackValue(DioException(requestOptions: RequestOptions(path: '')));
}

// --- Test Fixtures & Object Creation Helpers ---
NetworkConfigEntity createTestNetworkConfig({
  String baseUrl = 'https://api.example.com',
  List<String> excludedPaths = const <String>[],
  String refreshTokenApiEndpoint = '/auth/refresh',
  String accessTokenKey = 'access_token',
  String refreshTokenKey = 'refresh_token',
  AuthInterceptorType authInterceptorType = AuthInterceptorType.cookieBased,
  bool enableRetry = true,
  bool enableRefreshTokenBehavior = true,
  int maxRetries = 3,
  Duration retryInterval = const Duration(milliseconds: 10),
  List<int> retryOnStatusCodes = const [500, 502, 503, 504],
  List<Interceptor> interceptors = const [],
  Duration connectTimeout = const Duration(seconds: 60),
  Duration sendTimeout = const Duration(seconds: 60),
  Duration receiveTimeout = const Duration(seconds: 60),
  Map<String, String> staticHeaders = const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
  Map<String, dynamic> defaultQueryParams = const {},
  String defaultContentType = 'application/json',
  bool followRedirects = true,
  int maxRedirects = 5,
}) {
  return NetworkConfigEntity(
    baseUrl: baseUrl,
    excludedPaths: excludedPaths,
    refreshTokenApiEndpoint: refreshTokenApiEndpoint,
    accessTokenKey: accessTokenKey,
    refreshTokenKey: refreshTokenKey,
    authInterceptorType: authInterceptorType,
    enableRetry: enableRetry,
    enableRefreshTokenBehavior: enableRefreshTokenBehavior,
    maxRetries: maxRetries,
    retryInterval: retryInterval,
    retryOnStatusCodes: retryOnStatusCodes,
    interceptors: interceptors,
    connectTimeout: connectTimeout,
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
    staticHeaders: staticHeaders,
    defaultQueryParams: defaultQueryParams,
    defaultContentType: defaultContentType,
    followRedirects: followRedirects,
    maxRedirects: maxRedirects,
  );
}

RequestOptions createTestRequestOptions({
  String path = '/test',
  String method = 'GET',
  Map<String, dynamic>? extra,
  Map<String, dynamic>? headers,
}) {
  return RequestOptions(
    path: path,
    method: method,
    extra: extra ?? <String, dynamic>{},
    headers: headers ?? <String, dynamic>{},
  );
}

Response<T> createTestResponse<T>({
  required RequestOptions requestOptions,
  int statusCode = 200,
  T? data,
  Headers? headers,
}) {
  return Response<T>(
    requestOptions: requestOptions,
    statusCode: statusCode,
    data: data,
    headers: headers,
  );
}

DioException createTestDioException({
  required RequestOptions requestOptions,
  DioExceptionType type = DioExceptionType.badResponse,
  int? statusCode,
  dynamic data,
  Object? error,
  String? message,
}) {
  return DioException(
    type: type,
    requestOptions: requestOptions,
    error: error,
    message: message,
    response: statusCode != null
        ? Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: statusCode,
            data: data,
          )
        : null,
  );
}
