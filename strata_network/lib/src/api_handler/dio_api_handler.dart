import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:strata_core/strata_core.dart';

import '../error_handling/network_exception_mapper_interface.dart';
import 'api_handler_interface.dart';
import 'cancel_request_manager_interface.dart';
import 'models/models.dart';

/// Dio implementation of [ApiHandlerInterface].
class DioApiHandler(
  final Dio _dio,
  final NetworkExceptionMapperInterface _exceptionMapper,
  final NetworkCancelRequestManagerInterface _cancelRequestManager,
) implements ApiHandlerInterface {
  Options _buildOptions(ApiRequestOptions? options, {bool isFormData = false}) {
    final opts = options ?? const ApiRequestOptions();
    final extra = <String, dynamic>{
      'isAuthorized': opts.isAuthorized,
      'enableRetry': opts.enableRetry,
    };

    if (opts.maxRetryAttempts != null) {
      extra['maxRetryAttempts'] = opts.maxRetryAttempts;
    }
    if (opts.retryDelay != null) {
      extra['retryDelay'] = opts.retryDelay!.inMilliseconds;
    }
    if (opts.shouldCache) {
      extra['shouldCache'] = true;
    }
    if (opts.extra != null) {
      extra.addAll(opts.extra!);
    }

    return Options(
      headers: opts.headers,
      extra: extra,
      contentType: isFormData
          ? Headers.multipartFormDataContentType
          : Headers.jsonContentType,
    );
  }

  Future<FormData> _convertToDioFormData(NetworkFormData formData) async {
    final dioFormData = FormData();

    for (final entry in formData.fields.entries) {
      dioFormData.fields.add(MapEntry(entry.key, entry.value.toString()));
    }

    for (final file in formData.files) {
      final dioFile = await MultipartFile.fromFile(
        file.filePath,
        filename: file.filename,
        contentType: file.contentType != null
            ? DioMediaType.parse(file.contentType!)
            : null,
      );
      dioFormData.files.add(MapEntry(file.fieldName, dioFile));
    }

    return dioFormData;
  }

  void Function(int, int)? _buildProgressCallback(
    void Function(double progress)? callback,
  ) {
    if (callback == null) return null;
    return (count, total) => callback(total > 0 ? count / total : 0.0);
  }

  Future<dynamic> _buildRequestData(
    Map<String, dynamic>? body,
    NetworkFormData? formData,
  ) async {
    return formData == null ? body : _convertToDioFormData(formData);
  }

  ResultFuture<T> _handleResponse<T>({
    required Future<Response<dynamic>> Function(CancelToken? cancelToken)
    dioMethod,
    required T Function(Map<String, dynamic> json) parser,
    String? requestId,
  }) async {
    CancelToken? cancelToken;
    if (requestId != null) {
      cancelToken = _cancelRequestManager.registerRequest(requestId);
    }

    try {
      final response = await dioMethod(cancelToken);
      if (response.data is List<dynamic>) {
        final formattedMap = {'data': response.data};
        final parsedData = parser(formattedMap);
        return right<Failure, T>(parsedData);
      } else if (response.data is Map<String, dynamic>) {
        final parsedData = parser(response.data as Map<String, dynamic>);
        return right<Failure, T>(parsedData);
      } else if (response.data is String) {
        final formattedMap = {'data': response.data};
        final parsedData = parser(formattedMap);
        return right<Failure, T>(parsedData);
      } else {
        return left<Failure, T>(
          const UnknownFailure(message: 'Invalid response data'),
        );
      }
    } on DioException catch (error, stackTrace) {
      if (error.type == DioExceptionType.cancel) {
        rethrow;
      }
      return left<Failure, T>(_exceptionMapper.mapException(error, stackTrace));
    } on Exception catch (error, stackTrace) {
      return left<Failure, T>(
        UnknownFailure(
          message: error.toString(),
          stackTrace: stackTrace,
          originalException: error,
        ),
      );
    } finally {
      if (requestId != null && cancelToken != null) {
        _cancelRequestManager.unregisterToken(requestId, cancelToken);
      }
    }
  }

  @override
  ResultFuture<T> get<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) => _dio.get(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(opts),
        onReceiveProgress: opts.onReceiveProgress != null
            ? (count, total) =>
                  opts.onReceiveProgress!(total > 0 ? count / total : 0.0)
            : null,
        cancelToken: cancelToken,
      ),
      parser: parser,
      requestId: opts.requestId,
    );
  }

  @override
  ResultFuture<T> post<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) async {
        final requestData = await _buildRequestData(body, formData);
        return _dio.post(
          path,
          data: requestData,
          queryParameters: queryParameters,
          options: _buildOptions(opts, isFormData: formData != null),
          onSendProgress: _buildProgressCallback(opts.onSendProgress),
          onReceiveProgress: _buildProgressCallback(opts.onReceiveProgress),
          cancelToken: cancelToken,
        );
      },
      parser: parser,
      requestId: opts.requestId,
    );
  }

  @override
  ResultFuture<T> delete<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) => _dio.delete(
        path,
        queryParameters: queryParameters,
        options: _buildOptions(opts),
        cancelToken: cancelToken,
      ),
      parser: parser,
      requestId: opts.requestId,
    );
  }

  @override
  ResultFuture<T> put<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) async {
        final requestData = await _buildRequestData(body, formData);
        return _dio.put(
          path,
          data: requestData,
          queryParameters: queryParameters,
          options: _buildOptions(opts, isFormData: formData != null),
          onSendProgress: _buildProgressCallback(opts.onSendProgress),
          onReceiveProgress: _buildProgressCallback(opts.onReceiveProgress),
          cancelToken: cancelToken,
        );
      },
      parser: parser,
      requestId: opts.requestId,
    );
  }

  @override
  ResultFuture<T> patch<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) async {
        final requestData = await _buildRequestData(body, formData);
        return _dio.patch(
          path,
          data: requestData,
          queryParameters: queryParameters,
          options: _buildOptions(opts, isFormData: formData != null),
          onSendProgress: _buildProgressCallback(opts.onSendProgress),
          onReceiveProgress: _buildProgressCallback(opts.onReceiveProgress),
          cancelToken: cancelToken,
        );
      },
      parser: parser,
      requestId: opts.requestId,
    );
  }

  @override
  ResultFuture<T> download<T>(
    String url,
    String downloadDestinationPath, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  }) {
    final opts = options ?? const ApiRequestOptions();
    return _handleResponse(
      dioMethod: (CancelToken? cancelToken) => _dio.download(
        url,
        downloadDestinationPath,
        queryParameters: queryParameters,
        options: _buildOptions(opts)
            .copyWith(responseType: ResponseType.stream),
        onReceiveProgress: opts.onReceiveProgress != null
            ? (count, total) =>
                  opts.onReceiveProgress!(total > 0 ? count / total : 0.0)
            : null,
        cancelToken: cancelToken,
      ),
      parser: parser,
      requestId: opts.requestId,
    );
  }
}
