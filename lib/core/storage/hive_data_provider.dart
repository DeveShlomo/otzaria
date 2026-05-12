import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:otzaria/core/storage/app_paths.dart';

/// ניהול אחסון ה-key-value של האפליקציה דרך Hive.
///
/// שתי גישות שקולות לחלוטין:
///   HiveCache.getValue('key', defaultValue: false)
///   Settings.getValue('key', defaultValue: false)
class HiveCache {
  HiveCache._();

  static Box? _box;
  static const String keyName = 'app_preferences';

  static Future<void> init() async {
    if (!kIsWeb) {
      final defaultDirectory = await AppPaths.getDataRootPath();
      _box = await Hive.openBox<dynamic>(keyName, path: defaultDirectory);
    }
  }

  static T? getValue<T>(String key, {T? defaultValue}) {
    final value = _box?.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  static Future<void> setValue<T>(String key, T value) async {
    await _box?.put(key, value);
  }

  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  static Future<void> removeAll() async {
    await _box?.deleteAll(_box!.keys);
  }

  static bool containsKey(String key) => _box?.containsKey(key) ?? false;

  static Set get keys => _box?.keys.toSet() ?? {};

  /// גישה ישירה ל-box — לשימוש ב-backup ובמקומות שצריכים גישה ישירה.
  static Box? get box => _box;

  /// לשימוש בטסטים בלבד — מאפשר הזרקת box פתוח ישירות.
  @visibleForTesting
  static void setBoxForTesting(Box box) => _box = box;
}

/// Alias ל-[HiveCache] — מאפשר להשאיר קוד קיים עם Settings.getValue/setValue
/// ללא שינוי, ולא לייבא את flutter_settings_screens.
class Settings {
  Settings._();

  static T? getValue<T>(String key, {T? defaultValue}) =>
      HiveCache.getValue<T>(key, defaultValue: defaultValue);

  static Future<void> setValue<T>(String key, T value) =>
      HiveCache.setValue<T>(key, value);

  static Future<void> remove(String key) => HiveCache.remove(key);

  static void clearCache() => HiveCache.removeAll();

  static bool get isInitialized => HiveCache.box != null;
}
