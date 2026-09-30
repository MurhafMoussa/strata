import 'dart:async';

enum ConnectionStatus { connected, disconnected, unknown }

abstract interface class NetworkStatusInterface {
  Future<bool> get isConnected;

  Stream<ConnectionStatus> get connectionStream;

  void dispose();
}
