import 'failure.dart';

/// Business rule violation failure.
class const BusinessFailure({
  required super.message,
  super.code = 'BIZ_RULE',
  super.stackTrace,
  super.originalException,
}) extends Failure;
