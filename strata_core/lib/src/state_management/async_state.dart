import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../error_handling/failures/failure.dart';

/// Pure functional async state representation for asynchronous workflows.
sealed class AsyncState<T> extends Equatable {
  const AsyncState();

  const factory AsyncState.initial() = AsyncStateInitial<T>;

  const factory AsyncState.loading() = AsyncStateLoading<T>;

  const factory AsyncState.success(T data) = AsyncStateSuccess<T>;

  const factory AsyncState.failure(
    Failure failure, {
    void Function()? retryFunction,
  }) = AsyncStateFailure<T>;

  bool get isInitial => this is AsyncStateInitial<T>;
  bool get isLoading => this is AsyncStateLoading<T>;
  bool get isSuccess => this is AsyncStateSuccess<T>;
  bool get isFailure => this is AsyncStateFailure<T>;

  Option<T> get data => switch (this) {
        AsyncStateSuccess<T>(:final value) => some(value),
        _ => none(),
      };

  T? get dataOrNull => data.toNullable();

  Option<Failure> get failureObject => switch (this) {
        AsyncStateFailure<T>(:final failure) => some(failure),
        _ => none(),
      };

  Failure? get failureOrNull => failureObject.toNullable();

  void Function()? get retryFunction => switch (this) {
        AsyncStateFailure<T>(:final retryFunction) => retryFunction,
        _ => null,
      };

  /// Pattern matching helper
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Failure failure, void Function()? retryFunction)
        failure,
  }) {
    final failureCb = failure;
    return switch (this) {
      AsyncStateInitial<T>() => initial(),
      AsyncStateLoading<T>() => loading(),
      AsyncStateSuccess<T>(:final value) => success(value),
      AsyncStateFailure<T>(failure: final f, retryFunction: final r) =>
        failureCb(f, r),
    };
  }

  /// Optional pattern matching helper
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Failure failure, void Function()? retryFunction)? failure,
  }) {
    final failureCb = failure;
    return switch (this) {
      AsyncStateInitial<T>() => initial != null ? initial() : orElse(),
      AsyncStateLoading<T>() => loading != null ? loading() : orElse(),
      AsyncStateSuccess<T>(:final value) =>
        success != null ? success(value) : orElse(),
      AsyncStateFailure<T>(failure: final f, retryFunction: final r) =>
        failureCb != null ? failureCb(f, r) : orElse(),
    };
  }
}

/// Initial state before any request has started.
final class AsyncStateInitial<T> extends AsyncState<T> {
  const AsyncStateInitial();

  @override
  List<Object?> get props => [];
}

/// Loading state while the async request is executing.
final class AsyncStateLoading<T> extends AsyncState<T> {
  const AsyncStateLoading();

  @override
  List<Object?> get props => [];
}

/// Success state containing the result [value].
final class AsyncStateSuccess<T> extends AsyncState<T> {
  const AsyncStateSuccess(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

/// Failure state containing the [failure] and optional [retryFunction].
final class AsyncStateFailure<T> extends AsyncState<T> {
  const AsyncStateFailure(this.failure, {this.retryFunction});

  final Failure failure;
  @override
  final void Function()? retryFunction;

  @override
  List<Object?> get props => [failure, retryFunction];
}
