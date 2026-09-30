import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strata_state Dependency & Package Boundary Audit', () {
    const prohibitedDependencies = [
      'strata_network',
      'strata_storage',
      'strata_navigation',
      'strata_ui',
      'go_router',
      'dio',
      'hive',
      'pinput',
      'easy_refresh',
    ];

    test('pubspec.yaml must NOT contain prohibited network, storage, or navigation dependencies', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml should exist in package root');

      final content = pubspecFile.readAsStringSync();

      for (final dep in prohibitedDependencies) {
        final dependencyPattern = RegExp('^\\s*$dep\\s*:', multiLine: true);
        expect(
          dependencyPattern.hasMatch(content),
          isFalse,
          reason: 'strata_state pubspec.yaml MUST NOT depend on $dep',
        );
      }
    });

    test('lib files must NOT import prohibited sub-packages or libraries', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

      final prohibitedImportPatterns = prohibitedDependencies
          .map((dep) => 'package:$dep/')
          .toList();

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final pattern in prohibitedImportPatterns) {
          expect(
            content.contains(pattern),
            isFalse,
            reason: '${file.path} contains forbidden import $pattern',
          );
        }
      }
    });
  });
}
