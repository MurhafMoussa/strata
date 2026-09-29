import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:strata_core/strata_core.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../api_handler/api_handler_interface.dart';
import '../api_handler/cancel_request_manager_interface.dart';
import '../api_handler/default_cancel_request_manager.dart';
import '../api_handler/dio_api_handler.dart';
import '../auth/default_token_manager.dart';
import '../auth/token_manager_interface.dart';
import '../config/network_config_entity.dart';
import '../error_handling/dio_exception_mapper.dart';
import '../error_handling/network_exception_mapper_interface.dart';
import '../interceptors/retry_interceptor.dart';
import '../interceptors/token_injector_interceptor.dart';
import '../interceptors/token_refresh_interceptor_interface.dart';

/// Extension on [GetIt] to register `strata_network` dependencies.
extension StrataNetworkDiExtension on GetIt {
  /// Registers network infrastructure singletons.
  void registerStrataNetwork({
    required NetworkConfigEntity config,
    required ErrorModelParser errorParser,
  }) {
    if (!isRegistered<NetworkConfigEntity>()) {
      registerSingleton<NetworkConfigEntity>(config);
    }

    if (config.authInterceptorType == AuthInterceptorType.cookieBased) {
      if (!isRegistered<CookieJar>()) {
        registerLazySingleton<CookieJar>(() => CookieJar());
      }
    }

    if (!isRegistered<CancelRequestManagerInterface>()) {
      registerLazySingleton<CancelRequestManagerInterface>(
        () => DefaultCancelRequestManager(),
      );
    }

    if (!isRegistered<TokenManagerInterface>()) {
      registerLazySingleton<TokenManagerInterface>(
        () => DefaultTokenManager(
          sensitiveStorage: isRegistered<SensitiveStorageInterface>()
              ? get<SensitiveStorageInterface>()
              : null,
          secureStorageEnabled: true,
          cookieJar: isRegistered<CookieJar>() ? get<CookieJar>() : null,
        ),
      );
    }

    if (!isRegistered<NetworkExceptionMapperInterface>()) {
      registerLazySingleton<NetworkExceptionMapperInterface>(
        () => DioExceptionMapper(errorParser),
      );
    }

    if (!isRegistered<Dio>()) {
      registerLazySingleton<Dio>(() {
        final dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            sendTimeout: config.sendTimeout,
            receiveTimeout: config.receiveTimeout,
            headers: config.staticHeaders,
            queryParameters: config.defaultQueryParams,
            contentType: config.defaultContentType,
            followRedirects: config.followRedirects,
            maxRedirects: config.maxRedirects,
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        );

        if (config.enableLogging) {
          final talker =
              isRegistered<StrataLoggerInterface>() &&
                  get<StrataLoggerInterface>() is TalkerStrataLogger
              ? (get<StrataLoggerInterface>() as TalkerStrataLogger).talker
              : (isRegistered<Talker>() ? get<Talker>() : null);

          dio.interceptors.add(
            TalkerDioLogger(
              talker: talker,
              settings:
                  config.talkerDioLoggerSettings ??
                  const TalkerDioLoggerSettings(
                    printRequestData: true,
                    printResponseData: true,
                  ),
            ),
          );
        }

        if (config.authInterceptorType == AuthInterceptorType.cookieBased &&
            isRegistered<CookieJar>()) {
          dio.interceptors.add(CookieManager(get<CookieJar>()));
        }

        if (config.enableRetry) {
          dio.interceptors.add(
            RetryInterceptor(dio: dio, networkConfigEntity: config),
          );
        }

        if (config.enableTokenInjection) {
          final tokenManager = get<TokenManagerInterface>();
          final injector =
              config.authInterceptorType == AuthInterceptorType.cookieBased
              ? CookieTokenInjectorInterceptor(tokenManager)
              : BearerTokenInjectorInterceptor(tokenManager);
          dio.interceptors.add(injector);
        }

        if (config.enableRefreshTokenBehavior) {
          final tokenManager = get<TokenManagerInterface>();
          final refreshInterceptor =
              config.authInterceptorType == AuthInterceptorType.cookieBased
              ? CookieTokenRefreshInterceptor(
                  dio: dio,
                  tokenManager: tokenManager,
                  networkConfigEntity: config,
                )
              : BearerTokenRefreshInterceptor(
                  dio: dio,
                  tokenManager: tokenManager,
                  networkConfigEntity: config,
                );
          dio.interceptors.add(refreshInterceptor);
        }

        if (config.interceptors.isNotEmpty) {
          dio.interceptors.addAll(config.interceptors);
        }

        return dio;
      });
    }

    if (!isRegistered<ApiHandlerInterface>()) {
      registerLazySingleton<ApiHandlerInterface>(
        () => DioApiHandler(
          get<Dio>(),
          get<NetworkExceptionMapperInterface>(),
          get<CancelRequestManagerInterface>(),
        ),
      );
    }
  }
}
