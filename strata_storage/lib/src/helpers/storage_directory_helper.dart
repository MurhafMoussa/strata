import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:strata_core/strata_core.dart';

/// Target directory location for local database storage.
enum StorageDirectoryType {
  /// Application documents directory.
  documents,

  /// Application support directory.
  support,

  /// Temporary directory.
  temporary,
}

/// Utility for resolving storage directory paths for native database setups (Hive, Drift, Isar).
class StorageDirectoryHelper {
  /// Resolves directory path based on [type] and optional [subDirectory], ensuring directory creation.
  static ResultFuture<String> getDatabaseDirectoryPath({
    StorageDirectoryType type = StorageDirectoryType.support,
    String? subDirectory,
  }) async {
    try {
      final Directory baseDir = switch (type) {
        StorageDirectoryType.documents => await getApplicationDocumentsDirectory(),
        StorageDirectoryType.support => await getApplicationSupportDirectory(),
        StorageDirectoryType.temporary => await getTemporaryDirectory(),
      };

      String fullPath = baseDir.path;
      if (subDirectory != null && subDirectory.isNotEmpty) {
        final separator = Platform.pathSeparator;
        fullPath = '${baseDir.path}$separator$subDirectory';
      }

      final targetDirectory = Directory(fullPath);
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      return right(targetDirectory.path);
    } catch (e, stackTrace) {
      return left(
        StorageFailure(
          message: 'Failed to resolve database directory path: $e',
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
