import 'dart:async';

/// Abstract contract for managing access and refresh authentication tokens.
abstract class TokenManagerInterface {
  /// Asynchronously retrieves the access token.
  Future<String> get accessToken;

  /// Asynchronously retrieves the refresh token.
  Future<String> get refreshToken;

  /// Sets in-memory and persistent access and refresh tokens.
  Future<void> setTokens({String? accessToken, String? refreshToken});

  /// Clears stored access and refresh tokens.
  Future<void> clearTokens();

 

  /// Stream emitting events when unauthenticated state is triggered.
  Stream<void> get unauthenticatedStream;

  /// Emits the unauthenticated event.
  void notifyUnauthenticated();

  /// Disposes resources held by the token manager.
  Future<void> dispose();
}
