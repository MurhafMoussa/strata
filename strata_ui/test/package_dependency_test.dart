import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strata_ui Package Boundary Audit', () {
    test('pubspec.yaml must NOT import prohibited state management/routing dependencies', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml should exist in strata_ui');

      final content = pubspecFile.readAsStringSync();
      final lines = content.split('\n');

      final prohibitedPackages = ['go_router', 'dio', 'hive', 'isotope', 'easy_refresh'];

      for (final package in prohibitedPackages) {
        final hasProhibited = lines.any((line) {
          final trimmed = line.trim();
          return trimmed.startsWith('$package:') || trimmed.startsWith('package:$package');
        });

        expect(
          hasProhibited,
          isFalse,
          reason: 'strata_ui pubspec.yaml MUST NOT depend on $package',
        );
      }
    });

    test('lib/ files must NOT import go_router or easy_refresh', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains("import 'package:go_router/"),
          isFalse,
          reason: '${file.path} imports go_router',
        );
        expect(
          content.contains("import 'package:easy_refresh/"),
          isFalse,
          reason: '${file.path} imports easy_refresh',
        );
      }
    });
  });
}
