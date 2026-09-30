import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata_core/strata_core.dart';

/// A Cubit that manages the current network connection status.
class NetworkStatusCubit extends Cubit<ConnectionStatus> {
  NetworkStatusCubit({
    required this.networkStatus,
    ConnectionStatus initialStatus = ConnectionStatus.unknown,
  }) : super(initialStatus) {
    _initialize();
  }

  final NetworkStatusInterface networkStatus;
  StreamSubscription<ConnectionStatus>? _subscription;

  bool get isConnected => state == ConnectionStatus.connected;
  bool get isDisconnected => state == ConnectionStatus.disconnected;
  bool get isUnknown => state == ConnectionStatus.unknown;

  Future<void> _initialize() async {
    _subscription = networkStatus.connectionStream.listen((status) {
      if (!isClosed) emit(status);
    });

    try {
      final isConnected = await networkStatus.isConnected;
      final resolvedStatus = isConnected
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
      if (!isClosed && state != resolvedStatus) {
        emit(resolvedStatus);
      }
    } catch (_) {
      // Retain initial / stream status if isConnected check fails
    }
  }

  /// Manually checks and updates connection status.
  Future<ConnectionStatus> checkConnection() async {
    try {
      final isConnected = await networkStatus.isConnected;
      final resolvedStatus = isConnected
          ? ConnectionStatus.connected
          : ConnectionStatus.disconnected;
      if (!isClosed && state != resolvedStatus) {
        emit(resolvedStatus);
      }
      return resolvedStatus;
    } catch (_) {
      return state;
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
