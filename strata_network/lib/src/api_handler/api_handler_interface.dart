import 'package:strata_core/strata_core.dart';
import 'models/models.dart';

/// Abstract contract for handling API requests with functional programming [ResultFuture<T>].
abstract interface class ApiHandlerInterface {
  /// Sends an HTTP GET request to [path].
  ResultFuture<T> get<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });

  /// Sends an HTTP POST request to [path].
  ResultFuture<T> post<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });

  /// Sends an HTTP DELETE request to [path].
  ResultFuture<T> delete<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });

  /// Sends an HTTP PUT request to [path].
  ResultFuture<T> put<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });

  /// Sends an HTTP PATCH request to [path].
  ResultFuture<T> patch<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? body,
    NetworkFormData? formData,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });

  /// Downloads a file from [url] and saves it to [downloadDestinationPath].
  ResultFuture<T> download<T>(
    String url,
    String downloadDestinationPath, {
    required T Function(Map<String, dynamic> json) parser,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions? options,
  });
}
