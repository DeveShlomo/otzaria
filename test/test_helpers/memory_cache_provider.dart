import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:otzaria/core/storage/hive_data_provider.dart';

Directory? _memorySettingsTempDir;

/// פותח Hive box בתיקייה זמנית ומגדיר אותו ב-[HiveCache] לצרכי טסטים.
/// קרא ל-[tearDownInMemorySettings] בסוף הטסט לניקוי.
Future<void> setUpInMemorySettings() async {
  _memorySettingsTempDir =
      await Directory.systemTemp.createTemp('hive_settings_test_');
  Hive.init(_memorySettingsTempDir!.path);
  final box = await Hive.openBox<dynamic>(HiveCache.keyName);
  HiveCache.setBoxForTesting(box);
}

/// סוגר את Hive ומוחק את התיקייה הזמנית שנפתחה ב-[setUpInMemorySettings].
Future<void> tearDownInMemorySettings() async {
  await Hive.close();
  await _memorySettingsTempDir?.delete(recursive: true);
  _memorySettingsTempDir = null;
}
