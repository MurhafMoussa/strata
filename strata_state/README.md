# strata_state

BLoC state utilities and `AsyncHandler` lifecycle management for the Strata framework.

## Overview

`strata_state` provides BLoC/Cubit state handling delegates and UI builder widgets for managing `AsyncState<T>` transitions. It includes `AsyncHostMixin` for managing multiple async lifecycles inside a single Cubit/BLoC state, `DisposableAsyncHandlerInterface`, `AsyncHandler` with force re-execution override and automated cancellation via `CancelRequestManagerInterface`, and `AsyncBuilder` for UI rendering.

## Architectural Rules & Boundaries

- **BLoC Decoupling**: Depends ONLY on `strata_core`, `flutter`, `flutter_bloc`, `get_it`, and `skeletonizer`.
- **Zero Heavy Framework Lock-in**: Has ZERO dependencies on `strata_network`, `strata_storage`, `go_router`, or Dio.
- **Strict Boundary Enforcement**: Enforced via package dependency tests.

## Key Components

### 1. `DisposableAsyncHandlerInterface` & `AsyncHandler`
A delegate class managed by `AsyncHostMixin` that encapsulates loading, success, failure, retry, and cancellation for a specific `AsyncState` field within a composite BLoC state.

```dart
import 'package:strata_state/strata_state.dart';

// Force execution during loading state (automatically cancels any prior in-flight request)
await asyncHandler.handleAsync(
  asyncCall: fetchUserDataUseCase,
  params: userId,
  force: true,
);

// Default behavior (force: false) skips execution if state is already loading
await asyncHandler.handleAsync(
  asyncCall: fetchUserDataUseCase,
  params: userId,
  force: false,
);

// Convenience execution for parameterless calls or closures
await asyncHandler.execute(
  asyncCall: () => fetchUserDataUseCase(userId),
);
```

### 2. `AsyncHostMixin`
Mixin for `BlocBase` (Cubit/BLoC) that automatically creates and disposes `AsyncHandler` instances on `close()`.

```dart
class UserCubit extends Cubit<UserState> with AsyncHostMixin<UserState> {
  UserCubit() : super(UserState.initial()) {
    _profileHandler = createAsyncHandler(
      defaultRequestId: 'user_profile',
      getAsyncState: (state) => state.profileState,
      setAsyncState: (state, asyncState) => state.copyWith(profileState: asyncState),
    );
  }

  late final AsyncHandler<UserState, User> _profileHandler;

  Future<void> fetchProfile(String userId) async {
    await _profileHandler.handleAsync(
      asyncCall: getUserUseCase,
      params: userId,
    );
  }
}
```

### 3. `AsyncBuilder`
Flutter widget that listens to a specific `AsyncState` on a BLoC/Cubit and renders pattern-matched UI states (`initial`, `loading`, `success`, `failure`).

```dart
AsyncBuilder<UserState, User>(
  bloc: userCubit,
  getAsyncState: (state) => state.profileState,
  emptyEntity: User.empty(),
  successBuilder: (context, user) => UserProfileWidget(user: user),
);
```

## Running Tests & Audits

Run static analysis and unit tests inside the `strata_state` directory:

```bash
cd strata_state
flutter analyze
flutter test
```
