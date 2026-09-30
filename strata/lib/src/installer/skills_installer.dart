import 'dart:io';

/// Options parsed from command-line arguments for the Strata skills installer.
class InstallSkillsOptions {
  const InstallSkillsOptions({
    this.isHelp = false,
    this.installClaude = false,
    this.isGlobal = false,
    this.force = false,
    this.targetDir,
  });

  /// Whether the `--help` flag was provided.
  final bool isHelp;

  /// Whether to install skills for Claude Code (`.claude/skills/`).
  final bool installClaude;

  /// Whether to install skills globally in the user's home configuration directory.
  final bool isGlobal;

  /// Whether to overwrite existing skills if already present.
  final bool force;

  /// Custom destination directory if explicitly specified.
  final String? targetDir;

  /// Parses CLI arguments into an [InstallSkillsOptions] instance.
  static InstallSkillsOptions parse(List<String> args) {
    var isHelp = false;
    var installClaude = false;
    var isGlobal = false;
    var force = false;
    String? targetDir;

    for (final arg in args) {
      if (arg == '-h' || arg == '--help') {
        isHelp = true;
      } else if (arg == '--claude') {
        installClaude = true;
      } else if (arg == '--global') {
        isGlobal = true;
      } else if (arg == '--force' || arg == '-f') {
        force = true;
      } else if (arg.startsWith('--target-dir=')) {
        targetDir = arg.substring('--target-dir='.length);
      } else if (arg.startsWith('--target=')) {
        targetDir = arg.substring('--target='.length);
      }
    }

    return InstallSkillsOptions(
      isHelp: isHelp,
      installClaude: installClaude,
      isGlobal: isGlobal,
      force: force,
      targetDir: targetDir,
    );
  }
}

/// The embedded skill definitions for the Strata framework.
class StrataSkillsManifest {
  const StrataSkillsManifest._();

  static const String strataRouter = r'''---
name: strata
description: Router and architecture guide for the Strata Flutter & Dart framework. Routes to specialized skills for bootstrapping, authentication, clean feature slicing, and pagination.
disable-model-invocation: true
---

# Strata Framework Router

Strata is an enterprise modular Flutter & Dart framework decomposed into focused sub-packages:
- `strata_core`: Pure Dart contracts, domain entities, `ResultFuture<T>` (`Either<Failure, T>`), `AsyncState<T>`, `SensitiveStorageInterface`, `PaginationStrategy`.
- `strata_network`: `ApiHandlerInterface` (Dio wrapper), `TokenManagerInterface`, `CancelRequestManagerInterface`.
- `strata_storage`: `FlutterSecureSensitiveStorage`, encryption key helpers, directory setup.
- `strata_state`: `AsyncHostMixin`, `AsyncHandler`, `StrataPaginationBloc`, persistent cubits (`ThemeCubit`, `LocalizationCubit`).
- `strata_ui`: `AsyncBuilder`, `StrataPaginationWidget`, platform-adaptive widgets, responsive helpers.
- `strata`: Meta-package orchestrating `StrataInitializer` and exporting all sub-packages.

---

## 🧭 Selecting a Workflow

Diagnose the consumer's current goal and route to the corresponding specialized skill:

| Goal / Task | Specialized Skill | Command |
| :--- | :--- | :--- |
| **New Project / App Setup**<br>Setting up `main.dart`, `StrataInitializer`, `StrataConfigEntity`, DI registration | `strata-bootstrap` | `@strata-bootstrap` |
| **Authentication & Tokens**<br>Setting up login/logout, `TokenManagerInterface`, auto-refresh interceptors, `AuthBloc` | `strata-auth` | `@strata-auth` |
| **Clean Feature Implementation**<br>Scaffolding Feature-First Clean Architecture (`domain/`, `data/`, `presentation/`), UseCase, BLoC, and `AsyncBuilder` UI | `strata-feature` | `@strata-feature` |
| **Infinite Scroll & Pagination**<br>Wiring `StrataPaginationBloc` with `StrataPaginationWidget`, Page/Cursor strategies, and caching | `strata-pagination` | `@strata-pagination` |

---

## 📋 Strata Architecture Principles

When implementing or reviewing Strata code, enforce these non-negotiable rules:

1. **Domain Isolation**:
   - The domain layer (`domain/entities`, `domain/usecases`, `domain/repositories`) must depend **only** on `strata_core` and `fpdart`.
   - Domain never imports Flutter, Dio, `strata_network`, or data models.
2. **Functional Error Handling**:
   - Asynchronous use cases return `ResultFuture<T>` (defined as `Future<Either<Failure, T>>`).
   - Use cases extend `ResultFutureUseCase<Output, Input>`.
3. **Reactive Async State Management**:
   - BLoCs and Cubits managing asynchronous operations mix in `AsyncHostMixin<CompositeState>`.
   - Manage async fields using `createAsyncHandler<SuccessData>(...)`.
   - Always call `handler.dispose()` via the mixin's automatic `close()` hook.
4. **Deterministic Unit Testing**:
   - Every Domain UseCase and State BLoC must have companion unit tests using `bloc_test` and `mocktail`.
   - Test all lifecycle states: `initial`, `loading`, `success`, and `failure`.
''';

