import 'package:equatable/equatable.dart';

/// Base class for all failures in the application.
abstract class const Failure({
  required final String message,
  final String? code,
  final StackTrace? stackTrace,
  final Object? originalException,
}) extends Equatable implements Exception {
  @override
  List<Object?> get props => [message, code, stackTrace, originalException];

  @override
  bool get stringify => true;
}
