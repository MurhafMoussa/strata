import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

/// Authentication interceptor type options.
enum AuthInterceptorType { tokenBased, cookieBased }

/// Configuration options for `strata_network` HTTP client and interceptors.
class NetworkConfigEntity extends Equatable {
  const NetworkConfigEntity({
    required this.baseUrl,
    required this.excludedPaths,
    required this.refreshTokenApiEndpoint,
    required this.accessTokenKey,
    required this.refreshTokenKey,
    this.authInterceptorType = AuthInterceptorType.cookieBased,
    this.connectTimeout = const Duration(seconds: 60),
    this.sendTimeout = const Duration(seconds: 60),
    this.receiveTimeout = const Duration(seconds: 60),
    this.defaultQueryParams = const {},
    this.staticHeaders = const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    this.interceptors = const [],
    this.defaultContentType = 'application/json',
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 3),
    this.retryOnStatusCodes = const [500, 502, 503, 504],
    this.enableCache = false,
    this.cacheDuration = const Duration(minutes: 5),
    this.enableRetry = true,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.enableTokenInjection = true,
    this.enableRefreshTokenBehavior = true,
    this.enableLogging = true,
    this.talkerDioLoggerSettings,
  });

  final String baseUrl;
  final List<String> excludedPaths;
  final String refreshTokenApiEndpoint;
  final String accessTokenKey;
  final String refreshTokenKey;
  final AuthInterceptorType authInterceptorType;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final Map<String, dynamic> defaultQueryParams;
  final Map<String, String> staticHeaders;
  final List<Interceptor> interceptors;
  final String defaultContentType;
  final int maxRetries;
  final Duration retryInterval;
  final List<int> retryOnStatusCodes;
  final bool enableCache;
  final Duration cacheDuration;
  final bool enableRetry;
  final bool followRedirects;
  final int maxRedirects;
  final bool enableTokenInjection;
  final bool enableRefreshTokenBehavior;
  final bool enableLogging;
  final TalkerDioLoggerSettings? talkerDioLoggerSettings;

  @override
  List<Object?> get props => [
        baseUrl,
        connectTimeout,
        sendTimeout,
        receiveTimeout,
        staticHeaders,
        defaultQueryParams,
        defaultContentType,
        maxRetries,
        retryInterval,
        retryOnStatusCodes,
        enableCache,
        cacheDuration,
        followRedirects,
        maxRedirects,
        enableRetry,
        excludedPaths,
        authInterceptorType,
        refreshTokenApiEndpoint,
        accessTokenKey,
        refreshTokenKey,
        enableTokenInjection,
        enableRefreshTokenBehavior,
        enableLogging,
        talkerDioLoggerSettings,
      ];
}
