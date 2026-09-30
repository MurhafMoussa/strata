/// Abstract logging interface for application-wide logging contracts.
abstract interface class StrataLoggerInterface {
  /// Log verbose message for detailed diagnostics.
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]);

  /// Log debug information for development-time analysis.
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]);

  /// Log informational messages about application operation.
  void info(dynamic message, [Object? error, StackTrace? stackTrace]);

  /// Log non-critical issues that might require attention.
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]);

  /// Log critical errors that need immediate investigation.
  void error(dynamic message, [Object? error, StackTrace? stackTrace]);
}

/// No-op implementation of [StrataLoggerInterface] for testing or silent mode.
class NoOpStrataLogger implements StrataLoggerInterface {
  /// Creates a [NoOpStrataLogger].
  const NoOpStrataLogger();

  @override
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {}
}
