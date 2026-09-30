import 'failure.dart';

/// Represents HTTP 4xx/5xx errors from the backend.
class const ServerFailure({
  required super.message,
  required final int statusCode,
  final String? requestId,
  super.code = 'SERVER_ERR',
  super.stackTrace,
  super.originalException,
}) extends Failure {
  @override
  List<Object?> get props => [...super.props, statusCode, requestId];
}
