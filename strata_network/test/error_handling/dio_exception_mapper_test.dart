import 'package:dio/dio.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DioExceptionMapper Tests', () {
    late DioExceptionMapper mapper;

    setUp(() {
      mapper = DioExceptionMapper((response) {
        final data = response?.data;
        if (data is Map<String, dynamic>) {
          return TestErrorResponseModel(
            status: response?.statusCode ?? 500,
            developerMessage: data['message'] as String? ?? 'Error',
            timestamp: DateTime.now(),
          );
        }
        return TestErrorResponseModel(
          status: response?.statusCode ?? 500,
          developerMessage: 'Error',
          timestamp: DateTime.now(),
        );
      });
    });

    test('maps non-DioException to UnknownFailure', () {
      final failure = mapper.mapException('some error', null);
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, equals('some error'));
    });

    test('maps DioExceptionType.cancel to ConnectionFailure CANCELLED', () {
      final dioError = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = mapper.mapException(dioError, null);
      expect(failure, isA<ConnectionFailure>());
      expect(failure.code, equals('CANCELLED'));
    });

    test('maps timeout DioExceptions to ConnectionFailure TIMEOUT', () {
      final types = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];
      for (final type in types) {
        final dioError = DioException(
          type: type,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = mapper.mapException(dioError, null);
        expect(failure, isA<ConnectionFailure>());
        expect(failure.code, equals('TIMEOUT'));
      }
    });

    test('maps connection and unknown DioExceptions to ConnectionFailure NO_INTERNET', () {
      final types = [
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      ];
      for (final type in types) {
        final dioError = DioException(
          type: type,
          requestOptions: RequestOptions(path: '/test'),
        );
        final failure = mapper.mapException(dioError, null);
        expect(failure, isA<ConnectionFailure>());
        expect(failure.code, equals('NO_INTERNET'));
      }
    });

    test('maps badCertificate to ConnectionFailure SSL_ERR', () {
      final dioError = DioException(
        type: DioExceptionType.badCertificate,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = mapper.mapException(dioError, null);
      expect(failure, isA<ConnectionFailure>());
      expect(failure.code, equals('SSL_ERR'));
    });

    test('maps badResponse with null response to UnknownFailure', () {
      final dioError = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
      );
      final failure = mapper.mapException(dioError, null);
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, equals('Empty response from server'));
    });

    test('maps badResponse status codes 401, 403, 422, and 500 correctly', () {
      final requestOpts = RequestOptions(path: '/test');

      // 401
      final err401 = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOpts,
        response: Response(
          statusCode: 401,
          requestOptions: requestOpts,
          data: {'message': 'Unauthorized access'},
        ),
      );
      final failure401 = mapper.mapException(err401, null);
      expect(failure401, isA<UnauthorizedFailure>());
      expect(failure401.code, equals('AUTH_401'));

      // 403
      final err403 = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOpts,
        response: Response(
          statusCode: 403,
          requestOptions: requestOpts,
          data: {'message': 'Forbidden access'},
        ),
      );
      final failure403 = mapper.mapException(err403, null);
      expect(failure403, isA<UnauthorizedFailure>());
      expect(failure403.code, equals('AUTH_403'));

      // 422
      final err422 = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOpts,
        response: Response(
          statusCode: 422,
          requestOptions: requestOpts,
          data: {'message': 'Validation error'},
        ),
      );
      final failure422 = mapper.mapException(err422, null);
      expect(failure422, isA<ValidationFailure>());

      // 500
      final err500 = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: requestOpts,
        response: Response(
          statusCode: 500,
          requestOptions: requestOpts,
          headers: Headers.fromMap({'x-request-id': ['req-123']}),
          data: {'message': 'Server error'},
        ),
      );
      final failure500 = mapper.mapException(err500, null) as ServerFailure;
      expect(failure500.statusCode, equals(500));
      expect(failure500.requestId, equals('req-123'));
    });
  });
}
