import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

void main() {
  group('Models and Params Tests', () {
    test('NoParams serialization and value equality', () {
      const params1 = NoParams();
      final params2 = NoParams.fromJson({});
      expect(params1, equals(params2));
      expect(params1.toJson(), isEmpty);
      expect(params1.props, isEmpty);
    });

    test('IdParam serialization and value equality', () {
      const param1 = IdParam(id: '123');
      final param2 = IdParam.fromJson({'id': '123'});
      expect(param1, equals(param2));
      expect(param1.toJson(), equals({'id': '123'}));
      expect(param1.toJson(idKey: 'custom_id'), equals({'custom_id': '123'}));
      expect(param1.props, equals(['123']));

      final emptyParam = IdParam.fromJson({});
      expect(emptyParam.id, isEmpty);
    });

    test('DefaultPaginationParams serialization, requestId, and value equality', () {
      const pagination1 = DefaultPaginationParams(page: 2, limit: 20);
      final pagination2 = DefaultPaginationParams.fromJson({'page': 2, 'limit': 20});
      final pagination3 = DefaultPaginationParams.fromJson({'batch': 2, 'limit': 20});

      expect(pagination1, equals(pagination2));
      expect(pagination1, equals(pagination3));
      expect(pagination1.batch, equals(2));
      expect(pagination1.requestId, equals('default_page_2_limit_20'));
      expect(pagination1.toJson(), equals({'page': 2, 'limit': 20}));
      expect(pagination1.props, equals([2, 20, null]));

      final defaultPagination = DefaultPaginationParams.fromJson({});
      expect(defaultPagination.page, equals(1));
      expect(defaultPagination.limit, equals(10));
      expect(defaultPagination.requestId, equals('default_page_1_limit_10'));
    });

    test('SkipPaginationParams serialization, requestId, and value equality', () {
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

    test('PaginationParams polymorphic deserialization via fromJson factory', () {
      final defaultParams = PaginationParams.fromJson({'page': 1, 'limit': 10});
      expect(defaultParams, isA<DefaultPaginationParams>());

      final skipParams = PaginationParams.fromJson({'skip': 10, 'limit': 10});
      expect(skipParams, isA<SkipPaginationParams>());

      final cursorParams = PaginationParams.fromJson({'cursor': 'abc', 'limit': 10});
      expect(cursorParams, isA<CursorPaginationParams>());
    });

    test('PaginationParams supports extra parameters and flattens toQueryParameters()', () {
      const extra = {'query': 'flutter', 'active': true};
      const params = DefaultPaginationParams(
        page: 1,
        limit: 10,
        extra: extra,
      );

      expect(params.extra, equals(extra));
      expect(params.toJson(), equals({'page': 1, 'limit': 10, 'extra': extra}));
      expect(
        params.toQueryParameters(),
        equals({'page': 1, 'limit': 10, 'query': 'flutter', 'active': true}),
      );

      final deserialized = DefaultPaginationParams.fromJson(params.toJson());
      expect(deserialized.extra, equals(extra));

      const skipParams = SkipPaginationParams(skip: 20, limit: 10, extra: extra);
      expect(
        skipParams.toQueryParameters(),
        equals({'skip': 20, 'limit': 10, 'query': 'flutter', 'active': true}),
      );

      const cursorParams = CursorPaginationParams(cursor: 'token_1', limit: 10, extra: extra);
      expect(
        cursorParams.toQueryParameters(),
        equals({'cursor': 'token_1', 'limit': 10, 'query': 'flutter', 'active': true}),
      );
    });

    test('NetworkConfigEntity props props equality', () {
      const config1 = NetworkConfigEntity(
        baseUrl: 'https://api.com',
        excludedPaths: ['/ping'],
        refreshTokenApiEndpoint: '/refresh',
        accessTokenKey: 'access',
        refreshTokenKey: 'refresh',
      );
      const config2 = NetworkConfigEntity(
        baseUrl: 'https://api.com',
        excludedPaths: ['/ping'],
        refreshTokenApiEndpoint: '/refresh',
        accessTokenKey: 'access',
        refreshTokenKey: 'refresh',
      );
      expect(config1.props, equals(config2.props));
    });

    test('ApiRequestOptions, NetworkFile, NetworkFormData props equality', () {
      const options = ApiRequestOptions(isAuthorized: true, requestId: 'r1');
      expect(options.props, containsAll([true, 'r1']));

      const file = NetworkFile(fieldName: 'f', filePath: '/p');
      expect(file.props, containsAll(['f', '/p']));

      const formData = NetworkFormData(fields: {'a': 'b'});
      expect(formData.props, containsAll([{'a': 'b'}, <NetworkFile>[]]));
    });
  });
}
