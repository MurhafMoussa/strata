import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:strata_core/strata_core.dart';

/// Concrete implementation of [NetworkStatusInterface] using [InternetConnection].
class InternetConnectionNetworkStatus(
  final InternetConnection _internetConnection,
  final StrataLoggerInterface _logger,
) implements NetworkStatusInterface {
  this {
    _init();
  }

  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();
  StreamSubscription<InternetStatus>? _subscription;

  @override
  Stream<ConnectionStatus> get connectionStream => _controller.stream;

  @override
  void dispose() {
    _subscription?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  @override
  Future<bool> get isConnected async => _internetConnection.hasInternetAccess;

  Future<void> _init() async {
    _subscription =
        _internetConnection.onStatusChange.listen((status) {
          if (_controller.isClosed) return;
          switch (status) {
            case InternetStatus.connected:
              _controller.add(ConnectionStatus.connected);
              break;
            case InternetStatus.disconnected:
              _controller.add(ConnectionStatus.disconnected);
              break;
          }
        })..onError((Object? e, StackTrace s) {
          _logger.error('Something went wrong in NetworkStatus', e, s);
        });
  }
}
