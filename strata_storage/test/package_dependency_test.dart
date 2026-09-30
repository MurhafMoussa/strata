import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strata_storage Dependency & Package Boundary Audit', () {
    const prohibitedDependencies = [
      'dio',
      'flutter_bloc',
      'go_router',
      'skeletonizer',
      'easy_refresh',
      'pinput',
    ];

    test('pubspec.yaml must NOT contain prohibited UI, BLoC, or network dependencies', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml should exist in package root');

      final content = pubspecFile.readAsStringSync();

      for (final dep in prohibitedDependencies) {
        final dependencyPattern = RegExp('^\\s*$dep\\s*:', multiLine: true);
        expect(
          dependencyPattern.hasMatch(content),
          isFalse,
          reason: 'strata_storage pubspec.yaml MUST NOT depend on $dep',
        );
      }
    });

    test('lib files must NOT import prohibited UI, BLoC, or network packages', () {
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

    test('lib files must NOT define or expose NoSqlDatabaseInterface or CRUD database wrappers', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(
          content.contains('NoSqlDatabaseInterface'),
          isFalse,
          reason: '${file.path} must not mention or expose NoSqlDatabaseInterface',
        );
        expect(
          content.contains('abstract class LocalDatabaseWrapper'),
          isFalse,
          reason: '${file.path} must not expose generic database CRUD wrappers',
        );
      }
    });
  });
}