  static const String strataBootstrap = r'''---
name: strata-bootstrap
description: Set up and bootstrap the Strata framework in a Flutter project, including StrataInitializer, StrataConfigEntity, dependency injection with GetIt, and network configuration.
---

# Strata Bootstrap Skill

Bootstrap and configure the Strata framework in a Flutter application.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Verify & Add Dependencies
Inspect the host application's `pubspec.yaml`:
1. Check if `strata` is in `dependencies:`.
2. If missing, add it via:
   ```bash
   flutter pub add strata
   ```
   *(Or specify the monorepo path if developing locally).*
3. Ensure `get_it` is available (exported by `strata`, but can be explicitly declared).
4. Run `flutter pub get`.

---

### Step 2: Configure `StrataConfigEntity`
Create or update your app configuration file (e.g., `lib/core/config/app_strata_config.dart` or directly in `main.dart`):

```dart
import 'package:strata/strata.dart';

StrataConfigEntity createStrataConfig({
  required String baseUrl,
  bool isDebug = true,
}) {
  return StrataConfigEntity(
    networkConfig: NetworkConfigEntity(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
      refreshTokenApiEndpoint: '/auth/refresh',
      excludedPaths: const ['/auth/login', '/auth/register', '/auth/refresh'],
      enableRetry: true,
      maxRetryAttempts: 3,
      retryInterval: const Duration(seconds: 2),
    ),
    logger: isDebug ? null : null, // Uses default Strata talker logger if null
  );
}
```

---

### Step 3: Wire `main.dart`
Update `main.dart` to initialize Flutter bindings and run `StrataInitializer.initialize(...)` prior to `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:strata/strata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final strataConfig = StrataConfigEntity(
    networkConfig: const NetworkConfigEntity(
      baseUrl: 'https://api.example.com',
      accessTokenKey: 'access_token',
      refreshTokenKey: 'refresh_token',
      refreshTokenApiEndpoint: '/auth/refresh',
      excludedPaths: ['/auth/login', '/auth/register'],
      enableRetry: true,
    ),
  );

  // Initializes strata_core, strata_storage, strata_network, strata_state, strata_ui
  await StrataInitializer.initialize(strataConfig);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Strata Application',
      home: Scaffold(
        body: Center(
          child: Text('Strata Initialized Successfully'),
        ),
      ),
    );
  }
}
```

---

### Step 4: Verification
Execute static analysis to ensure all imports and configurations compile cleanly:
```bash
flutter analyze
```

**Completion Criteria**: `flutter analyze` completes with zero errors, and `StrataInitializer.initialize` is awaited before `runApp`.

---

### Step 5: Auth Handoff Prompt
Once bootstrap completes successfully, ask the developer:
> *"Strata initialization is complete! Would you like to set up the authentication and token lifecycle now using `@strata-auth`?"*
''';

