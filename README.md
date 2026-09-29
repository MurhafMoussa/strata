# 🎯 Strata Framework

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

**Strata** is an enterprise modular Flutter & Dart framework structured as a Melos monorepo. It is decomposed into 7 focused sub-packages designed for maximum flexibility, zero unnecessary framework lock-in, functional error handling via `fpdart`, and robust async dependency injection using `GetIt`.

---

## 📦 Strata Monorepo Packages

| Package | Purpose | Primary Dependencies |
| :--- | :--- | :--- |
| **`strata_core`** | Domain entities, failures, logger contracts (`StrataLoggerInterface`), `SensitiveStorageInterface`, `AsyncState<T>`, and `UseCase` contracts. | Pure Dart (`equatable`, `fpdart`, `get_it`) |
| **`strata_network`** | Dio HTTP client wrapper (`ApiHandlerInterface`), token lifecycle management (`TokenManagerInterface`), and request cancellation (`CancelRequestManagerInterface`). | `strata_core`, `dio`, `mutex`, `internet_connection_checker_plus` |
| **`strata_storage`** | Secure persistence adapters (`FlutterSecureSensitiveStorage`), encryption key rotation, and storage directory helpers. | `strata_core`, `flutter_secure_storage`, `path_provider` |
| **`strata_state`** | BLoC & state management, `AsyncHostMixin`, `AsyncHandler`, `AsyncBuilder`, persistent Cubits (`ThemeCubit`, `LocalizationCubit`, `PlatformCubit`), and Value Selectors. | `strata_core`, `flutter_bloc`, `hydrated_bloc` |
| **`strata_ui`** | Decoupled UI components (`StrataPaginationWidget`, form fields, `CoreImage`, `CoreCarousel`), theme/spacing constants, and reactive wrappers. | `strata_core`, `flutter`, `skeletonizer` |
| **`strata`** | Meta-package orchestrating `StrataInitializer` and exporting all sub-packages for single-line app setup. | All Strata sub-packages |

---

## 🚀 Quick Start

### 1. Add Dependency

Add the orchestrator meta-package `strata` (or specific sub-packages) to your application's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  strata:
    path: path/to/strata # or pub version when published
```

### 2. Framework Initialization

Initialize all Strata sub-packages in `main.dart` using `StrataInitializer.initialize()`:

```dart
import 'package:flutter/material.dart';
import 'package:strata/strata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final strataConfig = StrataConfigEntity(
    networkConfig: const NetworkConfigEntity(
      baseUrl: 'https://api.example.com',
      excludedPaths: ['/login', '/register'],
      refreshTokenApiEndpoint: '/auth/refresh',
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
      enableRetry: true,
      maxRetryAttempts: 3,
      retryInterval: Duration(seconds: 2),
    ),
    navigationConfig: NavigationConfigEntity(
      routes: $appRoutes, // GoRouter routes
      initialLocation: '/',
    ),
  );

  // Single-line framework setup (registers GetIt singletons and awaits getIt.allReady())
  await StrataInitializer.initialize(strataConfig);

  runApp(const MyApp());
}
```

---

## 📖 Module Usage Guide

### 🌐 1. Networking (`strata_network`)

Strata provides a type-safe API handler (`ApiHandlerInterface`) wrapping all network requests in `Either<Failure, T>`, enabling functional error handling.

#### Making Requests (GET, POST, PUT, DELETE)

```dart
import 'package:get_it/get_it.dart';
import 'package:strata/strata.dart';

final apiHandler = GetIt.I<ApiHandlerInterface>();

// GET request returning Either<Failure, List<User>>
final result = await apiHandler.get<List<User>>(
  '/users',
  parser: (json) => (json['data'] as List)
      .map((item) => User.fromJson(item as Map<String, dynamic>))
      .toList(),
  queryParameters: {'page': 1, 'limit': 20},
  isAuthorized: true,
  requestId: 'fetch-users', // Optional ID for request cancellation
);

