import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:strata_core/strata_core.dart';

/// Sealed hierarchy of immutable state classes representing all lifecycle phases
/// of paginated data operations within [StrataPaginationBloc].
///
/// Distinguishes initial page loading and failure from incremental page-N
/// loading (`PaginationLoadingMore`) and page-N fetch failure (`PaginationPageFetchFailure`).
///
/// `@example`
/// ```dart
/// const state = StrataPaginationState<TestItem, NoMetaModel>.succeeded(
///   paginatedResponseModel: PaginationResponseModel(data: [TestItem('1')]),
///   hasReachedMax: false,
///   isFromCache: true,
/// );
/// print(state.items.length); // 1
/// print(state.isFromCache); // true
/// print(state.hasReachedMax); // false
/// ```
sealed class StrataPaginationState<T extends Identifiable<String>, M extends MetaModel>
    extends Equatable {
  /// Const constructor for [StrataPaginationState].
  const StrataPaginationState();

  /// Initial state before any network or cache requests have been dispatched.
  const factory StrataPaginationState.initial() = PaginationInitial<T, M>;

  /// State indicating initial page loading is in flight.
  const factory StrataPaginationState.loading() = PaginationLoading<T, M>;

  /// State indicating paginated data was successfully loaded or updated.
  const factory StrataPaginationState.succeeded({
    required PaginationResponseModel<T, M> paginatedResponseModel,
    required bool hasReachedMax,
    bool isFromCache,
    bool isOffline,
  }) = PaginationSucceeded<T, M>;

  /// State indicating pull-to-refresh is in flight while retaining existing data.
  const factory StrataPaginationState.refreshing({
    required PaginationResponseModel<T, M> paginatedResponseModel,
    required bool hasReachedMax,
    bool isFromCache,
    bool isOffline,
  }) = PaginationRefreshing<T, M>;

  /// State indicating incremental page fetch (page N >= 2) is in flight while retaining existing items.
  const factory StrataPaginationState.loadingMore({
    required PaginationResponseModel<T, M> paginatedResponseModel,
    required bool hasReachedMax,
    bool isFromCache,
    bool isOffline,
  }) = PaginationLoadingMore<T, M>;

  /// State indicating initial page fetch failed with [failure].
  const factory StrataPaginationState.failed({
    required Failure failure,
    PaginationResponseModel<T, M> paginatedResponseModel,
    VoidCallback? onRetry,
  }) = PaginationFailed<T, M>;

  /// State indicating page N (N >= 2) fetch failed with [failure] while preserving existing items.
  const factory StrataPaginationState.pageFetchFailure({
    required Failure failure,
    required PaginationResponseModel<T, M> paginatedResponseModel,
    required bool hasReachedMax,
    bool isFromCache,
    bool isOffline,
    VoidCallback? onRetryMore,
  }) = PaginationPageFetchFailure<T, M>;

  /// Returns the current [PaginationResponseModel], or an empty model if uninitialized.
  PaginationResponseModel<T, M> get paginatedResponseModel => switch (this) {
        PaginationSucceeded<T, M>(:final paginatedResponseModel) => paginatedResponseModel,
        PaginationRefreshing<T, M>(:final paginatedResponseModel) => paginatedResponseModel,
        PaginationLoadingMore<T, M>(:final paginatedResponseModel) => paginatedResponseModel,
        PaginationFailed<T, M>(:final paginatedResponseModel) => paginatedResponseModel,
        PaginationPageFetchFailure<T, M>(:final paginatedResponseModel) => paginatedResponseModel,
        _ => const PaginationResponseModel(),
      };

  /// Shortcut getter returning the list of items currently held in state.
  List<T> get items => paginatedResponseModel.data;

  /// Indicates whether all pages have been fetched or total records reached.
  bool get hasReachedMax => switch (this) {
        PaginationSucceeded<T, M>(:final hasReachedMax) => hasReachedMax,
        PaginationRefreshing<T, M>(:final hasReachedMax) => hasReachedMax,
        PaginationLoadingMore<T, M>(:final hasReachedMax) => hasReachedMax,
        PaginationPageFetchFailure<T, M>(:final hasReachedMax) => hasReachedMax,
        _ => false,
      };

  /// Indicates whether the active dataset was served from offline cache.
  bool get isFromCache => switch (this) {
        PaginationSucceeded<T, M>(:final isFromCache) => isFromCache,
        PaginationRefreshing<T, M>(:final isFromCache) => isFromCache,
        PaginationLoadingMore<T, M>(:final isFromCache) => isFromCache,
        PaginationPageFetchFailure<T, M>(:final isFromCache) => isFromCache,
        _ => false,
      };

  /// Indicates whether the device or response state is operating offline.
  bool get isOffline => switch (this) {
        PaginationSucceeded<T, M>(:final isOffline) => isOffline,
        PaginationRefreshing<T, M>(:final isOffline) => isOffline,
        PaginationLoadingMore<T, M>(:final isOffline) => isOffline,
        PaginationPageFetchFailure<T, M>(:final isOffline) => isOffline,
        _ => false,
      };

  /// True if state is [PaginationLoading].
  bool get isLoading => this is PaginationLoading<T, M>;

  /// True if state is [PaginationRefreshing].
  bool get isRefreshing => this is PaginationRefreshing<T, M>;

  /// True if state is [PaginationLoadingMore].
  bool get isLoadingMore => this is PaginationLoadingMore<T, M>;

  /// True if state is [PaginationFailed].
  bool get isFailed => this is PaginationFailed<T, M>;

  /// True if state is [PaginationPageFetchFailure].
  bool get isPageFetchFailure => this is PaginationPageFetchFailure<T, M>;

  /// Returns the [Failure] if in [PaginationFailed] or [PaginationPageFetchFailure] state.
  Failure? get failure => switch (this) {
        PaginationFailed<T, M>(:final failure) => failure,
        PaginationPageFetchFailure<T, M>(:final failure) => failure,
        _ => null,
      };
}