  static const String strataAuth = r'''---
name: strata-auth
description: Implement authentication and token lifecycle in a Strata Flutter application, including SensitiveStorageInterface, TokenManagerInterface, auto-refresh interceptors, AuthBloc, and login/logout use cases.
---

# Strata Auth Skill

Implement and manage the authentication lifecycle in a Strata application, integrating `TokenManagerInterface`, `SensitiveStorageInterface`, `AuthBloc`, and clean-architecture login/logout use cases.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Verify Dependencies
Check `pubspec.yaml` and ensure required packages are present:
```bash
flutter pub add flutter_bloc fpdart
flutter pub add -d bloc_test mocktail
```

---

### Step 2: Autonomous Detection (Greenfield vs. Refactor)
Check `lib/features/auth/`:
- **If directory is empty or does not exist**: Proceed to **Greenfield Scaffolding** (Step 3).
- **If existing authentication files exist**: Perform **In-Place Migration** (Step 3-Refactor):
  - Replace raw HTTP auth calls with `ApiHandlerInterface.post(...)`.
  - Replace custom token persistence with `GetIt.I<TokenManagerInterface>()`.
  - Refactor existing auth BLoC/Cubit to mix in `AsyncHostMixin` and wrap state with `AsyncState`.

---

### Step 3: Greenfield Architecture Scaffolding

#### 1. Domain Entities & Usecases
`lib/features/auth/domain/entities/auth_tokens_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class AuthTokensEntity extends Equatable {
  const AuthTokensEntity({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
```

`lib/features/auth/domain/repositories/auth_repository_interface.dart`:
```dart
import 'package:strata/strata.dart';
import '../entities/auth_tokens_entity.dart';

abstract class AuthRepositoryInterface {
  ResultFuture<AuthTokensEntity> login({
    required String username,
    required String password,
  });

  ResultFuture<void> logout();

  ResultFuture<bool> isAuthenticated();
}
```

`lib/features/auth/domain/usecases/login_usecase.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../entities/auth_tokens_entity.dart';
import '../repositories/auth_repository_interface.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.username, required this.password});
  final String username;
  final String password;

  @override
  List<Object?> get props => [username, password];
}

class LoginUseCase extends ResultFutureUseCase<AuthTokensEntity, LoginParams> {
  const LoginUseCase(this._repository);
  final AuthRepositoryInterface _repository;

  @override
  ResultFuture<AuthTokensEntity> call(LoginParams input) {
    return _repository.login(
      username: input.username,
      password: input.password,
    );
  }
}
```

#### 2. Data Repository Implementation
`lib/features/auth/data/repositories/auth_repository.dart`:
```dart
import 'package:fpdart/fpdart.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/repositories/auth_repository_interface.dart';

class AuthRepository implements AuthRepositoryInterface {
  AuthRepository({
    required ApiHandlerInterface apiHandler,
    required TokenManagerInterface tokenManager,
  })  : _apiHandler = apiHandler,
        _tokenManager = tokenManager;

  final ApiHandlerInterface _apiHandler;
  final TokenManagerInterface _tokenManager;

  @override
  ResultFuture<AuthTokensEntity> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiHandler.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
      isAuthorized: false,
    );

    return response.fold(
      Left.new,
      (data) async {
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;

        await _tokenManager.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        return Right(AuthTokensEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ));
      },
    );
  }

  @override
  ResultFuture<void> logout() async {
    await _tokenManager.clearTokens();
    return const Right(null);
  }

  @override
  ResultFuture<bool> isAuthenticated() async {
    final token = await _tokenManager.accessToken;
    return Right(token.isNotEmpty);
  }
}
```

#### 3. Presentation State & BLoC
`lib/features/auth/presentation/blocs/auth_state.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/auth_tokens_entity.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.loginState = const AsyncState.initial(),
  });

  final AuthStatus status;
  final AsyncState<AuthTokensEntity> loginState;

  AuthState copyWith({
    AuthStatus? status,
    AsyncState<AuthTokensEntity>? loginState,
  }) {
    return AuthState(
      status: status ?? this.status,
      loginState: loginState ?? this.loginState,
    );
  }

  @override
  List<Object?> get props => [status, loginState];
}
```

`lib/features/auth/presentation/blocs/auth_bloc.dart`:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_state.dart';

abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  AuthLoginRequested(this.username, this.password);
  final String username;
  final String password;
}
class AuthLogoutRequested extends AuthEvent {}

class AuthBloc extends Bloc<AuthEvent, AuthState> with AsyncHostMixin<AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required TokenManagerInterface tokenManager,
  })  : _loginUseCase = loginUseCase,
        _tokenManager = tokenManager,
        super(const AuthState()) {
    _loginHandler = createAsyncHandler<AuthTokensEntity>(
      getAsyncState: (state) => state.loginState,
      setAsyncState: (state, asyncState) => state.copyWith(
        loginState: asyncState,
        status: asyncState is AsyncStateSuccess<AuthTokensEntity>
            ? AuthStatus.authenticated
            : state.status,
      ),
    );

    on<AuthLoginRequested>((event, emit) async {
      await _loginHandler.execute(
        () => _loginUseCase(LoginParams(
          username: event.username,
          password: event.password,
        )),
      );
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _tokenManager.clearTokens();
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        loginState: const AsyncState.initial(),
      ));
    });
  }

  final LoginUseCase _loginUseCase;
  final TokenManagerInterface _tokenManager;
  late final AsyncHandler<AuthState, AuthTokensEntity> _loginHandler;
}
```

---

### Step 4: Companion Unit Tests
Create `test/features/auth/presentation/blocs/auth_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata/strata.dart';

import 'package:my_app/features/auth/domain/entities/auth_tokens_entity.dart';
import 'package:my_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:my_app/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:my_app/features/auth/presentation/blocs/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockTokenManager extends Mock implements TokenManagerInterface {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockTokenManager mockTokenManager;

  setUpAll(() {
    registerFallbackValue(const LoginParams(username: '', password: ''));
  });

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockTokenManager = MockTokenManager();
  });

  const tTokens = AuthTokensEntity(
    accessToken: 'access-123',
    refreshToken: 'refresh-123',
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, success with authenticated status] on successful login',
    build: () {
      when(() => mockLoginUseCase(any())).thenAnswer((_) async => const Right(tTokens));
      return AuthBloc(
        loginUseCase: mockLoginUseCase,
        tokenManager: mockTokenManager,
      );
    },
    act: (bloc) => bloc.add(AuthLoginRequested('testuser', 'password')),
    expect: () => [
      const AuthState(loginState: AsyncState.loading()),
      const AuthState(
        status: AuthStatus.authenticated,
        loginState: AsyncState.success(tTokens),
      ),
    ],
  );
}
```

---

### Step 5: Verification & Completion
Run analysis and the test suite:
```bash
flutter analyze
flutter test test/features/auth
```

**Completion Criteria**: Zero analyzer issues and all auth BLoC unit tests pass.
''';

