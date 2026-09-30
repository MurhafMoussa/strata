import 'failure.dart';

/// Unexpected/unhandled failures.
class const UnknownFailure({
  required super.message,
  super.code = 'UNKNOWN',
  super.stackTrace,
  super.originalException,
}) extends Failure;
