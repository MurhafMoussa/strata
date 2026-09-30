import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strata_core/strata_core.dart';
import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ApiRequestOptions & NetworkFormData Models Tests', () {
    test('ApiRequestOptions has correct default values', () {
      const options = ApiRequestOptions();
      expect(options.isAuthorized, isFalse);
      expect(options.shouldCache, isFalse);
      expect(options.enableRetry, isTrue);
      expect(options.maxRetryAttempts, isNull);
      expect(options.retryDelay, isNull);
      expect(options.requestId, isNull);
      expect(options.headers, isNull);
      expect(options.onSendProgress, isNull);
      expect(options.onReceiveProgress, isNull);
      expect(options.extra, isNull);
    });

    test('ApiRequestOptions supports value equality', () {
      const options1 = ApiRequestOptions(
        isAuthorized: true,
        enableRetry: false,
        headers: {'Authorization': 'Bearer 123'},
      );
      const options2 = ApiRequestOptions(
        isAuthorized: true,
        enableRetry: false,
        headers: {'Authorization': 'Bearer 123'},
      );
      expect(options1, equals(options2));
    });

    test('NetworkFormData and NetworkFile encapsulate fields and files correctly', () {
      const file = NetworkFile(
        fieldName: 'avatar',
        filePath: '/tmp/avatar.png',
        filename: 'avatar.png',
        contentType: 'image/png',
      );
      const formData = NetworkFormData(
        fields: {'name': 'John'},
        files: [file],
      );

      expect(file.fieldName, equals('avatar'));
      expect(file.filePath, equals('/tmp/avatar.png'));
      expect(file.filename, equals('avatar.png'));
      expect(file.contentType, equals('image/png'));

      expect(formData.fields, equals({'name': 'John'}));
      expect(formData.files, hasLength(1));
      expect(formData.files.first, equals(file));
    });
  });

  group('DioApiHandler Tests', () {
    late MockDio mockDio;
    late MockNetworkExceptionMapper mockExceptionMapper;
    late MockCancelRequestManager mockCancelManager;
    late DioApiHandler handler;

    setUpAll(() {
      registerTestFallbacks();
    });

    setUp(() {
      mockDio = MockDio();
      mockExceptionMapper = MockNetworkExceptionMapper();
      mockCancelManager = MockCancelRequestManager();

      handler = DioApiHandler(
        mockDio,
        mockExceptionMapper,
        mockCancelManager,
      );
    });

    test('get executes successful GET request and applies request options correctly', () async {
      final reqOptions = RequestOptions(path: '/users');
      Options? capturedOptions;

      when(
        () => mockDio.get<dynamic>(
          '/users',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        capturedOptions = invocation.namedArguments[#options] as Options?;
        return Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'name': 'John Doe'},
        );
      });

      const options = ApiRequestOptions(
        isAuthorized: true,
        shouldCache: true,
        enableRetry: false,
        maxRetryAttempts: 3,
        retryDelay: Duration(seconds: 2),
        headers: {'X-Custom-Header': 'CustomValue'},
        extra: {'customExtraKey': 'customExtraValue'},
      );

      final result = await handler.get<String>(
        '/users',
        parser: (Map<String, dynamic> json) => json['name'] as String,
        options: options,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), equals('John Doe'));

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.headers, equals({'X-Custom-Header': 'CustomValue'}));
      expect(capturedOptions!.extra!['isAuthorized'], isTrue);
      expect(capturedOptions!.extra!['shouldCache'], isTrue);
      expect(capturedOptions!.extra!['enableRetry'], isFalse);
      expect(capturedOptions!.extra!['maxRetryAttempts'], equals(3));
      expect(capturedOptions!.extra!['retryDelay'], equals(2000));
      expect(capturedOptions!.extra!['customExtraKey'], equals('customExtraValue'));
    });

    test('registers and unregisters cancel token when requestId is provided in options', () async {
      final dummyToken = CancelToken();
      when(() => mockCancelManager.registerRequest('req_123'))
          .thenReturn(dummyToken);
      when(() => mockCancelManager.unregisterToken('req_123', dummyToken))
          .thenAnswer((_) {});

      final reqOptions = RequestOptions(path: '/users');
      when(
        () => mockDio.get<dynamic>(
          '/users',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: dummyToken,
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'id': '123'},
        ),
      );

      await handler.get<String>(
        '/users',
        parser: (Map<String, dynamic> json) => json['id'] as String,
        options: const ApiRequestOptions(requestId: 'req_123'),
      );

      verify(() => mockCancelManager.registerRequest('req_123')).called(1);
      verify(() => mockCancelManager.unregisterToken('req_123', dummyToken)).called(1);
    });

    test('post converts NetworkFormData fields and files into Dio FormData', () async {
      final reqOptions = RequestOptions(path: '/upload');
      dynamic capturedData;
      Options? capturedDioOptions;

      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/test.png')..writeAsStringSync('dummy content');

      when(
        () => mockDio.post<dynamic>(
          '/upload',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        capturedData = invocation.namedArguments[#data];
        capturedDioOptions = invocation.namedArguments[#options] as Options?;
        return Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'status': 'success'},
        );
      });

      final file = NetworkFile(
        fieldName: 'avatar',
        filePath: tempFile.path,
        filename: 'test.png',
        contentType: 'image/png',
      );
      final formData = NetworkFormData(
        fields: const {'username': 'johndoe', 'age': 30},
        files: [file],
      );

      final result = await handler.post<String>(
        '/upload',
        parser: (json) => json['status'] as String,
        formData: formData,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => ''), equals('success'));
      expect(capturedData, isA<FormData>());

      final dioFormData = capturedData as FormData;
      final fieldKeys = dioFormData.fields.map((e) => e.key).toList();
      expect(fieldKeys, containsAll(['username', 'age']));
      expect(dioFormData.files, hasLength(1));
      expect(dioFormData.files.first.key, equals('avatar'));
      expect(capturedDioOptions!.contentType, equals(Headers.multipartFormDataContentType));

      await tempDir.delete(recursive: true);
    });

    test('get and download invoke onReceiveProgress callbacks', () async {
      double getReceiveProgress = 0;
      double downloadReceiveProgress = 0;

      final reqOptions = RequestOptions(path: '/get');
      when(
        () => mockDio.get<dynamic>(
          '/get',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final onReceive = invocation.namedArguments[#onReceiveProgress] as void Function(int, int)?;
        onReceive?.call(50, 100);
        return Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'success': true},
        );
      });

      await handler.get<bool>(
        '/get',
        parser: (j) => true,
        options: ApiRequestOptions(onReceiveProgress: (p) => getReceiveProgress = p),
      );
      expect(getReceiveProgress, equals(0.5));

      when(
        () => mockDio.download(
          '/dl.zip',
          '/dest.zip',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final onReceive = invocation.namedArguments[#onReceiveProgress] as void Function(int, int)?;
        onReceive?.call(80, 100);
        return Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: 'OK',
        );
      });

      await handler.download<String>(
        '/dl.zip',
        '/dest.zip',
        parser: (j) => j['data'] as String,
        options: ApiRequestOptions(onReceiveProgress: (p) => downloadReceiveProgress = p),
      );
      expect(downloadReceiveProgress, equals(0.8));
    });

    test('put executes PUT request with ApiRequestOptions', () async {
      final reqOptions = RequestOptions(path: '/update');
      when(
        () => mockDio.put<dynamic>(
          '/update',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'updated': true},
        ),
      );

      final result = await handler.put<bool>(
        '/update',
        parser: (json) => json['updated'] as bool,
        body: {'title': 'New Title'},
        options: const ApiRequestOptions(isAuthorized: true),
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => false), isTrue);
    });

    test('patch executes PATCH request with ApiRequestOptions', () async {
      final reqOptions = RequestOptions(path: '/patch');
      when(
        () => mockDio.patch<dynamic>(
          '/patch',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'patched': true},
        ),
      );

      final result = await handler.patch<bool>(
        '/patch',
        parser: (json) => json['patched'] as bool,
        body: {'field': 'value'},
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => false), isTrue);
    });

    test('delete executes DELETE request with ApiRequestOptions', () async {
      final reqOptions = RequestOptions(path: '/delete');
      when(
        () => mockDio.delete<dynamic>(
          '/delete',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'deleted': true},
        ),
      );

      final result = await handler.delete<bool>(
        '/delete',
        parser: (json) => json['deleted'] as bool,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => false), isTrue);
    });

    test('handles List<dynamic> response data correctly', () async {
      final reqOptions = RequestOptions(path: '/list');
      when(
        () => mockDio.get<dynamic>(
          '/list',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: ['item1', 'item2'],
        ),
      );

      final result = await handler.get<int>(
        '/list',
        parser: (json) => (json['data'] as List).length,
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => 0), equals(2));
    });

    test('returns UnknownFailure when response data is invalid type or non-Dio exception occurs', () async {
      final reqOptions = RequestOptions(path: '/invalid');
      when(
        () => mockDio.get<dynamic>(
          '/invalid',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: 12345, // invalid data type
        ),
      );

      final result = await handler.get<String>(
        '/invalid',
        parser: (json) => '',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, equals('Invalid response data')),
        (_) => fail('Should fail'),
      );

      // Non-Dio exception
      when(
        () => mockDio.get<dynamic>(
          '/exception',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(Exception('Generic error'));

      final resultExc = await handler.get<String>(
        '/exception',
        parser: (json) => '',
      );

      expect(resultExc.isLeft(), isTrue);
    });

    test('rethrows DioExceptionType.cancel in _handleResponse', () async {
      final cancelErr = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/cancel'),
      );
      when(
        () => mockDio.get<dynamic>(
          '/cancel',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(cancelErr);

      expect(
        () => handler.get<String>('/cancel', parser: (j) => ''),
        throwsA(isA<DioException>()),
      );
    });

    test('progress callbacks are invoked correctly on send and receive', () async {
      double sendProgressValue = 0;
      double receiveProgressValue = 0;

      final reqOptions = RequestOptions(path: '/progress');
      when(
        () => mockDio.post<dynamic>(
          '/progress',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onSendProgress: any(named: 'onSendProgress'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final onSend = invocation.namedArguments[#onSendProgress] as void Function(int, int)?;
        final onReceive = invocation.namedArguments[#onReceiveProgress] as void Function(int, int)?;

        onSend?.call(50, 100);
        onReceive?.call(100, 100);

        return Response<dynamic>(
          requestOptions: reqOptions,
          statusCode: 200,
          data: {'status': 'ok'},
        );
      });

      await handler.post<String>(
        '/progress',
        parser: (j) => '',
        body: {'a': 'b'},
        options: ApiRequestOptions(
          onSendProgress: (p) => sendProgressValue = p,
          onReceiveProgress: (p) => receiveProgressValue = p,
        ),
      );

      expect(sendProgressValue, equals(0.5));
      expect(receiveProgressValue, equals(1.0));
    });

    test('maps DioException to Failure when request fails', () async {
      final options = RequestOptions(path: '/error');
      final dioException = DioException(
        requestOptions: options,
        response: Response(statusCode: 500, requestOptions: options),
      );

      when(
        () => mockDio.get<dynamic>(
          '/error',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(dioException);

      when(() => mockExceptionMapper.mapException(dioException, any()))
          .thenReturn(const ServerFailure(message: 'Internal Server Error', statusCode: 500));

      final result = await handler.get<String>(
        '/error',
        parser: (Map<String, dynamic> json) => '',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should be Left'),
      );
    });
  });
}
