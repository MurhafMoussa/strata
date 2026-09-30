import 'package:fpdart/fpdart.dart';
import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

class FakeSensitiveStorage implements SensitiveStorageInterface {
  final Map<String, String> _store = {};

  @override
  ResultFuture<String?> read(String key) async {
    return right(_store[key]);
  }

  @override
  ResultFuture<Unit> save(String key, String value) async {
    _store[key] = value;
    return right(unit);
  }

  @override
  ResultFuture<Unit> delete(String key) async {
    _store.remove(key);
    return right(unit);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    _store.clear();
    return right(unit);
  }

  @override
  ResultFuture<bool> containsKey(String key) async {
    return right(_store.containsKey(key));
  }
}

void main() {
  group('SensitiveStorageInterface Contract', () {
    late SensitiveStorageInterface storage;

    setUp(() {
      storage = FakeSensitiveStorage();
    });

    test('should save, read, containsKey, delete and deleteAll correctly', () async {
      // containsKey false initially
      final initialCheck = await storage.containsKey('token');
      expect(initialCheck, equals(right(false)));

      // save
      final saveResult = await storage.save('token', 'secret_value');
      expect(saveResult, equals(right(unit)));

      // containsKey true after save
      final postSaveCheck = await storage.containsKey('token');
      expect(postSaveCheck, equals(right(true)));

      // read
      final readResult = await storage.read('token');
      expect(readResult, equals(right('secret_value')));

      // delete
      final deleteResult = await storage.delete('token');
      expect(deleteResult, equals(right(unit)));

      // read after delete is null
      final postDeleteRead = await storage.read('token');
      expect(postDeleteRead, equals(right(null)));

      // deleteAll
      await storage.save('key1', 'val1');
      await storage.save('key2', 'val2');
      final clearResult = await storage.deleteAll();
      expect(clearResult, equals(right(unit)));

      final key1Check = await storage.containsKey('key1');
      expect(key1Check, equals(right(false)));
    });
  });
}
