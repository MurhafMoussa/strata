import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strata_core/strata_core.dart';

import 'pagination_cache_adapter_interface.dart';
import 'strata_pagination_event.dart';
import 'strata_pagination_state.dart';

/// Thread-safe BLoC managing paginated state transitions, concurrency safety,
/// $O(N)$ item deduplication, request cancellation, and optimistic mutations.
///
/// Generic parameters:
/// - [T]: Item type extending [Identifiable].
/// - [M]: Metadata model extending [MetaModel].
/// - [P]: Parameter model passed to data fetchers, constrained to
///   [PaginationParamsInterface] so request IDs are type-safe.
///
/// `@example`
/// ```dart
/// final bloc = StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>(
///   paginationStrategy: const PagePaginationStrategy(),
///   fetcher: (params, {requestId}) async {
///     return Right(PaginationResponseModel(data: [TestItem('1')]));
///   },
/// );
/// bloc.add(const StrataPaginationInitialFetched());
/// ```
class StrataPaginationBloc<
  T extends Identifiable<String>,
  M extends MetaModel,
  P extends PaginationParamsInterface
>
    extends Bloc<StrataPaginationEvent<T>, StrataPaginationState<T, M>> {
  /// Creates a [StrataPaginationBloc] instance.
  StrataPaginationBloc({
    required this.paginationStrategy,
    required this.fetcher,
    this.paramTransformer,
    this.requestIdGenerator,
    this.cancelRequestManager,
    this.cacheAdapter,
    this.cachePolicy = PaginationCachePolicy.networkOnly,
  }) : super(StrataPaginationState<T, M>.initial()) {
    on<StrataPaginationInitialFetched<T>>(
      _onInitialFetched,
      transformer: restartable(),
    );
    on<StrataPaginationFilterUpdated<T>>(
      _onFilterUpdated,
      transformer: restartable(),
    );
    on<StrataPaginationRefreshed<T>>(
      _onRefreshed,
      transformer: restartable(),
    );
    on<StrataPaginationMoreFetched<T>>(
      _onMoreFetched,
      transformer: droppable(),
    );
    on<StrataPaginationItemAdded<T>>(_onItemAdded);
    on<StrataPaginationItemUpdated<T>>(_onItemUpdated);
    on<StrataPaginationItemDeleted<T>>(_onItemDeleted);
  }

  /// Pure strategy calculating request parameter models.
  final PaginationStrategy<P> paginationStrategy;

  /// Asynchronous function performing network/data fetch.
  final ResultFuture<PaginationResponseModel<T, M>> Function(
    P params, {
    String? requestId,
  })
  fetcher;

  /// Optional function customizing parameter instances with extra filter maps.
  final P Function(P baseParams, Map<String, dynamic>? extra)?
  paramTransformer;

  /// Optional custom function generating request identifier strings for cancellation.
  final String Function(P params)? requestIdGenerator;

  /// Optional manager handling network request cancellation.
  final CancelRequestManagerInterface? cancelRequestManager;

  /// Optional caching adapter handling local offline persistence.
  final PaginationCacheAdapterInterface<T, M>? cacheAdapter;

  /// Default caching strategy policy.
  final PaginationCachePolicy cachePolicy;

  String? _lastRequestId;
  Map<String, dynamic>? _activeExtraFilters;

  P _buildParams(P baseParams, Map<String, dynamic>? extra) {
    if (paramTransformer != null) {
      return paramTransformer!(baseParams, extra);
    }
    return baseParams;
  }

  String _generateRequestId(P params) {
    if (requestIdGenerator != null) {
      return requestIdGenerator!(params);
    }
    return params.requestId;
  }

  void _cancelActiveRequest({String reason = 'New fetch initiated'}) {
    final lastId = _lastRequestId;
    if (lastId != null && cancelRequestManager != null) {
      cancelRequestManager!.cancelRequest(lastId, reason: reason);
    }
  }

  Future<void> _onInitialFetched(
    StrataPaginationInitialFetched<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) async {
    _cancelActiveRequest(reason: 'Initial fetch requested');
    _activeExtraFilters = event.extra;

    final effectivePolicy = event.cachePolicy ?? cachePolicy;
    final initialBase = paginationStrategy.getInitialParams(
      limit: event.limit,
    );
    final params = _buildParams(initialBase, event.extra);
    final requestId = _generateRequestId(params);
    _lastRequestId = requestId;

    emit(StrataPaginationState<T, M>.loading());

    if (cacheAdapter != null &&
        (effectivePolicy == PaginationCachePolicy.cacheFirst ||
            effectivePolicy == PaginationCachePolicy.cacheAndNetwork)) {
      final cachedModel = await cacheAdapter!.loadCache(requestId);
      if (cachedModel != null && !isClosed) {
        final hasReachedMax =
            cachedModel.data.length < event.limit ||
            paginationStrategy.getNextParams<T, M>(
                  currentItems: cachedModel.data,
                  meta: cachedModel.meta,
                  nextCursor: cachedModel.nextCursor,
                  limit: event.limit,
                ) ==
                null;

        emit(
          StrataPaginationState.succeeded(
            paginatedResponseModel: cachedModel,
            hasReachedMax: hasReachedMax,
            isFromCache: true,
          ),
        );

        if (effectivePolicy == PaginationCachePolicy.cacheFirst) {
          return;
        }
      }
    }

    await _executeFetch(
      params: params,
      requestId: requestId,
      limit: event.limit,
      isInitial: true,
      emit: emit,
    );
  }

  Future<void> _onFilterUpdated(
    StrataPaginationFilterUpdated<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) async {
    _cancelActiveRequest(reason: 'Filter updated');
    _activeExtraFilters = event.extra;

    final initialBase = paginationStrategy.getInitialParams(
      limit: event.limit,
    );
    final params = _buildParams(initialBase, event.extra);
    final requestId = _generateRequestId(params);
    _lastRequestId = requestId;

    emit(StrataPaginationState<T, M>.loading());

    await _executeFetch(
      params: params,
      requestId: requestId,
      limit: event.limit,
      isInitial: true,
      emit: emit,
    );
  }

  Future<void> _onRefreshed(
    StrataPaginationRefreshed<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) async {
    _cancelActiveRequest(reason: 'Pull to refresh');
    if (event.extra != null) {
      _activeExtraFilters = event.extra;
    }

    final currentModel = state.paginatedResponseModel;
    if (currentModel.data.isNotEmpty) {
      emit(
        StrataPaginationState.refreshing(
          paginatedResponseModel: currentModel,
          hasReachedMax: state.hasReachedMax,
          isFromCache: state.isFromCache,
          isOffline: state.isOffline,
        ),
      );
    } else {
      emit(StrataPaginationState<T, M>.loading());
    }

    final initialBase = paginationStrategy.getInitialParams(
      limit: event.limit,
    );
    final params = _buildParams(initialBase, _activeExtraFilters);
    final requestId = _generateRequestId(params);
    _lastRequestId = requestId;

    await _executeFetch(
      params: params,
      requestId: requestId,
      limit: event.limit,
      isInitial: true,
      emit: emit,
    );
  }

  Future<void> _onMoreFetched(
    StrataPaginationMoreFetched<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoading ||
        state.isLoadingMore ||
        state.isRefreshing) {
      return;
    }

    final currentModel = state.paginatedResponseModel;
    final nextParamsBase = paginationStrategy.getNextParams<T, M>(
      currentItems: currentModel.data,
      meta: currentModel.meta,
      nextCursor: currentModel.nextCursor,
      limit: event.limit,
    );

    if (nextParamsBase == null) {
      emit(
        StrataPaginationState.succeeded(
          paginatedResponseModel: currentModel,
          hasReachedMax: true,
          isFromCache: state.isFromCache,
          isOffline: state.isOffline,
        ),
      );
      return;
    }

    final params = _buildParams(nextParamsBase, _activeExtraFilters);
    final requestId = _generateRequestId(params);
    _lastRequestId = requestId;

    emit(
      StrataPaginationState.loadingMore(
        paginatedResponseModel: currentModel,
        hasReachedMax: state.hasReachedMax,
        isFromCache: state.isFromCache,
        isOffline: state.isOffline,
      ),
    );

    await _executeFetch(
      params: params,
      requestId: requestId,
      limit: event.limit,
      isInitial: false,
      emit: emit,
    );
  }

  Future<void> _executeFetch({
    required P params,
    required String requestId,
    required int limit,
    required bool isInitial,
    required Emitter<StrataPaginationState<T, M>> emit,
  }) async {
    final result = await fetcher(params, requestId: requestId);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (isInitial) {
          emit(
            StrataPaginationState.failed(
              failure: failure,
              paginatedResponseModel: state.paginatedResponseModel,
              onRetry: () => add(
                StrataPaginationInitialFetched(
                  limit: limit,
                  extra: _activeExtraFilters,
                ),
              ),
            ),
          );
        } else {
          emit(
            StrataPaginationState.pageFetchFailure(
              failure: failure,
              paginatedResponseModel: state.paginatedResponseModel,
              hasReachedMax: state.hasReachedMax,
              isFromCache: state.isFromCache,
              isOffline: state.isOffline,
              onRetryMore: () =>
                  add(StrataPaginationMoreFetched(limit: limit)),
            ),
          );
        }
      },
      (newResponse) {
        final PaginationResponseModel<T, M> finalModel;
        if (isInitial) {
          finalModel = newResponse;
        } else {
          final existing = state.paginatedResponseModel.data;
          final combined = _deduplicateAndAppend(existing, newResponse.data);
          finalModel = newResponse.copyWith(data: combined);
        }

        final hasReachedMax =
            newResponse.data.length < limit ||
            paginationStrategy.getNextParams<T, M>(
                  currentItems: finalModel.data,
                  meta: finalModel.meta,
                  nextCursor: finalModel.nextCursor,
                  limit: limit,
                ) ==
                null;

        emit(
          StrataPaginationState.succeeded(
            paginatedResponseModel: finalModel,
            hasReachedMax: hasReachedMax,
            isFromCache: false,
            isOffline: false,
          ),
        );

        if (cacheAdapter != null && isInitial) {
          cacheAdapter!.saveCache(requestId, finalModel);
        }
      },
    );
  }

  /// Deduplicates [incoming] items against [existing] items by `Identifiable.id` using $O(N)$ set lookups.
  List<T> _deduplicateAndAppend(List<T> existing, List<T> incoming) {
    final seenIds = existing.map((e) => e.id).toSet();
    final combined = List<T>.from(existing);
    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        combined.add(item);
      }
    }
    return combined;
  }

  void _onItemAdded(
    StrataPaginationItemAdded<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) {
    final currentModel = state.paginatedResponseModel;
    final filtered = currentModel.data.where((e) => e.id != event.item.id).toList();
    final updatedList = event.atFirst
        ? [event.item, ...filtered]
        : [...filtered, event.item];

    final updatedModel = currentModel.copyWith(data: updatedList);
    _emitMutatedState(updatedModel, emit);
  }

  void _onItemUpdated(
    StrataPaginationItemUpdated<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) {
    final currentModel = state.paginatedResponseModel;
    final list = List<T>.from(currentModel.data);
    final index = list.indexWhere((e) => e.id == event.item.id);
    if (index == -1) return;

    list[index] = event.item;
    final updatedModel = currentModel.copyWith(data: list);
    _emitMutatedState(updatedModel, emit);
  }

  void _onItemDeleted(
    StrataPaginationItemDeleted<T> event,
    Emitter<StrataPaginationState<T, M>> emit,
  ) {
    final currentModel = state.paginatedResponseModel;
    final updatedList = currentModel.data.where((e) => e.id != event.id).toList();
    final updatedModel = currentModel.copyWith(data: updatedList);
    _emitMutatedState(updatedModel, emit);
  }

  void _emitMutatedState(
    PaginationResponseModel<T, M> updatedModel,
    Emitter<StrataPaginationState<T, M>> emit,
  ) {
    emit(
      StrataPaginationState.succeeded(
        paginatedResponseModel: updatedModel,
        hasReachedMax: state.hasReachedMax,
        isFromCache: state.isFromCache,
        isOffline: state.isOffline,
      ),
    );
  }

  /// Optimistically adds [item] to state (at first index if [atFirst] is true, else at end).
  void addFirst(T item) => add(StrataPaginationItemAdded(item, atFirst: true));

  /// Optimistically appends [item] to state.
  void addLast(T item) => add(StrataPaginationItemAdded(item, atFirst: false));

  /// Optimistically updates [item] in state matching [item.id].
  void update(T item) => add(StrataPaginationItemUpdated(item));

  /// Optimistically removes item matching [id] from state.
  void delete(String id) => add(StrataPaginationItemDeleted(id));

  /// Finds and returns an item from the active dataset matching [id], or `null` if absent.
  T? findById(String id) {
    try {
      return state.items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
