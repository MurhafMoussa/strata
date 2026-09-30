import 'package:dio/dio.dart';
import 'package:strata_core/strata_core.dart';
import 'network_exception_mapper_interface.dart';

/// Default Dio exception mapper converting [DioException] into [Failure] domain models.
class DioExceptionMapper(
  final ErrorModelParser errorParser,
) implements NetworkExceptionMapperInterface {
  @override
  Failure mapException(Object exception, StackTrace? stackTrace) {
    if (exception is! DioException) {
      return UnknownFailure(
        message: exception.toString(),
        stackTrace: stackTrace,
        originalException: exception,
      );
    }

    return switch (exception.type) {
       DioExceptionType.cancel =>
        ConnectionFailure(
          message: 'Request cancelled',
          code: 'CANCELLED',
          stackTrace: stackTrace,
          originalException: exception,
        ),

       DioExceptionType.connectionTimeout ||
       DioExceptionType.sendTimeout ||
       DioExceptionType.receiveTimeout ||
       DioExceptionType.transformTimeout =>
        ConnectionFailure(
          message: 'Request timed out',
          code: 'TIMEOUT',
          stackTrace: stackTrace,
          originalException: exception,
        ),

       DioExceptionType.unknown ||
       DioExceptionType.connectionError =>
        ConnectionFailure(
          message: 'Unable to connect to server',
          code: 'NO_INTERNET',
          stackTrace: stackTrace,
          originalException: exception,
        ),

       DioExceptionType.badCertificate =>
        ConnectionFailure(
          message: 'Invalid SSL Certificate',
          code: 'SSL_ERR',
          stackTrace: stackTrace,
          originalException: exception,
        ),

       DioExceptionType.badResponse =>
        _mapServerResponse(exception.response, stackTrace, exception),
    };
  }

  Failure _mapServerResponse(
    Response<dynamic>? response,
    StackTrace? stackTrace,
    Object original,
  ) {
    if (response == null) {
      return UnknownFailure(
        message: 'Empty response from server',
        stackTrace: stackTrace,
        originalException: original,
      );
    }

    final int statusCode = response.statusCode ?? 500;
    final errorModel = errorParser(response);
    final String message = errorModel.developerMessage;
    final String? requestId = response.headers.value('x-request-id');

    return switch (statusCode) {
      401 => UnauthorizedFailure(
          message: message,
          code: 'AUTH_401',
          stackTrace: stackTrace,
          originalException: original,
        ),
      403 => UnauthorizedFailure(
          message: message,
          code: 'AUTH_403',
          stackTrace: stackTrace,
          originalException: original,
        ),
      422 => ValidationFailure(
          message: message,
          stackTrace: stackTrace,
          originalException: original,
        ),
      _ => ServerFailure(
          message: message,
          statusCode: statusCode,
          requestId: requestId,
          stackTrace: stackTrace,
          originalException: original,
        ),
    };
  }
}
