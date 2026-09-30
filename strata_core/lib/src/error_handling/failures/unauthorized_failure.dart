import 'failure.dart';

/// Authorization issues (401/403).
class const UnauthorizedFailure({
  super.message = 'Access denied',
  super.code = 'ACCESS_DENIED',
  super.stackTrace,
  super.originalException,
}) extends Failure;
