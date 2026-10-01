# strata_network

Dio HTTP client wrapper, token lifecycle management, and multi-token request cancellation tracking for the Strata framework.

## Overview

`strata_network` provides a robust functional HTTP networking layer for Dart applications. It wraps Dio into functional `ResultFuture<T>` calls, handles automated token refresh with immediate cleanup on refresh failure, tracks multi-token concurrent request cancellations, and supports per-request retry policies.

## Architectural Rules & Boundaries

- **Pure Dart Core**: Depends ONLY on `strata_core`, `dio`, `dio_cookie_manager`, `cookie_jar`, `internet_connection_checker_plus`, `fpdart`, `get_it`, `equatable`, and `mutex`.
- **Zero Framework Lock-in**: Has ZERO dependencies on Flutter, `flutter_bloc`, `go_router`, or UI libraries.
- **Strict Boundary Enforcement**: Enforced via package dependency tests. Zero Dio type leakage on public package entrypoint.

## Key Components

### 1. `ApiHandlerInterface` & `DioApiHandler`
Functional HTTP client methods (`get`, `post`, `put`, `patch`, `delete`, `download`) returning `ResultFuture<T>` (`Future<Either<Failure, T>>`):

```dart
import 'package:strata_network/strata_network.dart';

final apiHandler = getIt<ApiHandlerInterface>();

final result = await apiHandler.get<User>(
  '/users/123',
  parser: (json) => User.fromJson(json),
  options: const ApiRequestOptions(
    isAuthorized: true,
    requestId: 'get_user_profile',
  ),
);

result.fold(
  (failure) => print('API Error: ${failure.message}'),
  (user) => print('User fetched: ${user.name}'),
);
```

### 2. Multipart Form Data (`NetworkFormData` & `NetworkFile`)
Allows sending multipart requests cleanly without caller dependencies on Dio types:

```dart
import 'package:strata_network/strata_network.dart';

final formData = NetworkFormData(
  fields: {'username': 'john_doe'},
  files: [
    NetworkFile(
      fieldName: 'avatar',
      filePath: '/path/to/avatar.png',
      filename: 'avatar.png',
      contentType: 'image/png',
    ),
  ],
);

final result = await apiHandler.post<User>(
  '/users/avatar',
  parser: (json) => User.fromJson(json),
  formData: formData,
  options: const ApiRequestOptions(isAuthorized: true),
);
```

### 3. `CancelRequestManagerInterface` & `DefaultCancelRequestManager`
Manages request cancellation tokens using a multi-token map (`Map<String, Set<CancelToken>>`). Supports rapid navigation and concurrent requests sharing identical request IDs without overwriting active connections:

```dart
import 'package:strata_network/strata_network.dart';

final cancelManager = getIt<CancelRequestManagerInterface>();

// Register concurrent requests under identical requestId
final token1 = cancelManager.registerRequest('fetch_feed');
final token2 = cancelManager.registerRequest('fetch_feed');

// Cancel only specific token instance
cancelManager.cancelToken(token1, reason: 'Tab switched');

// Cancel all active requests for a given request ID
cancelManager.cancelRequest('fetch_feed', reason: 'Screen dismissed');

// Cancel all active network requests app-wide (e.g. on logout)
cancelManager.cancelAll(reason: 'User logged out');

// Register and cancel paginated requests via PaginatedCancelRequestManagerX
final pageParams = PagePaginationParams(page: 1, limit: 20);
final pageToken = cancelManager.registerPaginationRequest(pageParams);
cancelManager.cancelPaginationRequest(pageParams, reason: 'Page refreshed');
```

### 4. `TokenRefreshInterceptorInterface`
Handles 401 unauthorized errors by queuing pending requests and attempting a single token refresh operation.

**Critical Security Feature**: On refresh failure (HTTP 400/401 or network error during refresh API call), `TokenRefreshInterceptorInterface`:
1. Explicitly calls `_tokenManager.clearTokens()` to clear stored expired tokens.
2. Calls `notifyUnauthenticated()` on `_tokenManager` to notify active `unauthenticatedStream` listeners.
3. Rejects all pending queued requests.

Available concrete implementations:
- `BearerTokenRefreshInterceptor`: For Bearer token authorization headers.
- `CookieTokenRefreshInterceptor`: For cookie-based session authorization.

### 5. `TokenManagerInterface` & `DefaultTokenManager`
Manages access and refresh tokens in memory and optionally persists them using `SensitiveStorageInterface` from `strata_core`. Exposes a reactive `unauthenticatedStream` for session expiration handling:

```dart
import 'package:strata_network/strata_network.dart';

final tokenManager = DefaultTokenManager(
  sensitiveStorage: getIt<SensitiveStorageInterface>(),
  secureStorageEnabled: true,
);

// Listen to unauthenticated events for reactive logout/routing
tokenManager.unauthenticatedStream.listen((_) {
  print('User session expired - triggering logout flow');
});

await tokenManager.setTokens(
  accessToken: 'new_access_token',
  refreshToken: 'new_refresh_token',
);
```

### 6. Network Status (`InternetConnectionNetworkStatus`)
Monitors device internet connectivity status conforming to `GLOSSARY.md` naming conventions and `NetworkStatusInterface`. Automatically registered in `GetIt` by `registerStrataNetwork`:

```dart
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_network/strata_network.dart';

final networkStatus = InternetConnectionNetworkStatus(
  InternetConnection(),
  logger,
);

// Check current connectivity
final isConnected = await networkStatus.isConnected;

// Listen to status stream (ConnectionStatus.connected, ConnectionStatus.disconnected)
networkStatus.connectionStream.listen((status) {
  print('Network status changed to: ${status.name}');
});
```

### 7. Dependency Injection (`StrataNetworkDiExtension`)
Registers singletons on `GetIt`:

```dart
import 'package:get_it/get_it.dart';
import 'package:strata_network/strata_network.dart';

final getIt = GetIt.instance;

getIt.registerStrataNetwork(
  config: const NetworkConfigEntity(
    baseUrl: 'https://api.example.com',
    excludedPaths: ['/auth/login'],
    refreshTokenApiEndpoint: '/auth/refresh',
    accessTokenKey: 'access_token',
    refreshTokenKey: 'refresh_token',
  ),
  errorParser: (response) => CustomErrorResponseModel.fromJson(response),
);
```

## Running Tests & Audits

Run static analysis and unit tests inside the `strata_network` directory:

```bash
cd strata_network
dart analyze
dart test
```