  static const String strataFeature = r'''---
name: strata-feature
description: Scaffold or refactor a feature using Feature-First Clean Architecture in Strata, including ResultFutureUseCase, ApiHandlerInterface, AsyncHostMixin, AsyncHandler, AsyncBuilder, and companion bloc_test suites.
---

# Strata Feature Skill

Scaffold a production-grade, test-backed feature slice conforming to Strata's Feature-First Clean Architecture.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Autonomous Dependency Inspection
Inspect `pubspec.yaml`. Automatically add any missing packages:
```bash
flutter pub add flutter_bloc fpdart
flutter pub add -d bloc_test mocktail
```

---

### Step 2: Autonomous Greenfield vs. Refactor Detection
Inspect the target directory `lib/features/<feature_name>/`:
- **Greenfield**: If empty or missing, proceed to **Step 3 (Greenfield Generation)**.
- **Refactor**: If existing feature code is found:
  1. Inspect existing models and API calls; convert raw `http`/`dio` calls to `GetIt.I<ApiHandlerInterface>()`.
  2. Ensure domain contracts use `ResultFuture<T>` (`Future<Either<Failure, T>>`).
  3. Refactor state classes to contain `AsyncState<T>`.
  4. Add `with AsyncHostMixin<State>` to the BLoC/Cubit and replace manual loading/error handling with `createAsyncHandler`.
  5. Refactor UI widgets to use `AsyncBuilder`.
  6. Jump to **Step 4 (Tests)** and **Step 5 (Verification)**.

---

### Step 3: Greenfield Scaffolding

Given a feature name (e.g., `product`), scaffold the following files:

#### 1. Domain Layer (`lib/features/product/domain/`)

`entities/product_entity.dart`:
```dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  @override
  List<Object?> get props => [id, name, price];
}
```

`repositories/product_repository_interface.dart`:
```dart
import 'package:strata/strata.dart';
import '../entities/product_entity.dart';

abstract class ProductRepositoryInterface {
  ResultFuture<ProductEntity> getProduct(String id);
}
```

`usecases/get_product_usecase.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository_interface.dart';

class GetProductParams extends Equatable {
  const GetProductParams({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];
}

class GetProductUseCase extends ResultFutureUseCase<ProductEntity, GetProductParams> {
  const GetProductUseCase(this._repository);
  final ProductRepositoryInterface _repository;

  @override
  ResultFuture<ProductEntity> call(GetProductParams input) {
    return _repository.getProduct(input.id);
  }
}
```

#### 2. Data Layer (`lib/features/product/data/`)

`models/product_model.dart`:
```dart
import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };
}
```

`repositories/product_repository.dart`:
```dart
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository_interface.dart';
import '../models/product_model.dart';

class ProductRepository implements ProductRepositoryInterface {
  ProductRepository(this._apiHandler);
  final ApiHandlerInterface _apiHandler;

  @override
  ResultFuture<ProductEntity> getProduct(String id) {
    return _apiHandler.get<ProductEntity>(
      '/products/$id',
      parser: (json) => ProductModel.fromJson(json as Map<String, dynamic>),
      isAuthorized: true,
      requestId: 'get-product-$id',
    );
  }
}
```

#### 3. Presentation Layer (`lib/features/product/presentation/`)

`blocs/product_state.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';

class ProductState extends Equatable {
  const ProductState({
    this.productState = const AsyncState.initial(),
  });

  final AsyncState<ProductEntity> productState;

  ProductState copyWith({
    AsyncState<ProductEntity>? productState,
  }) {
    return ProductState(
      productState: productState ?? this.productState,
    );
  }

  @override
  List<Object?> get props => [productState];
}
```

`blocs/product_bloc.dart`:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_usecase.dart';
import 'product_state.dart';

abstract class ProductEvent {}
class ProductFetchRequested extends ProductEvent {
  ProductFetchRequested(this.id);
  final String id;
}

class ProductBloc extends Bloc<ProductEvent, ProductState>
    with AsyncHostMixin<ProductState> {
  ProductBloc(this._getProductUseCase) : super(const ProductState()) {
    _productHandler = createAsyncHandler<ProductEntity>(
      getAsyncState: (state) => state.productState,
      setAsyncState: (state, asyncState) => state.copyWith(productState: asyncState),
    );

    on<ProductFetchRequested>((event, emit) async {
      await _productHandler.execute(
        () => _getProductUseCase(GetProductParams(id: event.id)),
      );
    });
  }

  final GetProductUseCase _getProductUseCase;
  late final AsyncHandler<ProductState, ProductEntity> _productHandler;
}
```

`pages/product_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/product_entity.dart';
import '../blocs/product_bloc.dart';
import '../blocs/product_state.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductBloc>();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: AsyncBuilder<ProductState, ProductEntity>(
        bloc: bloc,
        getAsyncState: (state) => state.productState,
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        errorBuilder: (context, failure, retry) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error: ${failure.message}'),
              if (retry != null)
                ElevatedButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
        successBuilder: (context, product) => Center(
          child: Text('Product: ${product.name} (\$${product.price})'),
        ),
      ),
    );
  }
}
```

---

### Step 4: Companion Unit Tests
Generate `test/features/product/presentation/blocs/product_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata/strata.dart';

import 'package:my_app/features/product/domain/entities/product_entity.dart';
import 'package:my_app/features/product/domain/usecases/get_product_usecase.dart';
import 'package:my_app/features/product/presentation/blocs/product_bloc.dart';
import 'package:my_app/features/product/presentation/blocs/product_state.dart';

class MockGetProductUseCase extends Mock implements GetProductUseCase {}

void main() {
  late MockGetProductUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(const GetProductParams(id: ''));
  });

  setUp(() {
    mockUseCase = MockGetProductUseCase();
  });

  const tProduct = ProductEntity(id: '1', name: 'Coffee', price: 4.5);

  blocTest<ProductBloc, ProductState>(
    'emits [loading, success] when product fetch succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const Right(tProduct));
      return ProductBloc(mockUseCase);
    },
    act: (bloc) => bloc.add(ProductFetchRequested('1')),
    expect: () => [
      const ProductState(productState: AsyncState.loading()),
      const ProductState(productState: AsyncState.success(tProduct)),
    ],
  );

  blocTest<ProductBloc, ProductState>(
    'emits [loading, failure] when product fetch fails',
    build: () {
      when(() => mockUseCase(any())).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );
      return ProductBloc(mockUseCase);
    },
    act: (bloc) => bloc.add(ProductFetchRequested('1')),
    expect: () => [
      const ProductState(productState: AsyncState.loading()),
      const ProductState(
        productState: AsyncState.failure(
          ServerFailure(message: 'Not found', code: 404),
        ),
      ),
    ],
  );
}
```

---

### Step 5: Verification & Compilation
Run static analysis and test execution:
```bash
flutter analyze
flutter test test/features/<feature_name>
```

**Completion Criteria**: Zero analyzer errors, clean package boundaries, and all companion tests pass.
''';

