import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata_core/strata_core.dart';

/// A Bloc observer that logs events, state changes, transitions, errors,
/// creation, and closure of blocs using an injected [StrataLoggerInterface] instance.
class StrataBlocObserver extends BlocObserver {
  /// Creates a new [StrataBlocObserver] with the given [logger].
  StrataBlocObserver(this.logger);

  /// The logger instance used for logging Bloc events and changes.
  final StrataLoggerInterface logger;

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    logger.verbose('''
[Event] ${bloc.runtimeType}:
Event: $event
''');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    logger.debug('''
[Change] ${bloc.runtimeType}:
CurrentState: ${change.currentState}
NextState: ${change.nextState}
''');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    logger.info('''
[Transition] ${bloc.runtimeType}:
CurrentState: ${transition.currentState}
NextState: ${transition.nextState}
Event: ${transition.event}
''');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    logger.error('''
[Error] in ${bloc.runtimeType}:
Error: $error
StackTrace: $stackTrace
''');
  }

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    logger.warning('''
[Create] ${bloc.runtimeType} created.
''');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    logger.warning('''
[Close] ${bloc.runtimeType} closed.
''');
  }
}