// Process functional result
result.fold(
  (failure) => print('Error [${failure.code}]: ${failure.message}'),
  (users) => print('Fetched ${users.length} users'),
);
```

#### Request Cancellation

Track and cancel pending network requests using `CancelRequestManagerInterface`:

```dart
final cancelManager = GetIt.I<CancelRequestManagerInterface>();

// Trigger network call with a requestId
apiHandler.get('/heavy-report', requestId: 'report-job', parser: (j) => j);

// Cancel specific request by ID when user navigates away
cancelManager.cancelRequest('report-job', reason: 'User navigated away');
```

#### Per-Request Retry Configuration

Override global retry behavior on specific API endpoints:

```dart
// Custom retry configuration for critical request
final result = await apiHandler.post<Map<String, dynamic>>(
  '/transactions',
  parser: (json) => json,
  body: {'amount': 100},
  enableRetry: true,
  maxRetryAttempts: 5,
  retryDelay: const Duration(seconds: 3),
);

// Disable retry for non-idempotent or one-off operations
final uploadResult = await apiHandler.post<Unit>(
  '/upload',
  parser: (_) => unit,
  enableRetry: false,
);
```

#### Network Status Monitoring

Check network connectivity or listen to live changes:

```dart
final networkStatus = GetIt.I<NetworkStatusInterface>();

// Check current status
bool online = await networkStatus.isConnected;

// Listen to network status stream
networkStatus.connectionStream.listen((status) {
  if (status == ConnectionStatus.disconnected) {
    print('Network connection lost');
  }
});
```

---

### 🔑 2. Secure Storage (`strata_storage`)

Strata provides encrypted key-value persistence through `SensitiveStorageInterface` implemented by `FlutterSecureSensitiveStorage`.

> **Database Neutrality Notice:** Strata does NOT impose generic key-value database wrappers (`NoSqlDatabaseInterface`). Feature repositories interact directly with native database engines (Drift, Isar, Hive) while using `SensitiveStorageInterface` for secure credentials and encryption keys.

#### Storing & Retrieving Credentials

```dart
final secureStorage = GetIt.I<SensitiveStorageInterface>();

// Save sensitive item
final saveResult = await secureStorage.save('api_token', 'secret_jwt_token');

// Read sensitive item
final readResult = await secureStorage.read('api_token');
readResult.fold(
  (failure) => print('Storage read error: ${failure.message}'),
  (token) => print('Read token: $token'),
);

// Delete item or clear all
await secureStorage.delete('api_token');
await secureStorage.deleteAll();
```

#### Storage Encryption Key Rotation & Helpers

```dart
// Generate or retrieve encryption keys for database engines (e.g. Hive/Drift)
final keyBytes = await StorageEncryptionKeyHelper.getOrCreateEncryptionKey(
  storage: secureStorage,
  keyName: 'db_encryption_key',
);

// Resolve application storage directory for database engines
final dbDir = await StorageDirectoryHelper.getDatabaseDirectory(
  subDirectory: 'user_data',
);
```

---

### 🔄 3. State Management (`strata_state`)

Strata decouples pure `AsyncState<T>` from BLoC, allowing lightweight state modeling with `AsyncHostMixin`, `AsyncHandler`, and `AsyncBuilder`.

#### Pure `AsyncState<T>` Representation

```dart
// AsyncState<T> variants: Initial, Loading, Success, Failure
const state = AsyncState<String>.loading();

state.when(
  initial: () => print('Initial'),
  loading: () => print('Loading...'),
  success: (data) => print('Data: $data'),
  failure: (failure, retry) => print('Error: ${failure.message}'),
);
```

#### Building Cubits with `AsyncHostMixin`

`AsyncHostMixin` provides streamlined async handling with state safety and automatic Cubit disposal cleanup:

```dart
@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default(AsyncState.initial()) AsyncState<List<User>> usersState,
  }) = _UserState;
}

class UserCubit extends Cubit<UserState> with AsyncHostMixin<UserState> {
  final UserRepositoryInterface _repository;

  late final _usersHandler = createAsyncHandler<List<User>>(
    getAsyncState: (state) => state.usersState,
    setAsyncState: (state, asyncState) => state.copyWith(usersState: asyncState),
  );

