import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strata Meta-Package Boundary Audit', () {
    test('pubspec.yaml must depend on all 5 sub-packages', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml should exist in strata package');

      final content = pubspecFile.readAsStringSync();

      const requiredSubPackages = [
        'strata_core',
        'strata_network',
        'strata_storage',
        'strata_state',
        'strata_ui',
      ];

      for (final subPackage in requiredSubPackages) {
        expect(
          content.contains(subPackage),
          isTrue,
          reason: 'strata pubspec.yaml MUST depend on $subPackage',
        );
      }
    });

    test('strata.dart must export all 5 sub-packages', () {
      final strataFile = File('lib/strata.dart');
      expect(strataFile.existsSync(), isTrue, reason: 'lib/strata.dart must exist');

      final content = strataFile.readAsStringSync();

      const requiredExports = [
        "export 'package:strata_core/strata_core.dart",
        "export 'package:strata_network/strata_network.dart",
        "export 'package:strata_storage/strata_storage.dart",
        "export 'package:strata_state/strata_state.dart",
        "export 'package:strata_ui/strata_ui.dart",
      ];

      for (final exportStatement in requiredExports) {
        expect(
          content.contains(exportStatement),
          isTrue,
          reason: 'strata.dart MUST export $exportStatement',
        );
      }
    });
  });
}