  static const String strataPagination = r'''---
name: strata-pagination
description: Implement infinite scrolling and pagination using StrataPaginationBloc and StrataPaginationWidget, supporting Page, Skip, and Cursor strategies, offline caching, and companion unit tests.
---

# Strata Pagination Skill

Implement high-performance, pull-to-refresh infinite scrolling lists using `StrataPaginationBloc` and `StrataPaginationWidget`.

---

## 🛠️ Step-by-Step Workflow

### Step 1: Dependencies Verification
Inspect `pubspec.yaml` and ensure required packages exist:
```bash
flutter pub add flutter_bloc
flutter pub add -d bloc_test mocktail
```

---

### Step 2: Pagination Scheme Selection
Determine the pagination mechanic used by the target API endpoint:
- **Page Scheme** (`page`, `limit`, `totalCount`): Use `PagePaginationStrategy` and `PagePaginationParams`.
- **Skip/Offset Scheme** (`skip`, `limit`, `totalCount`): Use `SkipPaginationStrategy` and `SkipPaginationParams`.
- **Cursor Scheme** (`cursor`, `limit`): Use `CursorPaginationStrategy` and `CursorPaginationParams`.

*Tip*: If unsure, inspect a sample backend response JSON:
```json
// Example Page-based JSON:
{ "data": [...], "meta": { "page": 1, "limit": 20, "total_count": 100 } }
// Example Cursor-based JSON:
{ "data": [...], "meta": { "cursor": "eyJpZCI6MTAwfQ==", "limit": 20 } }
```

---

### Step 3: Greenfield Scaffolding

Given an entity (e.g. `Order`):

#### 1. Entity Implementing `Identifiable<String>`
`lib/features/orders/domain/entities/order_entity.dart`:
```dart
import 'package:equatable/equatable.dart';
import 'package:strata/strata.dart';

class OrderEntity extends Equatable implements Identifiable<String> {
  const OrderEntity({
    required this.id,
    required this.title,
    required this.amount,
  });

  final String id;
  final String title;
  final double amount;

  @override
  String get identifier => id; // Used by Strata for O(N) deduplication

  @override
  List<Object?> get props => [id, title, amount];
}
```

#### 2. BLoC Factory Instantiation
`lib/features/orders/presentation/blocs/orders_pagination_bloc.dart`:
```dart
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';

StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams> createOrdersPaginationBloc({
  required ApiHandlerInterface apiHandler,
  CancelRequestManagerInterface? cancelRequestManager,
  PaginationCacheAdapterInterface<OrderEntity, PaginationMetaModel>? cacheAdapter,
  PaginationCachePolicy cachePolicy = PaginationCachePolicy.networkOnly,
}) {
  return StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>(
    paginationStrategy: const PagePaginationStrategy(),
    cancelRequestManager: cancelRequestManager,
    cacheAdapter: cacheAdapter,
    cachePolicy: cachePolicy,
    fetcher: (params, {requestId}) async {
      return apiHandler.get<PaginationResponseModel<OrderEntity, PaginationMetaModel>>(
        '/orders',
        queryParameters: {
          'page': params.page,
          'limit': params.limit,
        },
        requestId: requestId,
        parser: (json) {
          final data = (json['data'] as List)
              .map((item) => OrderEntity(
                    id: item['id'] as String,
                    title: item['title'] as String,
                    amount: (item['amount'] as num).toDouble(),
                  ))
              .toList();
          final meta = PaginationMetaModel.fromJson(
            json['meta'] as Map<String, dynamic>? ?? {},
          );
          return PaginationResponseModel(data: data, meta: meta);
        },
      );
    },
  );
}
```

#### 3. Presentation with `StrataPaginationWidget`
`lib/features/orders/presentation/pages/orders_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata/strata.dart';
import '../../domain/entities/order_entity.dart';
import '../blocs/orders_pagination_bloc.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => createOrdersPaginationBloc(
        apiHandler: GetIt.I<ApiHandlerInterface>(),
      )..add(const StrataPaginationInitialFetched()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: BlocBuilder<
          StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>,
          StrataPaginationState<OrderEntity, PaginationMetaModel>
        >(
          builder: (context, state) {
            final bloc = context.read<
              StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>
            >();

            return StrataPaginationWidget<OrderEntity, PaginationMetaModel>(
              state: state,
              onRefresh: () async => bloc.add(const StrataPaginationRefreshed()),
              onLoadMore: () async => bloc.add(const StrataPaginationMoreFetched()),
              onRetry: () => bloc.add(const StrataPaginationInitialFetched()),
              onRetryMore: () => bloc.add(const StrataPaginationMoreFetched()),
              scrollableBuilder: (context, scrollController, items) {
                return ListView.separated(
                  key: const Key('strata_pagination_list'),
                  controller: scrollController,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = items[index];
                    return ListTile(
                      title: Text(order.title),
                      subtitle: Text('ID: ${order.id}'),
                      trailing: Text('\$${order.amount.toStringAsFixed(2)}'),
                    );
                  },
                );
              },
              emptyBuilder: (context) => const Center(
                child: Text('No orders found'),
              ),
              errorBuilder: (context, failure, onRetry) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load: ${failure.message}'),
                    if (onRetry != null)
                      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### Step 4: Companion Unit Tests
Create `test/features/orders/presentation/blocs/orders_pagination_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata/strata.dart';

import 'package:my_app/features/orders/domain/entities/order_entity.dart';
import 'package:my_app/features/orders/presentation/blocs/orders_pagination_bloc.dart';

class MockApiHandler extends Mock implements ApiHandlerInterface {}

void main() {
  late MockApiHandler mockApiHandler;

  setUpAll(() {
    registerFallbackValue(
      const PaginationResponseModel<OrderEntity, PaginationMetaModel>(),
    );
  });

  setUp(() {
    mockApiHandler = MockApiHandler();
  });

  const tOrders = [
    OrderEntity(id: '1', title: 'Order 1', amount: 10.0),
    OrderEntity(id: '2', title: 'Order 2', amount: 20.0),
  ];

  const tResponse = PaginationResponseModel<OrderEntity, PaginationMetaModel>(
    data: tOrders,
    meta: PaginationMetaModel(page: 1, limit: 20, totalCount: 2),
  );

  blocTest<
    StrataPaginationBloc<OrderEntity, PaginationMetaModel, PagePaginationParams>,
    StrataPaginationState<OrderEntity, PaginationMetaModel>
  >(
    'emits [loading, succeeded] on initial fetch',
    build: () {
      when(() => mockApiHandler.get<PaginationResponseModel<OrderEntity, PaginationMetaModel>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            requestId: any(named: 'requestId'),
            parser: any(named: 'parser'),
          )).thenAnswer((_) async => const Right(tResponse));

      return createOrdersPaginationBloc(apiHandler: mockApiHandler);
    },
    act: (bloc) => bloc.add(const StrataPaginationInitialFetched()),
    expect: () => [
      const StrataPaginationState<OrderEntity, PaginationMetaModel>.loading(),
      const StrataPaginationState<OrderEntity, PaginationMetaModel>.succeeded(
        paginatedResponseModel: tResponse,
        hasReachedMax: true,
      ),
    ],
  );
}
```

---

### Step 5: Verification & Compilation
Run static analysis and test validation:
```bash
flutter analyze
flutter test test/features/<feature_name>
```

**Completion Criteria**: Zero analyzer warnings, exactly one layout builder provided (`scrollableBuilder`), and pagination BLoC tests pass with complete state coverage.
''';

