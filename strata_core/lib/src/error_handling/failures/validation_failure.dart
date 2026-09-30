import 'failure.dart';

/// Client-side data validation failure.
class const ValidationFailure({
  required super.message,
  super.code = 'VALIDATION_ERR',
  super.stackTrace,
  super.originalException,
}) extends Failure;
