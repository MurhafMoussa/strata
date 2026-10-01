import 'package:strata_network/strata_network.dart';
import 'package:test/test.dart';

void main() {
  group('Network Models Tests', () {
    test('NetworkConfigEntity props equality', () {
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
