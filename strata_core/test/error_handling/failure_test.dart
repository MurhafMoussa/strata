import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('Failure Hierarchy', () {
    test('StorageFailure should set default code and props', () {
      const failure = StorageFailure(message: 'Storage failed');
      expect(failure.message, equals('Storage failed'));
      expect(failure.code, equals('STORAGE_ERR'));
      expect(failure.props, equals(['Storage failed', 'STORAGE_ERR', null, null]));
      expect(failure.stringify, isTrue);
    });

    test('ServerFailure should store statusCode and requestId', () {
      const failure = ServerFailure(
        message: 'Internal Server Error',
        statusCode: 500,
        requestId: 'req-123',
      );
      expect(failure.message, equals('Internal Server Error'));
      expect(failure.statusCode, equals(500));
      expect(failure.requestId, equals('req-123'));
      expect(failure.code, equals('SERVER_ERR'));
      expect(
        failure.props,
        equals(['Internal Server Error', 'SERVER_ERR', null, null, 500, 'req-123']),
      );
    });

    test('UnauthorizedFailure should set default message and code', () {
      const failure = UnauthorizedFailure();
      expect(failure.message, equals('Access denied'));
      expect(failure.code, equals('ACCESS_DENIED'));
    });

    test('BusinessFailure should store custom message and default code', () {
      const failure = BusinessFailure(message: 'Insufficient balance');
      expect(failure.message, equals('Insufficient balance'));
      expect(failure.code, equals('BIZ_RULE'));
    });

    test('UnknownFailure should set default code', () {
      const failure = UnknownFailure(message: 'Unexpected error');
      expect(failure.message, equals('Unexpected error'));
      expect(failure.code, equals('UNKNOWN'));
    });

    test('ConnectionFailure should set default message and code', () {
      const failure = ConnectionFailure();
      expect(failure.message, equals('No internet connection'));
      expect(failure.code, equals('NO_INTERNET'));
    });

    test('ValidationFailure should store message and set default code', () {
      const failure = ValidationFailure(message: 'Invalid email format');
      expect(failure.message, equals('Invalid email format'));
      expect(failure.code, equals('VALIDATION_ERR'));
    });
  });
}
