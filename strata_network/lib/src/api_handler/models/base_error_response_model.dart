/// Abstract contract for structured backend error response models.
abstract class const BaseErrorResponseModel({
  required final int status,
  required final String developerMessage,
  required final DateTime timestamp,
  final String? traceId,
  final String? path,
}) {
  /// Returns a map of field names to error messages for validation failures.
  Map<String, String> get validationErrors;
}
