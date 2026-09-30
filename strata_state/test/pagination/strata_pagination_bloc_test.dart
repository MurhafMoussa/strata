import 'package:bloc_test/bloc_test.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_state/strata_state.dart';

import '../helpers/pagination_test_helpers.dart';

class CustomParam extends Equatable {
  const CustomParam(this.page, this.limit, {this.query});
  final int page;
  final int limit;
  final String? query;

  @override
  List<Object?> get props => [page, limit, query];
}

class ThrowingParam {
  String get requestId => throw Exception('Getter error');
}

class DummyThrowingStrategy extends PaginationStrategy<ThrowingParam> {
  const DummyThrowingStrategy();

  @override
  ThrowingParam getInitialParams({required int limit}) => ThrowingParam();

  @override
  ThrowingParam? getNextParams<T, M extends MetaModel>({
    required List<T> currentItems,
    M? meta,
    String? nextCursor,
    required int limit,
  }) =>
      null;
}

class DummyCacheAdapter<T extends Identifiable<String>, M extends MetaModel>
    extends PaginationCacheAdapterInterface<T, M> {
  final Map<String, PaginationResponseModel<T, M>> _storage = {};

  @override
  Future<PaginationResponseModel<T, M>?> loadCache(String key) async => _storage[key];

  @override
  Future<void> saveCache(String key, PaginationResponseModel<T, M> response) async {
    _storage[key] = response;
  }

  @override
  Future<void> clearCache(String key) async {
    _storage.remove(key);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const PaginationResponseModel<TestItem, NoMetaModel>(),
    );
  });

  group('StrataPaginationBloc Tests', () {
    late PagePaginationStrategy pageStrategy;
    late MockCancelManager mockCancelManager;
    late MockCacheAdapter mockCacheAdapter;

    setUp(() {
      pageStrategy = const PagePaginationStrategy();
      mockCancelManager = MockCancelManager();
      mockCacheAdapter = MockCacheAdapter();

      when(() => mockCancelManager.cancelRequest(any(), reason: any(named: 'reason')))
          .thenReturn(null);
      when(() => mockCacheAdapter.saveCache(any(), any())).thenAnswer((_) async {});
      when(() => mockCacheAdapter.loadCache(any())).thenAnswer((_) async => null);
    });

    test('Initial state properties and state getters', () {
      final bloc = StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>(
        paginationStrategy: pageStrategy,
        fetcher: (params, {requestId}) async => createSuccessFuture(createTestItems(1)),
      );

      expect(
        bloc.state,
        equals(const StrataPaginationState<TestItem, NoMetaModel>.initial()),
      );
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.hasReachedMax, isFalse);
      expect(bloc.state.isFromCache, isFalse);
      expect(bloc.state.isOffline, isFalse);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.isRefreshing, isFalse);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.isFailed, isFalse);
      expect(bloc.state.isPageFetchFailure, isFalse);
      expect(bloc.state.failure, isNull);
    });

    test('StrataPaginationState getters across all state variants', () {
      const initial = StrataPaginationState<TestItem, NoMetaModel>.initial();
      expect(initial.isLoading, isFalse);

      const loading = StrataPaginationState<TestItem, NoMetaModel>.loading();
      expect(loading.isLoading, isTrue);
      expect(loading.props, isEmpty);

      const succeeded = StrataPaginationState<TestItem, NoMetaModel>.succeeded(
        paginatedResponseModel: PaginationResponseModel(data: [TestItem('1')]),
        hasReachedMax: true,
        isFromCache: true,
        isOffline: true,
      );
      expect(succeeded.hasReachedMax, isTrue);
      expect(succeeded.isFromCache, isTrue);
      expect(succeeded.isOffline, isTrue);
      expect(
        succeeded.props,
        equals([
          const PaginationResponseModel<TestItem, NoMetaModel>(
            data: [TestItem('1')],
          ),
          true,
          true,
          true,
        ]),
      );

      const refreshing = StrataPaginationState<TestItem, NoMetaModel>.refreshing(
        paginatedResponseModel: PaginationResponseModel(data: [TestItem('1')]),
        hasReachedMax: false,
        isFromCache: false,
        isOffline: false,
      );
      expect(refreshing.isRefreshing, isTrue);
      expect(
        refreshing.props,
        equals([
          const PaginationResponseModel<TestItem, NoMetaModel>(
            data: [TestItem('1')],
          ),
          false,
          false,
          false,
        ]),
      );

      const loadingMore = StrataPaginationState<TestItem, NoMetaModel>.loadingMore(
        paginatedResponseModel: PaginationResponseModel(data: [TestItem('1')]),
        hasReachedMax: false,
      );
      expect(loadingMore.isLoadingMore, isTrue);

      const failed = StrataPaginationState<TestItem, NoMetaModel>.failed(
        failure: UnknownFailure(message: 'Error'),
      );
      expect(failed.isFailed, isTrue);
      expect(failed.failure, equals(const UnknownFailure(message: 'Error')));

      const pageFailure = StrataPaginationState<TestItem, NoMetaModel>.pageFetchFailure(
        failure: ConnectionFailure(message: 'Offline'),
        paginatedResponseModel: PaginationResponseModel(data: [TestItem('1')]),
        hasReachedMax: false,
      );
      expect(pageFailure.isPageFetchFailure, isTrue);
      expect(
        pageFailure.failure,
        equals(const ConnectionFailure(message: 'Offline')),
      );
    });

    test('StrataPaginationEvent props equality test', () {
      const initialEvent = StrataPaginationInitialFetched<TestItem>(
        limit: 10,
        extra: {'a': 'b'},
        cachePolicy: PaginationCachePolicy.cacheFirst,
      );
      expect(
        initialEvent.props,
        equals([10, {'a': 'b'}, PaginationCachePolicy.cacheFirst]),
      );

      const refreshEvent = StrataPaginationRefreshed<TestItem>(
        limit: 15,
        extra: {'c': 'd'},
      );
      expect(refreshEvent.props, equals([15, {'c': 'd'}]));

      const moreEvent = StrataPaginationMoreFetched<TestItem>(limit: 25);
      expect(moreEvent.props, equals([25]));

      const filterEvent = StrataPaginationFilterUpdated<TestItem>(
        extra: {'f': 'g'},
        limit: 30,
      );
      expect(filterEvent.props, equals([{'f': 'g'}, 30]));

      const addEvent = StrataPaginationItemAdded<TestItem>(
        TestItem('1'),
        atFirst: true,
      );
      expect(addEvent.props, equals([const TestItem('1'), true]));

      const updateEvent = StrataPaginationItemUpdated<TestItem>(
        TestItem('1'),
      );
      expect(updateEvent.props, equals([const TestItem('1')]));

      const deleteEvent = StrataPaginationItemDeleted<TestItem>('1');
      expect(deleteEvent.props, equals(['1']));
    });

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits [PaginationLoading, PaginationSucceeded] on successful initial fetch',
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            fetcher: (params, {requestId}) async {
              expect(params.page, equals(1));
              expect(params.limit, equals(2));
              return createSuccessFuture(createTestItems(2));
            },
          ),
      act: (bloc) => bloc.add(const StrataPaginationInitialFetched(limit: 2)),
      expect:
          () => [
            const StrataPaginationState<TestItem, NoMetaModel>.loading(),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: createTestItems(2),
              ),
              hasReachedMax: false,
              isFromCache: false,
            ),
          ],
    );

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits [PaginationLoading, PaginationFailed] on initial fetch failure',
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            fetcher: (params, {requestId}) async {
              return createFailureFuture(
                const ServerFailure(message: 'Server error', statusCode: 500),
              );
            },
          ),
      act: (bloc) => bloc.add(const StrataPaginationInitialFetched(limit: 2)),
      expect:
          () => [
            const StrataPaginationState<TestItem, NoMetaModel>.loading(),
            isA<PaginationFailed<TestItem, NoMetaModel>>()
                .having(
                  (s) => s.failure.message,
                  'failure message',
                  'Server error',
                )
                .having((s) => s.onRetry, 'onRetry', isNotNull),
          ],
    );

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits cached data and then fetches network when cacheAndNetwork policy used',
      setUp: () {
        when(() => mockCacheAdapter.loadCache(any())).thenAnswer(
          (_) async => createTestResponse(items: [const TestItem('cache_1')]),
        );
      },
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            cacheAdapter: mockCacheAdapter,
            cachePolicy: PaginationCachePolicy.cacheAndNetwork,
            fetcher:
                (params, {requestId}) async =>
                    createSuccessFuture([const TestItem('network_1')]),
          ),
      act: (bloc) => bloc.add(const StrataPaginationInitialFetched(limit: 2)),
      expect:
          () => [
            const StrataPaginationState<TestItem, NoMetaModel>.loading(),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: [const TestItem('cache_1')],
              ),
              hasReachedMax: true,
              isFromCache: true,
            ),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: [const TestItem('network_1')],
              ),
              hasReachedMax: true,
              isFromCache: false,
            ),
          ],
    );

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits [PaginationRefreshing, PaginationSucceeded] on pull to refresh when items exist',
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            fetcher:
                (params, {requestId}) async =>
                    createSuccessFuture([const TestItem('refreshed_1')]),
          ),
      seed:
          () => StrataPaginationState.succeeded(
            paginatedResponseModel: createTestResponse(
              items: [const TestItem('old_1')],
            ),
            hasReachedMax: false,
          ),
      act: (bloc) => bloc.add(const StrataPaginationRefreshed(limit: 10)),
      expect:
          () => [
            StrataPaginationState<TestItem, NoMetaModel>.refreshing(
              paginatedResponseModel: createTestResponse(
                items: [const TestItem('old_1')],
              ),
              hasReachedMax: false,
            ),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: [const TestItem('refreshed_1')],
              ),
              hasReachedMax: true,
            ),
          ],
    );

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits [PaginationLoading, PaginationSucceeded] on pull to refresh when list is empty',
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            fetcher:
                (params, {requestId}) async =>
                    createSuccessFuture([const TestItem('refreshed_1')]),
          ),
      act: (bloc) => bloc.add(const StrataPaginationRefreshed(limit: 10)),
      expect:
          () => [
            const StrataPaginationState<TestItem, NoMetaModel>.loading(),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: [const TestItem('refreshed_1')],
              ),
              hasReachedMax: true,
            ),
          ],
    );

    blocTest<
      StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>,
      StrataPaginationState<TestItem, NoMetaModel>
    >(
      'Emits [PaginationLoadingMore, PaginationSucceeded] and deduplicates items on load-more',
      build:
          () => StrataPaginationBloc<
            TestItem,
            NoMetaModel,
            PagePaginationParams
          >(
            paginationStrategy: pageStrategy,
            fetcher: (params, {requestId}) async {
              if (params.page == 1) {
                return createSuccessFuture(createTestItems(2, startId: 1));
              }
              // Returns item '2' (duplicate) and item '3'
              return createSuccessFuture(createTestItems(2, startId: 2));
            },
          ),
      seed:
          () => StrataPaginationState.succeeded(
            paginatedResponseModel: createTestResponse(
              items: createTestItems(2, startId: 1),
            ),
            hasReachedMax: false,
          ),
      act: (bloc) => bloc.add(const StrataPaginationMoreFetched(limit: 2)),
      expect:
          () => [
            StrataPaginationState<TestItem, NoMetaModel>.loadingMore(
              paginatedResponseModel: createTestResponse(
                items: createTestItems(2, startId: 1),
              ),
              hasReachedMax: false,
            ),
            StrataPaginationState<TestItem, NoMetaModel>.succeeded(
              paginatedResponseModel: createTestResponse(
                items: createTestItems(3, startId: 1),
              ),
              hasReachedMax: true,
            ),
          ],
    );

    test(
      'Emits hasReachedMax true when nextParams returns null on MoreFetched',
      () async {
        final bloc =
            StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>(
              paginationStrategy: pageStrategy,
              fetcher:
                  (params, {requestId}) async =>
                      const Right(PaginationResponseModel()),
            );

        bloc.emit(
          StrataPaginationState.succeeded(
            paginatedResponseModel: createTestResponse(
              items: createTestItems(1),
            ),
            hasReachedMax: false,
          ),
        );

        bloc.add(const StrataPaginationMoreFetched(limit: 2));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.hasReachedMax, isTrue);
        await bloc.close();
      },
    );

    test(
      'paramTransformer and requestIdGenerator custom implementations',
      () async {
        final bloc =
            StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>(
              paginationStrategy: pageStrategy,
              paramTransformer:
                  (base, extra) =>
                      PagePaginationParams(page: base.page, limit: base.limit),
              requestIdGenerator:
                  (params) => 'custom_${params.page}_${params.limit}',
              fetcher: (params, {requestId}) async {
                expect(requestId, equals('custom_1_10'));
                return createSuccessFuture([const TestItem('1')]);
              },
            );

        bloc.add(const StrataPaginationInitialFetched(limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await bloc.close();
      },
    );

    test(
      'Fallback in _generateRequestId when getter throws exception',
      () async {
        final bloc =
            StrataPaginationBloc<TestItem, NoMetaModel, ThrowingParam>(
              paginationStrategy: const DummyThrowingStrategy(),
              fetcher: (params, {requestId}) async {
                expect(requestId, isNotNull);
                return createSuccessFuture([const TestItem('1')]);
              },
            );

        bloc.add(const StrataPaginationInitialFetched(limit: 10));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await bloc.close();
      },
    );

    test('DummyCacheAdapter saveCache, loadCache, and clearCache execution', () async {
      final adapter = DummyCacheAdapter<TestItem, NoMetaModel>();
      const key = 'test_key';
      final model = createTestResponse(items: [const TestItem('1')]);

      await adapter.saveCache(key, model);
      final loaded = await adapter.loadCache(key);
      expect(loaded, equals(model));

      await adapter.clearCache(key);
      final cleared = await adapter.loadCache(key);
      expect(cleared, isNull);
    });

    group('Optimistic Mutations & findById Edge Cases', () {
      late StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>
      bloc;

      setUp(() {
        bloc =
            StrataPaginationBloc<TestItem, NoMetaModel, PagePaginationParams>(
              paginationStrategy: pageStrategy,
              fetcher:
                  (params, {requestId}) async => createSuccessFuture([
                    const TestItem('1', name: 'Item 1'),
                    const TestItem('2', name: 'Item 2'),
                  ]),
            );
        bloc.emit(
          StrataPaginationState.succeeded(
            paginatedResponseModel: createTestResponse(
              items: [
                const TestItem('1', name: 'Item 1'),
                const TestItem('2', name: 'Item 2'),
              ],
            ),
            hasReachedMax: false,
          ),
        );
      });

      tearDown(() => bloc.close());

      test(
        'update does nothing if item ID does not exist in state list',
        () async {
          bloc.update(const TestItem('999', name: 'Nonexistent'));
          await Future<void>.delayed(Duration.zero);

          expect(
            bloc.state.items,
            equals([
              const TestItem('1', name: 'Item 1'),
              const TestItem('2', name: 'Item 2'),
            ]),
          );
        },
      );

      test('findById returns item if exists, else null', () {
        expect(
          bloc.findById('1'),
          equals(const TestItem('1', name: 'Item 1')),
        );
        expect(bloc.findById('absent'), isNull);
      });
    });
  });
}
