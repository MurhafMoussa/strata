import 'package:strata_core/strata_core.dart';
import 'package:test/test.dart';

void main() {
  group('Params Tests', () {
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
  });
}
