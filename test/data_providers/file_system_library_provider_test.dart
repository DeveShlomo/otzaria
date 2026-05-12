import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/storage/hive_data_provider.dart';
import '../test_helpers/memory_cache_provider.dart';
import 'package:otzaria/data/constants/database_constants.dart';
import 'package:otzaria/data/data_providers/book_composite_key.dart';
import 'package:otzaria/data/data_providers/file_system_library_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/settings/engine/settings_repository.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileSystemLibraryProvider bundled talmud bavli', () {
    late Directory tempDir;

    setUp(() async {
      await setUpInMemorySettings();
      tempDir = await Directory.systemTemp.createTemp('otzaria_fs_provider_');
      await Settings.setValue<String>(
        SettingsRepository.keyLibraryPath,
        tempDir.path,
      );
      await Settings.setValue<String>(
        SettingsRepository.keyLibraryFolderName,
        DatabaseConstants.otzariaFolderName,
      );
      FileSystemLibraryProvider.instance.resetForTesting();
    });

    tearDown(() async {
      FileSystemLibraryProvider.instance.resetForTesting();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads Brakhot PDF from bundled talmud bavli folder at library root',
        () async {
      final talmudDir = Directory(path.join(
        tempDir.path,
        DatabaseConstants.talmudBavliFolderName,
      ));
      await talmudDir.create(recursive: true);

      final pdfPath = path.join(talmudDir.path, 'ברכות.pdf');
      await File(pdfPath).writeAsBytes(const [37, 80, 68, 70]);

      final provider = FileSystemLibraryProvider.instance;
      await provider.initialize();

      final booksByCategory = await provider.loadBooks({});
      final talmudBooks = booksByCategory[DatabaseConstants.talmudBavliFolderName];

      expect(talmudBooks, isNotNull);
      expect(talmudBooks, hasLength(1));
      expect(talmudBooks!.single, isA<PdfBook>());
      expect(talmudBooks.single.title, 'ברכות');

      final keyToPath = await provider.keyToPath;
      final storageKey = BookCompositeKey.create(
        title: 'ברכות',
        categoryId: DatabaseConstants.talmudBavliFolderName.hashCode,
        fileType: 'pdf',
      ).toStorageKey();

      expect(keyToPath[storageKey], pdfPath);
    });
  });
}
