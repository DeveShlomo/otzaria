import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:otzaria/data/constants/database_constants.dart';
import 'package:otzaria/empty_library/bloc/empty_library_bloc.dart';
import 'package:otzaria/empty_library/bloc/empty_library_event.dart';
import 'package:otzaria/empty_library/bloc/empty_library_state.dart';
import 'package:otzaria/settings/engine/settings_repository.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmptyLibraryBloc', () {
    test('parseLatestDatabaseAsset מחזיר את asset של seforim.db.zst', () {
      final asset = EmptyLibraryBloc.parseLatestDatabaseAsset({
        'assets': [
          {
            'name': '1-2.DIFF.zst',
            'browser_download_url': 'https://example.com/1-2.DIFF.zst',
          },
          {
            'name': 'seforim.db.zst',
            'browser_download_url': 'https://example.com/seforim.db.zst',
          },
        ],
      });

      expect(asset, isNotNull);
      expect(asset!.assetName, 'seforim.db.zst');
      expect(asset.downloadUrl, 'https://example.com/seforim.db.zst');
    });

    test('DownloadLibraryRequested מוריד DB מהרליס האחרון ומחלץ אותו',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'otzaria-empty-library-test-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');
      await Settings.setValue<String>(
        SettingsRepository.keyLibraryFolderName,
        '',
      );

      final downloadedBytes = utf8.encode('compressed-db');
      final talmudBytes = utf8.encode('compressed-talmud');
      final catalogBytes = utf8.encode('compressed-catalog');
      final lexicalBytes = utf8.encode('lexical-dictionary');
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'assets': [
                {
                  'name': '2-3.DIFF.zst',
                  'browser_download_url':
                      'https://example.com/releases/2-3.DIFF.zst',
                },
                {
                  'name': 'seforim.db.zst',
                  'browser_download_url':
                      'https://example.com/releases/seforim.db.zst',
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }

        if (request.url.toString() ==
            'https://example.com/releases/seforim.db.zst') {
          return http.Response.bytes(downloadedBytes, 200);
        }

        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('talmud_bavli_latest.tar.zst')) {
          return http.Response.bytes(talmudBytes, 200);
        }

        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('otzar-HB_catalog.db.zst')) {
          return http.Response.bytes(catalogBytes, 200);
        }

        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('/lexical.db')) {
          return http.Response.bytes(lexicalBytes, 200);
        }

        return http.Response('not found', 404);
      });

      final bloc = EmptyLibraryBloc(
        httpClient: client,
        defaultLibraryPathOverride: tempDir.path,
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          // הקובץ הזמני חייב להיות בתיקיית temp של המערכת
          expect(archivePath, startsWith(Directory.systemTemp.path));
          // יכול להיות גם seforim.db.zst וגם otzar-HB_catalog.db.zst
          final basename = path.basename(archivePath);
          if (basename == 'otzaria_seforim.db.zst') {
            expect(await File(archivePath).readAsBytes(), downloadedBytes);
            expect(
              outputPath,
              path.join(tempDir.path, DatabaseConstants.databaseFileName),
            );
            await File(outputPath).writeAsBytes(const [1, 2, 3], flush: true);
          } else if (basename == 'otzaria_otzar-HB_catalog.db.zst') {
            expect(await File(archivePath).readAsBytes(), catalogBytes);
            await File(outputPath).writeAsBytes(const [4, 5, 6], flush: true);
          } else {
            fail('Unexpected archive: $archivePath');
          }
        },
        extractTarArchive: (archivePath, outputDir, onProgress) async {
          expect(archivePath, startsWith(Directory.systemTemp.path));
          expect(path.basename(archivePath), 'otzaria_talmud_bavli.tar.zst');
          expect(await File(archivePath).readAsBytes(), talmudBytes);
          // לא יוצרים קבצי tar אמיתיים בטסט — מדמים חילוץ
        },
      );
      addTearDown(bloc.close);

      final directorySelectedFuture = bloc.stream
          .where((state) => state is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(DownloadLibraryRequested());

      final selectedState = await directorySelectedFuture.timeout(
        const Duration(seconds: 5),
      );

      expect(selectedState.selectedPath, tempDir.path);
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        tempDir.path,
      );
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryFolderName),
        '',
      );
      // הקובץ הזמני נמחק אוטומטית
      expect(
        File(path.join(Directory.systemTemp.path, 'otzaria_seforim.db.zst'))
            .existsSync(),
        isFalse,
      );
      // מילון החיפוש המקורב (לא דחוס) הועתק לתיקיית הספרייה ליד seforim.db.
      expect(
        File(path.join(tempDir.path, 'lexical.db')).existsSync(),
        isTrue,
      );
    });

    test('פס ההתקדמות מאוחד על פני כל הקבצים — רק הכותרת מתחלפת', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'otzaria-combined-progress-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryFolderName, '');

      // גדלים שונים בכוונה, כדי לוודא שכולם נספרים יחד.
      final seforimBytes = utf8.encode('A' * 100);
      final talmudBytes = utf8.encode('B' * 200);
      final catalogBytes = utf8.encode('C' * 700);
      final lexicalBytes = utf8.encode('D' * 300);
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'assets': [
                {
                  'name': 'seforim.db.zst',
                  'browser_download_url':
                      'https://example.com/releases/seforim.db.zst',
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.toString() ==
            'https://example.com/releases/seforim.db.zst') {
          return http.Response.bytes(seforimBytes, 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('talmud_bavli_latest.tar.zst')) {
          return http.Response.bytes(talmudBytes, 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('otzar-HB_catalog.db.zst')) {
          return http.Response.bytes(catalogBytes, 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('/lexical.db')) {
          return http.Response.bytes(lexicalBytes, 200);
        }
        return http.Response('not found', 404);
      });

      final bloc = EmptyLibraryBloc(
        httpClient: client,
        defaultLibraryPathOverride: tempDir.path,
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          await File(outputPath).writeAsBytes(const [1], flush: true);
        },
        extractTarArchive: (archivePath, outputDir, onProgress) async {},
      );
      addTearDown(bloc.close);

      final downloading = <EmptyLibraryDownloading>[];
      final sub = bloc.stream.listen((state) {
        if (state is EmptyLibraryDownloading) downloading.add(state);
      });
      addTearDown(sub.cancel);

      final done =
          bloc.stream.where((s) => s is EmptyLibraryDirectorySelected).first;
      bloc.add(DownloadLibraryRequested());
      await done.timeout(const Duration(seconds: 5));

      // כל הכותרות הופיעו (רק הכותרת מתחלפת בין הקבצים).
      final titles =
          downloading.map((s) => s.message.split('\n').first).toSet();
      expect(
          titles,
          containsAll(<String>[
            'מוריד את ספריית אוצריא',
            'מוריד את התלמוד הבבלי',
            'מוריד את הקטלוגים',
            'מוריד מילון לחיפוש המקורב',
          ]));

      // הפס מאוחד: בזמן הצגת הכותרת של הקובץ הראשון הוא לא מגיע ל-100%
      // (סימן שהוא מתייחס לסכום שלושת הקבצים ולא לקובץ בודד).
      final seforimStates = downloading
          .where((s) => s.message.startsWith('מוריד את ספריית אוצריא'));
      expect(seforimStates, isNotEmpty);
      expect(
        seforimStates.map((s) => s.progress).reduce((a, b) => a > b ? a : b),
        lessThan(0.5),
      );

      // ההתקדמות לא יורדת ומגיעה ל-100% בסוף — כולל מילון החיפוש המקורב,
      // שהוא כעת חלק מהפס המאוחד ולא שלב נפרד.
      final progresses = downloading.map((s) => s.progress).toList();
      for (var i = 1; i < progresses.length; i++) {
        expect(progresses[i], greaterThanOrEqualTo(progresses[i - 1]));
      }
      expect(progresses.last, closeTo(1.0, 1e-9));
    });

    test(
        'כשל בהורדת המילון (best-effort) — ההורדה מסתיימת והפס עדיין מגיע ל-100%',
        () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'otzaria-lexical-fail-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryFolderName, '');

      final seforimBytes = utf8.encode('A' * 100);
      final talmudBytes = utf8.encode('B' * 200);
      final catalogBytes = utf8.encode('C' * 700);
      // המילון מחזיר 404 (מדמה release לא זמין). resolve מצליח אך ההורדה נכשלת.
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'assets': [
                {
                  'name': 'seforim.db.zst',
                  'browser_download_url':
                      'https://example.com/releases/seforim.db.zst',
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.toString() ==
            'https://example.com/releases/seforim.db.zst') {
          return http.Response.bytes(seforimBytes, 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('talmud_bavli_latest.tar.zst')) {
          return http.Response.bytes(talmudBytes, 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('otzar-HB_catalog.db.zst')) {
          return http.Response.bytes(catalogBytes, 200);
        }
        // lexical.db (וכל היתר) — 404
        return http.Response('not found', 404);
      });

      final bloc = EmptyLibraryBloc(
        httpClient: client,
        defaultLibraryPathOverride: tempDir.path,
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          await File(outputPath).writeAsBytes(const [1], flush: true);
        },
        extractTarArchive: (archivePath, outputDir, onProgress) async {},
      );
      addTearDown(bloc.close);

      final downloading = <EmptyLibraryDownloading>[];
      final sub = bloc.stream.listen((state) {
        if (state is EmptyLibraryDownloading) downloading.add(state);
      });
      addTearDown(sub.cancel);

      final done =
          bloc.stream.where((s) => s is EmptyLibraryDirectorySelected).first;
      bloc.add(DownloadLibraryRequested());
      await done.timeout(const Duration(seconds: 5));

      // כשל המילון לא חסם — הספרייה נבחרה.
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        tempDir.path,
      );
      // המילון לא הותקן (הורדתו נכשלה), אך פס ההורדה עדיין הגיע ל-100%.
      expect(
        File(path.join(tempDir.path, 'lexical.db')).existsSync(),
        isFalse,
      );
      expect(downloading.last.progress, closeTo(1.0, 1e-9));
    });

    test('StorageLocationSelected שומר את שורש הספרייה ומרענן מצב התחלה',
        () async {
      await Settings.init(cacheProvider: _MemoryCacheProvider());

      final bloc = EmptyLibraryBloc();
      addTearDown(bloc.close);

      const sdRoot = '/storage/ABCD-1234/Android/data/pkg/files';
      final done = bloc.stream
          .where((s) =>
              s is EmptyLibraryInitial &&
              Settings.getValue<String>(
                      SettingsRepository.keyAndroidLibraryRoot) ==
                  sdRoot)
          .first;
      bloc.add(StorageLocationSelected(sdRoot));
      await done.timeout(const Duration(seconds: 5));

      expect(
        Settings.getValue<String>(SettingsRepository.keyAndroidLibraryRoot),
        sdRoot,
      );
    });

    test('ImportExistingLibraryRequested מעתיק תיקיית DB קיימת אל מיקום היעד',
        () async {
      final sourceDir =
          await Directory.systemTemp.createTemp('otzaria-import-src-');
      final targetDir =
          await Directory.systemTemp.createTemp('otzaria-import-dst-');
      addTearDown(() async {
        for (final d in [sourceDir, targetDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      await File(
        path.join(sourceDir.path, DatabaseConstants.databaseFileName),
      ).writeAsBytes(const [1, 2, 3]);

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');

      final bloc = EmptyLibraryBloc();
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(ImportExistingLibraryRequested(
        sourcePath: sourceDir.path,
        targetPath: targetDir.path,
        isArchive: false,
      ));

      final selected = await selectedFuture.timeout(const Duration(seconds: 5));

      expect(selected.selectedPath, targetDir.path);
      expect(
        File(path.join(targetDir.path, DatabaseConstants.databaseFileName))
            .existsSync(),
        isTrue,
      );
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        targetDir.path,
      );
    });

    test('ImportExistingLibraryRequested מחלץ ארכיון zst אל מיקום היעד',
        () async {
      final sourceDir =
          await Directory.systemTemp.createTemp('otzaria-import-zst-src-');
      final targetDir =
          await Directory.systemTemp.createTemp('otzaria-import-zst-dst-');
      addTearDown(() async {
        for (final d in [sourceDir, targetDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      final archive = File(path.join(sourceDir.path, 'library.zst'));
      await archive.writeAsString('fake-zst');

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');

      String? extractedTo;
      final bloc = EmptyLibraryBloc(
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          extractedTo = outputPath;
          await File(outputPath).writeAsBytes(const [1, 2, 3]);
        },
      );
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(ImportExistingLibraryRequested(
        sourcePath: archive.path,
        targetPath: targetDir.path,
        isArchive: true,
      ));

      final selected = await selectedFuture.timeout(const Duration(seconds: 5));

      expect(
        extractedTo,
        path.join(targetDir.path, DatabaseConstants.databaseFileName),
      );
      expect(selected.selectedPath, targetDir.path);
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        targetDir.path,
      );
    });

    test(
        'DownloadLibraryRequested עם targetPath מוריד אל היעד ולא לברירת המחדל',
        () async {
      final defaultDir =
          await Directory.systemTemp.createTemp('otzaria-dl-default-');
      final targetDir =
          await Directory.systemTemp.createTemp('otzaria-dl-target-');
      addTearDown(() async {
        for (final d in [defaultDir, targetDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'assets': [
                {
                  'name': 'seforim.db.zst',
                  'browser_download_url':
                      'https://example.com/releases/seforim.db.zst',
                },
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }
        if (request.url.toString() ==
            'https://example.com/releases/seforim.db.zst') {
          return http.Response.bytes(utf8.encode('db'), 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('talmud_bavli_latest.tar.zst')) {
          return http.Response.bytes(utf8.encode('talmud'), 200);
        }
        if (request.url.host == 'github.com' &&
            request.url.path.endsWith('otzar-HB_catalog.db.zst')) {
          return http.Response.bytes(utf8.encode('catalog'), 200);
        }
        return http.Response('not found', 404);
      });

      final bloc = EmptyLibraryBloc(
        httpClient: client,
        defaultLibraryPathOverride: defaultDir.path,
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          await File(outputPath).writeAsBytes(const [1], flush: true);
        },
        extractTarArchive: (archivePath, outputDir, onProgress) async {},
      );
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(DownloadLibraryRequested(targetPath: targetDir.path));

      final selected = await selectedFuture.timeout(const Duration(seconds: 5));

      expect(selected.selectedPath, targetDir.path);
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        targetDir.path,
      );
    });

    test('UpdateLibraryRequested (ייבוא) מעתיק DB חדש ומוחק את הגיבוי בהצלחה',
        () async {
      final libDir =
          await Directory.systemTemp.createTemp('otzaria-update-lib-');
      final srcDir =
          await Directory.systemTemp.createTemp('otzaria-update-src-');
      addTearDown(() async {
        for (final d in [libDir, srcDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      final dbName = DatabaseConstants.databaseFileName;
      await File(path.join(libDir.path, dbName)).writeAsString('old-db');
      await File(path.join(srcDir.path, dbName)).writeAsString('new-db');

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryPath, libDir.path);

      final bloc = EmptyLibraryBloc();
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(UpdateLibraryRequested(
        isDownload: false,
        sourceFolder: srcDir.path,
        targetPath: libDir.path,
        existingLibraryPath: libDir.path,
      ));

      await selectedFuture.timeout(const Duration(seconds: 5));

      // הקובץ החדש הוחלף במקום הישן, והגיבוי הזמני נמחק.
      expect(
          await File(path.join(libDir.path, dbName)).readAsString(), 'new-db');
      final backups = Directory.systemTemp
          .listSync()
          .whereType<Directory>()
          .where((d) => path.basename(d.path).startsWith('otzaria_db_backup_'));
      expect(backups, isEmpty);
    });

    test(
        'UpdateLibraryRequested (ייבוא) משחזר את הגיבוי כשהמקור חסר seforim.db',
        () async {
      final libDir =
          await Directory.systemTemp.createTemp('otzaria-update-lib2-');
      final srcDir =
          await Directory.systemTemp.createTemp('otzaria-update-src2-');
      addTearDown(() async {
        for (final d in [libDir, srcDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      final dbName = DatabaseConstants.databaseFileName;
      await File(path.join(libDir.path, dbName)).writeAsString('old-db');
      // srcDir ריק — אין seforim.db, לכן ההעתקה תיכשל.

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryPath, libDir.path);

      final bloc = EmptyLibraryBloc();
      addTearDown(bloc.close);

      final errorFuture = bloc.stream
          .where((s) => s is EmptyLibraryError)
          .cast<EmptyLibraryError>()
          .first;

      bloc.add(UpdateLibraryRequested(
        isDownload: false,
        sourceFolder: srcDir.path,
        targetPath: libDir.path,
        existingLibraryPath: libDir.path,
      ));

      await errorFuture.timeout(const Duration(seconds: 5));

      // הקובץ הישן שוחזר, והגיבוי נוקה.
      expect(
          await File(path.join(libDir.path, dbName)).readAsString(), 'old-db');
      final backups = Directory.systemTemp
          .listSync()
          .whereType<Directory>()
          .where((d) => path.basename(d.path).startsWith('otzaria_db_backup_'));
      expect(backups, isEmpty);
    });

    test(
        'UpdateLibraryRequested (isArchive) מגבה, מחלץ ארכיון ליעד, ומוחק את הגיבוי בהצלחה',
        () async {
      final libDir =
          await Directory.systemTemp.createTemp('otzaria-update-archive-lib-');
      final srcDir =
          await Directory.systemTemp.createTemp('otzaria-update-archive-src-');
      addTearDown(() async {
        for (final d in [libDir, srcDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      final dbName = DatabaseConstants.databaseFileName;
      await File(path.join(libDir.path, dbName)).writeAsString('old-db');
      final archive = File(path.join(srcDir.path, 'library.zst'));
      await archive.writeAsString('fake-zst');

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(
          SettingsRepository.keyLibraryPath, libDir.path);

      final bloc = EmptyLibraryBloc(
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          await File(outputPath).writeAsString('new-db');
        },
      );
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(UpdateLibraryRequested(
        isDownload: false,
        isArchive: true,
        sourceFolder: archive.path,
        targetPath: libDir.path,
        existingLibraryPath: libDir.path,
      ));

      await selectedFuture.timeout(const Duration(seconds: 5));

      expect(
          await File(path.join(libDir.path, dbName)).readAsString(), 'new-db');
      final backups = Directory.systemTemp
          .listSync()
          .whereType<Directory>()
          .where((d) => path.basename(d.path).startsWith('otzaria_db_backup_'));
      expect(backups, isEmpty);
    });

    test('ImportLibraryFolderRequested מזהה ומעתיק נכסי ספרייה רגילים מתיקייה',
        () async {
      final srcDir =
          await Directory.systemTemp.createTemp('otzaria-import-folder-src-');
      final targetDir =
          await Directory.systemTemp.createTemp('otzaria-import-folder-dst-');
      addTearDown(() async {
        for (final d in [srcDir, targetDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      await File(path.join(srcDir.path, DatabaseConstants.databaseFileName))
          .writeAsString('db');
      await File(
              path.join(srcDir.path, DatabaseConstants.lexicalDatabaseFileName))
          .writeAsString('lex');
      await File(path.join(
              srcDir.path, DatabaseConstants.externalCatalogDatabaseFileName))
          .writeAsString('cat');

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');

      final bloc = EmptyLibraryBloc();
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(ImportLibraryFolderRequested(
        sourceFolder: srcDir.path,
        targetPath: targetDir.path,
      ));

      await selectedFuture.timeout(const Duration(seconds: 5));

      expect(
        await File(
                path.join(targetDir.path, DatabaseConstants.databaseFileName))
            .exists(),
        isTrue,
      );
      expect(
        await File(path.join(
                targetDir.path, DatabaseConstants.lexicalDatabaseFileName))
            .exists(),
        isTrue,
      );
      expect(
        await File(path.join(targetDir.path,
                DatabaseConstants.externalCatalogDatabaseFileName))
            .exists(),
        isTrue,
      );
      expect(
        Settings.getValue<String>(SettingsRepository.keyLibraryPath),
        targetDir.path,
      );
    });

    test(
        'ImportLibraryFolderRequested מחלץ seforim.db.zst דחוס אם אין גרסה רגילה',
        () async {
      final srcDir = await Directory.systemTemp
          .createTemp('otzaria-import-folder-zst-src-');
      final targetDir = await Directory.systemTemp
          .createTemp('otzaria-import-folder-zst-dst-');
      addTearDown(() async {
        for (final d in [srcDir, targetDir]) {
          if (await d.exists()) await d.delete(recursive: true);
        }
      });

      await File(
              path.join(srcDir.path, DatabaseConstants.databaseArchiveFileName))
          .writeAsString('fake-zst');

      await Settings.init(cacheProvider: _MemoryCacheProvider());
      await Settings.setValue<String>(SettingsRepository.keyLibraryPath, '');

      String? extractedTo;
      final bloc = EmptyLibraryBloc(
        extractCompressedDatabase: (archivePath, outputPath, onProgress) async {
          extractedTo = outputPath;
          await File(outputPath).writeAsString('db');
        },
      );
      addTearDown(bloc.close);

      final selectedFuture = bloc.stream
          .where((s) => s is EmptyLibraryDirectorySelected)
          .cast<EmptyLibraryDirectorySelected>()
          .first;

      bloc.add(ImportLibraryFolderRequested(
        sourceFolder: srcDir.path,
        targetPath: targetDir.path,
      ));

      await selectedFuture.timeout(const Duration(seconds: 5));

      expect(extractedTo,
          path.join(targetDir.path, DatabaseConstants.databaseFileName));
    });
  });
}

class _MemoryCacheProvider extends CacheProvider {
  final Map<String, Object?> _values = {};

  @override
  Future<void> init() async {}

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  Set getKeys() => _values.keys.toSet();

  @override
  bool? getBool(String key, {bool? defaultValue}) =>
      _values[key] as bool? ?? defaultValue;

  @override
  double? getDouble(String key, {double? defaultValue}) =>
      _values[key] as double? ?? defaultValue;

  @override
  int? getInt(String key, {int? defaultValue}) =>
      _values[key] as int? ?? defaultValue;

  @override
  String? getString(String key, {String? defaultValue}) =>
      _values[key] as String? ?? defaultValue;

  @override
  T? getValue<T>(String key, {T? defaultValue}) {
    final value = _values[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> removeAll() async {
    _values.clear();
  }

  @override
  Future<void> setBool(String key, bool? value) async {
    _values[key] = value;
  }

  @override
  Future<void> setDouble(String key, double? value) async {
    _values[key] = value;
  }

  @override
  Future<void> setInt(String key, int? value) async {
    _values[key] = value;
  }

  @override
  Future<void> setObject<T>(String key, T? value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String? value) async {
    _values[key] = value;
  }
}