  /// Map of all available skills by name.
  static const Map<String, String> allSkills = {
    'strata': strataRouter,
    'strata-bootstrap': strataBootstrap,
    'strata-auth': strataAuth,
    'strata-feature': strataFeature,
    'strata-pagination': strataPagination,
  };
}

/// Runner for installing Strata skills into local or global agent environments.
class SkillsInstaller {
  const SkillsInstaller();

  /// Prints CLI usage help.
  static void printHelp(StringSink sink) {
    sink.writeln('Strata Framework Skills Installer');
    sink.writeln('');
    sink.writeln('Usage: dart run strata:install_skills [options]');
    sink.writeln('');
    sink.writeln('Options:');
    sink.writeln('  --claude          Install skills to .claude/skills/ in addition to .opencode/skills/');
    sink.writeln('  --global          Install skills globally to ~/.config/opencode/skills/');
    sink.writeln('  --force, -f       Overwrite existing skill files');
    sink.writeln('  --target-dir=<p>  Install to a custom target directory');
    sink.writeln('  --help, -h        Show this help message');
  }

  /// Installs Strata skills according to the provided [options].
  int install(
    InstallSkillsOptions options, {
    Directory? baseDir,
    String? homeDir,
    StringSink? output,
    StringSink? errorOutput,
  }) {
    final out = output ?? stdout;
    final err = errorOutput ?? stderr;

    if (options.isHelp) {
      printHelp(out);
      return 0;
    }

    final targetDirectories = <Directory>[];

    if (options.targetDir != null && options.targetDir!.isNotEmpty) {
      targetDirectories.add(Directory(options.targetDir!));
    } else if (options.isGlobal) {
      final userHome = homeDir ??
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'];

      if (userHome == null || userHome.isEmpty) {
        err.writeln('Error: Could not resolve user home directory for --global install.');
        return 1;
      }

      final separator = Platform.pathSeparator;
      targetDirectories.add(Directory('$userHome$separator.config${separator}opencode${separator}skills'));
    } else {
      final rootPath = (baseDir ?? Directory.current).path;
      final separator = Platform.pathSeparator;
      targetDirectories.add(Directory('$rootPath$separator.opencode${separator}skills'));

      if (options.installClaude) {
        targetDirectories.add(Directory('$rootPath$separator.claude${separator}skills'));
      }
    }

    out.writeln('📦 Installing Strata Agent Skills...');

    var installedCount = 0;

    for (final baseTarget in targetDirectories) {
      for (final entry in StrataSkillsManifest.allSkills.entries) {
        final skillName = entry.key;
        final skillContent = entry.value;

        final skillDir = Directory('${baseTarget.path}${Platform.pathSeparator}$skillName');
        final skillFile = File('${skillDir.path}${Platform.pathSeparator}SKILL.md');

        if (skillFile.existsSync() && !options.force) {
          out.writeln('  - Skipped $skillName (already exists, use --force to overwrite)');
          continue;
        }

        if (!skillDir.existsSync()) {
          skillDir.createSync(recursive: true);
        }

        skillFile.writeAsStringSync(skillContent);
        out.writeln('  ✓ Installed $skillName');
        installedCount++;
      }

      out.writeln('✨ Successfully installed $installedCount skill(s) in: ${baseTarget.path}');
    }

    return 0;
  }
}
