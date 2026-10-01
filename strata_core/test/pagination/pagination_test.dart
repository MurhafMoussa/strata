import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('PaginationCachePolicy', () {
    test('networkOnly assertions', () {
      const policy = PaginationCachePolicy.networkOnly;
      expect(policy.usesCache, isFalse);
      expect(policy.requestsNetwork, isTrue);
    });

    test('cacheFirst assertions', () {
      const policy = PaginationCachePolicy.cacheFirst;
      expect(policy.usesCache, isTrue);
      expect(policy.requestsNetwork, isTrue);
    });

    test('cacheAndNetwork assertions', () {
      const policy = PaginationCachePolicy.cacheAndNetwork;
      expect(policy.usesCache, isTrue);
      expect(policy.requestsNetwork, isTrue);
    });
  });

  group('Pagination Meta & Response Models', () {
    test('NoMetaModel value equality', () {
      const meta1 = NoMetaModel();
      const meta2 = NoMetaModel();
      expect(meta1, equals(meta2));
      expect(meta1.props, isEmpty);
    });

    test('PaginationMetaModel json serialization and equality', () {
      final meta = PaginationMetaModel.fromJson({
        'total_count': 100,
        'page': 2,
        'limit': 20,
      });

      expect(meta.totalCount, equals(100));
      expect(meta.page, equals(2));
      expect(meta.limit, equals(20));

      final json = meta.toJson();
      expect(json['total_count'], equals(100));
      expect(json['page'], equals(2));
      expect(json['limit'], equals(20));

      const sameMeta = PaginationMetaModel(
        totalCount: 100,
        page: 2,
        limit: 20,
      );
      expect(meta, equals(sameMeta));
    });

    test('PaginationResponseModel value equality and copyWith', () {
      const response = PaginationResponseModel<String, PaginationMetaModel>(
        data: ['a', 'b'],
        meta: PaginationMetaModel(totalCount: 10, page: 1, limit: 2),
        nextCursor: 'cursor_1',
      );

      expect(response.data, equals(['a', 'b']));
      expect(response.nextCursor, equals('cursor_1'));

      final updated = response.copyWith(nextCursor: 'cursor_2');
      expect(updated.data, equals(['a', 'b']));
      expect(updated.nextCursor, equals('cursor_2'));

      expect(response, isNot(equals(updated)));
    });

    test('PaginationResponseModel.fromJson parsing data, meta, and cursors', () {
      final json = {
        'data': [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ],
        'meta': {'total_count': 50, 'page': 1, 'limit': 2},
        'next_cursor': 'cursor_abc',
      };

      final response = PaginationResponseModel<Map<String, dynamic>, PaginationMetaModel>.fromJson(
        json,
        (itemJson) => itemJson,
        fromJsonM: PaginationMetaModel.fromJson,
      );

      expect(response.data.length, equals(2));
      expect(response.data.first['name'], equals('Item 1'));
      expect(response.meta?.totalCount, equals(50));
      expect(response.nextCursor, equals('cursor_abc'));
    });

    test('PaginationResponseModel.fromJson with fallback camelCase nextCursor and NoMetaModel', () {
      final json = {
        'data': [
          {'title': 'Alpha'},
        ],
        'nextCursor': 'cursor_xyz',
      };

      final response = PaginationResponseModel<Map<String, dynamic>, NoMetaModel>.fromJson(
        json,
        (itemJson) => itemJson,
      );

      expect(response.data.length, equals(1));
      expect(response.meta, equals(const NoMetaModel()));
      expect(response.nextCursor, equals('cursor_xyz'));
    });
  });

  group('PaginationParamsInterface', () {
    test('PagePaginationParams implements interface and exposes requestId', () {
      const params = PagePaginationParams(page: 1, limit: 20);
      expect(params, isA<PaginationParamsInterface>());
      expect(params, isA<PaginationParams>());
      expect(params.requestId, equals('page_1_limit_20'));
      expect(params.page, equals(1));
      expect(params.limit, equals(20));
    });

    test('PagePaginationParams serialization, defaults, and aliases', () {
      const pagination1 = PagePaginationParams(page: 2, limit: 20);
      final pagination2 = PagePaginationParams.fromJson({'page': 2, 'limit': 20});
      final pagination3 = PagePaginationParams.fromJson({'batch': 2, 'limit': 20});

      expect(pagination1, equals(pagination2));
      expect(pagination1, equals(pagination3));
      expect(pagination1.page, equals(2));
      expect(pagination1.requestId, equals('page_2_limit_20'));
      expect(pagination1.toJson(), equals({'page': 2, 'limit': 20}));
      expect(pagination1.props, equals([2, 20, null]));

      final defaultPagination = PagePaginationParams.fromJson({});
      expect(defaultPagination.page, equals(1));
      expect(defaultPagination.limit, equals(10));
      expect(defaultPagination.requestId, equals('page_1_limit_10'));

      const aliasParam = PagePaginationParams(page: 3, limit: 15);
      expect(aliasParam, isA<PagePaginationParams>());
      expect(aliasParam.page, equals(3));
    });

    test('SkipPaginationParams implements interface and exposes requestId', () {
      const params = SkipPaginationParams(skip: 10, limit: 15);
      expect(params, isA<PaginationParamsInterface>());
      expect(params, isA<PaginationParams>());
      expect(params.requestId, equals('skip_10_limit_15'));
      expect(params.skip, equals(10));
      expect(params.limit, equals(15));
    });

    test('SkipPaginationParams serialization, defaults, and value equality', () {
      const pagination1 = SkipPaginationParams(skip: 20, limit: 10);
      final pagination2 = SkipPaginationParams.fromJson({'skip': 20, 'limit': 10});

      expect(pagination1, equals(pagination2));
      expect(pagination1.skip, equals(20));
      expect(pagination1.requestId, equals('skip_20_limit_10'));
      expect(pagination1.toJson(), equals({'skip': 20, 'limit': 10}));
      expect(pagination1.props, equals([20, 10, null]));

      final defaultPagination = SkipPaginationParams.fromJson({});
      expect(defaultPagination.skip, equals(0));
      expect(defaultPagination.limit, equals(10));
      expect(defaultPagination.requestId, equals('skip_0_limit_10'));
    });

    test('CursorPaginationParams implements interface and exposes requestId', () {
      const params = CursorPaginationParams(cursor: 'token_1', limit: 25);
      expect(params, isA<PaginationParamsInterface>());
      expect(params, isA<PaginationParams>());
      expect(params.requestId, equals('cursor_token_1_limit_25'));
    });

    test('CursorPaginationParams serialization, requestId, and value equality', () {
      const pagination1 = CursorPaginationParams(cursor: 'token_123', limit: 20);
      final pagination2 = CursorPaginationParams.fromJson({'cursor': 'token_123', 'limit': 20});

      expect(pagination1, equals(pagination2));
      expect(pagination1.cursor, equals('token_123'));
      expect(pagination1.requestId, equals('cursor_token_123_limit_20'));
      expect(pagination1.toJson(), equals({'cursor': 'token_123', 'limit': 20}));
      expect(pagination1.props, equals(['token_123', 20, null]));

      const nullCursorPagination = CursorPaginationParams(limit: 15);
      expect(nullCursorPagination.cursor, isNull);
      expect(nullCursorPagination.requestId, equals('cursor_null_limit_15'));
      expect(nullCursorPagination.toJson(), equals({'limit': 15}));
    });

    test('CursorPaginationParams requestId handles null cursor', () {
      const params = CursorPaginationParams(limit: 5);
      expect(params.requestId, equals('cursor_null_limit_5'));
    });

    test('requestId changes when pagination position changes', () {
      const page1 = PagePaginationParams(page: 1, limit: 20);
      const page2 = PagePaginationParams(page: 2, limit: 20);
      expect(page1.requestId, isNot(equals(page2.requestId)));
    });

    test('PaginationParams polymorphic deserialization via fromJson factory', () {
      final defaultParams = PaginationParams.fromJson({'page': 1, 'limit': 10});
      expect(defaultParams, isA<PagePaginationParams>());

      final skipParams = PaginationParams.fromJson({'skip': 10, 'limit': 10});
      expect(skipParams, isA<SkipPaginationParams>());

      final cursorParams = PaginationParams.fromJson({'cursor': 'abc', 'limit': 10});
      expect(cursorParams, isA<CursorPaginationParams>());
    });

    test('PaginationParams supports extra parameters and flattens toQueryParameters()', () {
      const extra = {'filter': 'active', 'order': 'desc'};
      const params = PagePaginationParams(
        page: 2,
        limit: 15,
        extra: extra,
      );

      expect(params.extra, equals(extra));
      expect(
        params.toJson(),
        equals({'page': 2, 'limit': 15, 'extra': extra}),
      );
      expect(
        params.toQueryParameters(),
        equals({'page': 2, 'limit': 15, 'filter': 'active', 'order': 'desc'}),
      );

      final deserialized = PagePaginationParams.fromJson(params.toJson());
      expect(deserialized.extra, equals(extra));

      const skipParams = SkipPaginationParams(skip: 20, limit: 10, extra: extra);
      expect(
        skipParams.toQueryParameters(),
        equals({'skip': 20, 'limit': 10, 'filter': 'active', 'order': 'desc'}),
      );

      const cursorParams = CursorPaginationParams(cursor: 'token_1', limit: 10, extra: extra);
      expect(
        cursorParams.toQueryParameters(),
        equals({'cursor': 'token_1', 'limit': 10, 'filter': 'active', 'order': 'desc'}),
      );
    });
  });

  group('PagePaginationStrategy', () {
    const strategy = PagePaginationStrategy();

    test('getInitialParams generates page 1 and given limit', () {
      final params = strategy.getInitialParams(limit: 20);
      expect(params.page, equals(1));
      expect(params.limit, equals(20));
    });

    test('getNextParams calculates page 2 when first page is full', () {
      final currentItems = List.generate(20, (i) => 'item_$i');
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        limit: 20,
      );

      expect(next, isNotNull);
      expect(next?.page, equals(2));
      expect(next?.limit, equals(20));
    });

    test('getNextParams returns null when currentItems is empty', () {
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: [],
        limit: 20,
      );

      expect(next, isNull);
    });

    test('getNextParams returns null when last fetched page was incomplete', () {
      final currentItems = List.generate(15, (i) => 'item_$i');
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        limit: 20,
      );

      expect(next, isNull);
    });

    test('getNextParams returns null when totalCount in meta is reached', () {
      final currentItems = List.generate(20, (i) => 'item_$i');
      const meta = PaginationMetaModel(totalCount: 20, page: 1, limit: 20);

      final next = strategy.getNextParams<String, PaginationMetaModel>(
        currentItems: currentItems,
        meta: meta,
        limit: 20,
      );

      expect(next, isNull);
    });

    test('PagePaginationStrategy supports custom createParams builder', () {
      final customStrategy = PagePaginationStrategy(
        createParams: ({required page, required limit}) => PagePaginationParams(page: page * 10, limit: limit),
      );

      final initial = customStrategy.getInitialParams(limit: 10);
      expect(initial.page, equals(10));

      final next = customStrategy.getNextParams<String, NoMetaModel>(
        currentItems: List.generate(10, (i) => '$i'),
        limit: 10,
      );
      expect(next?.page, equals(20));
    });
  });

  group('SkipPaginationStrategy', () {
    const strategy = SkipPaginationStrategy();

    test('getInitialParams generates skip 0 and given limit', () {
      final params = strategy.getInitialParams(limit: 15);
      expect(params.skip, equals(0));
      expect(params.limit, equals(15));
    });

    test('getNextParams calculates skip equal to current item count', () {
      final currentItems = List.generate(15, (i) => 'item_$i');
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        limit: 15,
      );

      expect(next, isNotNull);
      expect(next?.skip, equals(15));
      expect(next?.limit, equals(15));
    });

    test('getNextParams returns null when incomplete page or total reached', () {
      final items = List.generate(10, (i) => 'item_$i');
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: items,
        limit: 15,
      );
      expect(next, isNull);

      final fullItems = List.generate(15, (i) => 'item_$i');
      const meta = PaginationMetaModel(totalCount: 15);
      final nextMeta = strategy.getNextParams<String, PaginationMetaModel>(
        currentItems: fullItems,
        meta: meta,
        limit: 15,
      );
      expect(nextMeta, isNull);
    });

    test('SkipPaginationStrategy supports custom createParams builder', () {
      final customStrategy = SkipPaginationStrategy(
        createParams: ({required skip, required limit}) => SkipPaginationParams(skip: skip + 5, limit: limit),
      );

      final initial = customStrategy.getInitialParams(limit: 25);
      expect(initial.skip, equals(5));

      final next = customStrategy.getNextParams<String, NoMetaModel>(
        currentItems: List.generate(25, (i) => '$i'),
        limit: 25,
      );
      expect(next?.skip, equals(30));
    });
  });

  group('CursorPaginationStrategy', () {
    const strategy = CursorPaginationStrategy();

    test('getInitialParams returns null cursor when no initial cursor is provided', () {
      final params = strategy.getInitialParams(limit: 20);
      expect(params.cursor, isNull);
      expect(params.limit, equals(20));
    });

    test('getInitialParams uses initialCursor when provided', () {
      const customStrategy = CursorPaginationStrategy(
        initialCursor: 'init_cursor',
      );

      final params = customStrategy.getInitialParams(limit: 20);
      expect(params.cursor, equals('init_cursor'));
    });

    test('getNextParams calculates next params with nextCursor', () {
      final currentItems = List.generate(20, (i) => 'item_$i');
      final next = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        nextCursor: 'next_token_123',
        limit: 20,
      );

      expect(next, isNotNull);
      expect(next?.cursor, equals('next_token_123'));
      expect(next?.limit, equals(20));
    });

    test('getNextParams returns null when nextCursor is null or empty', () {
      final currentItems = List.generate(20, (i) => 'item_$i');

      final nextNull = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        nextCursor: null,
        limit: 20,
      );
      expect(nextNull, isNull);

      final nextEmpty = strategy.getNextParams<String, NoMetaModel>(
        currentItems: currentItems,
        nextCursor: '',
        limit: 20,
      );
      expect(nextEmpty, isNull);
    });

    test('CursorPaginationStrategy supports custom createParams builder', () {
      final customStrategy = CursorPaginationStrategy(
        createParams: ({cursor, required limit}) => CursorPaginationParams(cursor: 'pref_$cursor', limit: limit),
      );

      final initial = customStrategy.getInitialParams(limit: 10);
      expect(initial.cursor, equals('pref_null'));

      final next = customStrategy.getNextParams<String, NoMetaModel>(
        currentItems: List.generate(10, (i) => '$i'),
        nextCursor: 'abc',
        limit: 10,
      );
      expect(next?.cursor, equals('pref_abc'));
    });
  });
}
