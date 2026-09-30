import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:strata_core/strata_core.dart';

import 'token_manager_interface.dart';

/// Default implementation of [TokenManagerInterface] backed by optional [SensitiveStorageInterface]
/// and optional [CookieJar].
class DefaultTokenManager implements TokenManagerInterface {
  DefaultTokenManager({
    this.sensitiveStorage,
    this.cookieJar,
    this.secureStorageEnabled = false,
  });

  final SensitiveStorageInterface? sensitiveStorage;
  final CookieJar? cookieJar;
  final bool secureStorageEnabled;
  final StreamController<void> _unauthenticatedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get unauthenticatedStream => _unauthenticatedController.stream;

  String? _accessToken;
  String? _refreshToken;

  @override
  void notifyUnauthenticated() {
    if (!_unauthenticatedController.isClosed) {
      _unauthenticatedController.add(null);
    }
  }

  @override
  Future<String> get accessToken async {
    final storage = sensitiveStorage;
    if (secureStorageEnabled && storage != null) {
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        return _accessToken!;
      }
      final result = await storage.read('accessToken');
      return result.fold((failure) => '', (String? token) {
        _accessToken = token;
        return token ?? '';
      });
    }
    return _accessToken ?? '';
  }

  @override
  Future<String> get refreshToken async {
    final storage = sensitiveStorage;
    if (secureStorageEnabled && storage != null) {
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        return _refreshToken!;
      }
      final result = await storage.read('refreshToken');
      return result.fold((failure) => '', (String? token) {
        _refreshToken = token;
        return token ?? '';
      });
    }
    return _refreshToken ?? '';
  }

  @override
  Future<void> setTokens({String? accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final storage = sensitiveStorage;
    if (secureStorageEnabled && storage != null) {
      if (accessToken != null && accessToken.isNotEmpty) {
        await storage.save('accessToken', accessToken);
      }
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await storage.save('refreshToken', refreshToken);
      }
    }
  }

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    final storage = sensitiveStorage;
    if (secureStorageEnabled && storage != null) {
      await storage.delete('accessToken');
      await storage.delete('refreshToken');
    }

    final jar = cookieJar;
    if (jar != null) {
      await jar.deleteAll();
    }
  }

  @override
  Future<void> dispose() async {
    await _unauthenticatedController.close();
  }
}