/// Initial uninitialized state before any fetch operation.
final class PaginationInitial<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationInitial] state.
  const PaginationInitial();

  @override
  List<Object?> get props => [];
}

/// State representing an active initial page request.
final class PaginationLoading<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationLoading] state.
  const PaginationLoading();

  @override
  List<Object?> get props => [];
}

/// State representing successfully loaded paginated data.
final class PaginationSucceeded<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationSucceeded] state.
  const PaginationSucceeded({
    required this.paginatedResponseModel,
    required this.hasReachedMax,
    this.isFromCache = false,
    this.isOffline = false,
  });

  @override
  final PaginationResponseModel<T, M> paginatedResponseModel;

  @override
  final bool hasReachedMax;

  @override
  final bool isFromCache;

  @override
  final bool isOffline;

  @override
  List<Object?> get props => [
        paginatedResponseModel,
        hasReachedMax,
        isFromCache,
        isOffline,
      ];
}

/// State representing an active pull-to-refresh operation preserving current items.
final class PaginationRefreshing<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationRefreshing] state.
  const PaginationRefreshing({
    required this.paginatedResponseModel,
    required this.hasReachedMax,
    this.isFromCache = false,
    this.isOffline = false,
  });

  @override
  final PaginationResponseModel<T, M> paginatedResponseModel;

  @override
  final bool hasReachedMax;

  @override
  final bool isFromCache;

  @override
  final bool isOffline;

  @override
  List<Object?> get props => [
        paginatedResponseModel,
        hasReachedMax,
        isFromCache,
        isOffline,
      ];
}

/// State representing an active load-more page request preserving current items.
final class PaginationLoadingMore<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationLoadingMore] state.
  const PaginationLoadingMore({
    required this.paginatedResponseModel,
    required this.hasReachedMax,
    this.isFromCache = false,
    this.isOffline = false,
  });

  @override
  final PaginationResponseModel<T, M> paginatedResponseModel;

  @override
  final bool hasReachedMax;

  @override
  final bool isFromCache;

  @override
  final bool isOffline;

  @override
  List<Object?> get props => [
        paginatedResponseModel,
        hasReachedMax,
        isFromCache,
        isOffline,
      ];
}

/// State representing a failed initial page fetch.
final class PaginationFailed<T extends Identifiable<String>, M extends MetaModel>
    extends StrataPaginationState<T, M> {
  /// Creates a [PaginationFailed] state.
  const PaginationFailed({
    required this.failure,
    this.paginatedResponseModel = const PaginationResponseModel(),
    this.onRetry,
  });

  @override
  final Failure failure;

  @override
  final PaginationResponseModel<T, M> paginatedResponseModel;

  /// Optional callback to retry initial fetch.
  final VoidCallback? onRetry;

  @override
  List<Object?> get props => [failure, paginatedResponseModel, onRetry];
}

/// State representing a failed incremental page fetch (page N >= 2) preserving existing items.
final class PaginationPageFetchFailure<T extends Identifiable<String>,
        M extends MetaModel> extends StrataPaginationState<T, M> {
  /// Creates a [PaginationPageFetchFailure] state.
  const PaginationPageFetchFailure({
    required this.failure,
    required this.paginatedResponseModel,
    required this.hasReachedMax,
    this.isFromCache = false,
    this.isOffline = false,
    this.onRetryMore,
  });

  @override
  final Failure failure;

  @override
  final PaginationResponseModel<T, M> paginatedResponseModel;

  @override
  final bool hasReachedMax;

  @override
  final bool isFromCache;

  @override
  final bool isOffline;

  /// Optional callback to retry fetching the failed subsequent page.
  final VoidCallback? onRetryMore;

  @override
  List<Object?> get props => [
        failure,
        paginatedResponseModel,
        hasReachedMax,
        isFromCache,
        isOffline,
        onRetryMore,
      ];
}
