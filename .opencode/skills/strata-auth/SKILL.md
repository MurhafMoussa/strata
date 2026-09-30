---
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

        await _tokenManager.saveTokens(
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
    final token = await _tokenManager.getAccessToken();
    return Right(token != null && token.isNotEmpty);
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
