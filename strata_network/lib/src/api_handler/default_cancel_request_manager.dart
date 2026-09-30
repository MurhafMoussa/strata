import 'package:dio/dio.dart';
import 'cancel_request_manager_interface.dart';

/// Default implementation of [NetworkCancelRequestManagerInterface] supporting concurrent requests.
///
/// Uses `Map<String, Set<CancelToken>>` to ensure concurrent requests sharing identical
/// `requestId` strings maintain distinct active cancel tokens without overwriting each other.
class DefaultCancelRequestManager implements NetworkCancelRequestManagerInterface {
  final Map<String, Set<CancelToken>> _activeRequests = {};

  @override
  CancelToken registerRequest(String requestId) {
    final token = CancelToken();
    _activeRequests.putIfAbsent(requestId, () => {}).add(token);
    return token;
  }

  @override
  void cancelToken(CancelToken token, {String? reason}) {
    if (!token.isCancelled) {
      token.cancel(reason ?? 'Request cancelled');
    }
  }

  @override
  void cancelRequest(String requestId, {String? reason}) {
    final tokens = _activeRequests[requestId];
    if (tokens != null) {
      for (final token in Set<CancelToken>.from(tokens)) {
        cancelToken(token, reason: reason);
      }
    }
  }

  @override
  void unregisterToken(String requestId, CancelToken token) {
    final tokens = _activeRequests[requestId];
    if (tokens != null) {
      tokens.remove(token);
      if (tokens.isEmpty) {
        _activeRequests.remove(requestId);
      }
    }
  }

  @override
  void cancelAll({String? reason}) {
    for (final tokens in _activeRequests.values) {
      for (final token in Set<CancelToken>.from(tokens)) {
        cancelToken(token, reason: reason ?? 'All requests cancelled');
      }
    }
    _activeRequests.clear();
  }

  @override
  int get activeRequestCount {
    return _activeRequests.values.fold(0, (sum, set) => sum + set.length);
  }

  @override
  bool get hasActiveRequests => activeRequestCount > 0;
}
