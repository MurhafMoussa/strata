import 'failure.dart';

/// Network connectivity issues.
class const ConnectionFailure({
  super.message = 'No internet connection',
  super.code = 'NO_INTERNET',
  super.stackTrace,
  super.originalException,
}) extends Failure;