  UserCubit(this._repository) : super(const UserState());

  Future<void> fetchUsers({bool force = false}) async {
    await _usersHandler.handleAsync(
      asyncCall: (params) => _repository.getUsers(params),
      params: const PagePaginationParams(page: 1, limit: 20),
      force: force, // Force re-execution even if currently loading
    );
  }
}
```

#### Rendering State in UI with `AsyncBuilder`

```dart
AsyncBuilder<UserState, List<User>>(
  bloc: context.read<UserCubit>(),
  getAsyncState: (state) => state.usersState,
  loadingBuilder: (context) => const CircularProgressIndicator(),
  successBuilder: (context, users) => ListView.builder(
    itemCount: users.length,
    itemBuilder: (context, index) => Text(users[index].name),
  ),
  errorBuilder: (context, failure, onRetry) => ElevatedButton(
    onPressed: onRetry,
    child: Text('Retry (${failure.message})'),
  ),
)
```

#### Hydrated Cubits (`ThemeCubit`, `LocalizationCubit`, `PlatformCubit`)

Strata includes pre-built persisted Cubits using `HydratedBloc`:

```dart
// Theme Management
context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);

// Locale / Language Management
context.read<LocalizationCubit>().changeLanguage(const Locale('ar'));

// Access Platform & Device Information
final platformCubit = context.read<PlatformCubit>();
final deviceInfo = platformCubit.deviceInfo;
print('Device: ${deviceInfo.model} (${deviceInfo.manufacturer}), OS: ${deviceInfo.osVersion}');
print('Platform: ${platformCubit.currentPlatform.name}, Is Mobile: ${platformCubit.isMobile}');
```

---

### 🎨 4. UI Components (`strata_ui`)

`strata_ui` contains decoupled, responsive UI components isolated from router dependencies.

#### High-Performance Paginated List (`StrataPaginationWidget`)

`StrataPaginationWidget` provides platform-adaptive pull-to-refresh (`RefreshIndicator.adaptive`), infinite load-more via scroll notifications, full-screen and bottom loading states (`Skeletonizer`), inline page-N retry bar, desktop shortcuts (`Ctrl+R` / `Cmd+R`), and offline cache badges:

```dart
StrataPaginationWidget<ProductItem, PaginationMetaModel>(
  state: paginationState,
  onRefresh: () async => context.read<ProductBloc>().add(const RefreshProducts()),
  onLoadMore: () async => context.read<ProductBloc>().add(const LoadMoreProducts()),
  emptyEntity: ProductItem.empty,
  scrollableBuilder: (context, controller, items) {
    return ListView.separated(
      controller: controller,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
    );
  },
)
```

#### Form Input Widgets

```dart
// Text Field with Label and Validation
CoreTextField(
  label: 'Email Address',
  validator: (val) => val == null || val.isEmpty ? 'Email is required' : null,
)

// PIN / OTP Code Input Field
CorePinCodeField(
  length: 6,
  onCompleted: (pin) => print('Entered PIN: $pin'),
)
```

#### Image & Display Components

```dart
CoreImage.network(
  'https://example.com/avatar.jpg',
  width: 100,
  height: 100,
  borderRadius: BorderRadiusManager.circular12,
)
```

#### Reactive Application Wrappers

Wrap your root app widget with reactive framework builders:

```dart
ThemeWrapper(
  builder: (context, themeMode) => LocalizationWrapper(
    builder: (context, locale) => MaterialApp.router(
      themeMode: themeMode,
      locale: locale,
      routerConfig: GetIt.I<GoRouter>(),
    ),
  ),
)
```

---

## 🛠️ Monorepo Commands (Melos)

When working inside the Strata monorepo root, execute workspace commands using **Melos**:

```bash
# Bootstrap all package dependencies
melos bootstrap

# Run Dart analysis across all 7 packages
melos run analyze

# Run unit & widget tests across all sub-packages
melos run test
```

---

## 🤝 Contributing

Contributions are welcome! Please follow the sub-package dependency boundary rules specified in `AGENTS.md` and `GLOSSARY.md`.

**Built with ❤️ for scalable Flutter development**
