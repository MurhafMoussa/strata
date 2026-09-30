import 'package:talker/talker.dart';

import 'strata_logger_interface.dart';

/// [StrataLoggerInterface] implementation backed by [Talker].
class TalkerStrataLogger implements StrataLoggerInterface {
  /// Creates a [TalkerStrataLogger] with an optional [Talker] instance.
  TalkerStrataLogger([Talker? talker]) : talker = talker ?? Talker();

  /// The underlying [Talker] instance.
  final Talker talker;

  @override
  void verbose(dynamic message, [Object? error, StackTrace? stackTrace]) {
    talker.verbose(message, error, stackTrace);
  }

  @override
  void debug(dynamic message, [Object? error, StackTrace? stackTrace]) {
    talker.debug(message, error, stackTrace);
  }

  @override
  void info(dynamic message, [Object? error, StackTrace? stackTrace]) {
    talker.info(message, error, stackTrace);
  }

  @override
  void warning(dynamic message, [Object? error, StackTrace? stackTrace]) {
    talker.warning(message, error, stackTrace);
  }

  @override
  void error(dynamic message, [Object? error, StackTrace? stackTrace]) {
    talker.error(message, error, stackTrace);
  }
}
