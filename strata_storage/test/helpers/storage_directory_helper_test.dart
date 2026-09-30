import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:strata_storage/strata_storage.dart';

class FakePathProviderPlatform
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testPath = Directory.systemTemp.createTempSync('strata_storage_test').path;

  @override
  Future<String?> getTemporaryPath() async => testPath;

  @override
  Future<String?> getApplicationSupportPath() async => testPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => testPath;

  @override
  Future<String?> getLibraryPath() async => testPath;

  @override
  Future<String?> getExternalStoragePath() async => testPath;

  @override
  Future<List<String>?> getExternalCachePaths() async => [testPath];

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [testPath];

  @override
  Future<String?> getDownloadsPath() async => testPath;

  @override
  Future<String?> getApplicationCachePath() async => testPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePathProviderPlatform fakePathProvider;

  setUp(() {
    fakePathProvider = FakePathProviderPlatform();
    PathProviderPlatform.instance = fakePathProvider;
  });

  group('StorageDirectoryHelper', () {
    test('resolves default support database directory', () async {
      final result = await StorageDirectoryHelper.getDatabaseDirectoryPath();

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be Right'),
        (path) => expect(path, contains(fakePathProvider.testPath)),
      );
    });

    test('resolves directory with subDirectory and creates it', () async {
      final result = await StorageDirectoryHelper.getDatabaseDirectoryPath(
        type: StorageDirectoryType.documents,
        subDirectory: 'user_db',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should be Right'),
        (path) {
          expect(path, contains('user_db'));
          expect(Directory(path).existsSync(), isTrue);
        },
      );
    });

    test('resolves temporary storage directory', () async {
      final result = await StorageDirectoryHelper.getDatabaseDirectoryPath(
        type: StorageDirectoryType.temporary,
      );

      expect(result.isRight(), isTrue);
    });
  });
}
