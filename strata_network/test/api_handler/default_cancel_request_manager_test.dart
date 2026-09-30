import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultCancelRequestManager Tests', () {
    late DefaultCancelRequestManager manager;

    setUp(() {
      manager = DefaultCancelRequestManager();
    });

    test('registerRequest creates distinct tokens for same requestId', () {
      final token1 = manager.registerRequest('get_users');
      final token2 = manager.registerRequest('get_users');

      expect(token1, isNot(same(token2)));
      expect(manager.activeRequestCount, equals(2));
      expect(manager.hasActiveRequests, isTrue);
    });

    test('cancelToken cancels specific token instance only', () {
      final token1 = manager.registerRequest('get_users');
      final token2 = manager.registerRequest('get_users');

      manager.cancelToken(token1, reason: 'cancelled token 1');

      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isFalse);
    });

    test('cancelRequest cancels all active tokens for requestId', () {
      final token1 = manager.registerRequest('get_users');
      final token2 = manager.registerRequest('get_users');
      final token3 = manager.registerRequest('other_request');

      manager.cancelRequest('get_users', reason: 'user navigated away');

      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isTrue);
      expect(token3.isCancelled, isFalse);
    });

    test('unregisterToken removes specific token and cleans up empty map keys', () {
      final token1 = manager.registerRequest('get_users');
      final token2 = manager.registerRequest('get_users');

      manager.unregisterToken('get_users', token1);
      expect(manager.activeRequestCount, equals(1));

      manager.unregisterToken('get_users', token2);
      expect(manager.activeRequestCount, equals(0));
      expect(manager.hasActiveRequests, isFalse);
    });

    test('cancelAll cancels all tokens across all request IDs', () {
      final token1 = manager.registerRequest('req_1');
      final token2 = manager.registerRequest('req_2');

      manager.cancelAll(reason: 'app closing');

      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isTrue);
      expect(manager.activeRequestCount, equals(0));
      expect(manager.hasActiveRequests, isFalse);
    });

    test('PaginatedCancelRequestManagerX extension registers and cancels requests using PaginationParams', () {
      const defaultParams = DefaultPaginationParams(page: 1, limit: 20);
      const skipParams = SkipPaginationParams(skip: 10, limit: 10);
      const cursorParams = CursorPaginationParams(cursor: 'tok_1', limit: 20);

      final token1 = manager.registerPaginationRequest(defaultParams);
      final token2 = manager.registerPaginationRequest(skipParams);
      final token3 = manager.registerPaginationRequest(cursorParams);

      expect(manager.activeRequestCount, equals(3));

      manager.cancelPaginationRequest(defaultParams, reason: 'Refreshed');
      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isFalse);
      expect(token3.isCancelled, isFalse);

      manager.cancelPaginationRequest(skipParams);
      expect(token2.isCancelled, isTrue);

      manager.cancelPaginationRequest(cursorParams);
      expect(token3.isCancelled, isTrue);
    });
  });
}
