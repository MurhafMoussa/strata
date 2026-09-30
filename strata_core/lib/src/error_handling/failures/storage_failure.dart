import 'failure.dart';

/// Represents local storage operation failures (read, save, delete, clear).
class const StorageFailure({
  required super.message,
  super.code = 'STORAGE_ERR',
  super.stackTrace,
  super.originalException,
}) extends Failure;
