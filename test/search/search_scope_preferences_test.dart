import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/storage/hive_data_provider.dart';
import '../test_helpers/memory_cache_provider.dart';
import 'package:otzaria/search/search_scope_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchScopePreferences', () {
    setUp(() async {
      await setUpInMemorySettings();
    });

    test('שומר ומחזיר מצב של חיפוש בכל הקטגוריות', () async {
      await SearchScopePreferences.save(
        searchAllCategories: true,
        manualFacets: {'/תנ"ך', '/הלכה/שולחן ערוך'},
      );

      final loaded = SearchScopePreferences.load();

      expect(loaded.searchAllCategories, isTrue);
      expect(
        loaded.manualFacets,
        {'/תנ"ך', '/הלכה/שולחן ערוך'},
      );
    });

    test('מסנן ערכים לא תקינים ושומר facets מנורמלים בלבד', () async {
      await Settings.setValue<String>(
        'key-search-manual-category-facets',
        '["", "/", "תנך", "//הלכה///שוע"]',
      );
      await Settings.setValue<bool>(
        'key-search-all-categories-enabled',
        false,
      );

      final loaded = SearchScopePreferences.load();

      expect(loaded.searchAllCategories, isFalse);
      expect(loaded.manualFacets, {'/תנך', '/הלכה/שוע'});
    });

    test('שומר מצב של תחום חיפוש ידני ריק בלי להדליק את כל הקטגוריות',
        () async {
      await SearchScopePreferences.save(
        searchAllCategories: false,
        manualFacets: const {},
      );

      final loaded = SearchScopePreferences.load();

      expect(loaded.searchAllCategories, isFalse);
      expect(loaded.manualFacets, isEmpty);
    });

    test('טוען מצב persisted של תחום ידני ריק כפי שנשמר', () async {
      await Settings.setValue<bool>('key-search-all-categories-enabled', false);
      await Settings.setValue<String>(
        'key-search-manual-category-facets',
        '[]',
      );

      final loaded = SearchScopePreferences.load();

      expect(loaded.searchAllCategories, isFalse);
      expect(loaded.manualFacets, isEmpty);
    });

    test('מטפל ב-payload חוקי שאינו רשימה בלי לשנות את מצב הסוויץ׳', () async {
      await Settings.setValue<bool>('key-search-all-categories-enabled', false);
      await Settings.setValue<String>(
        'key-search-manual-category-facets',
        '{"unexpected":true}',
      );

      final loaded = SearchScopePreferences.load();

      expect(loaded.searchAllCategories, isFalse);
      expect(loaded.manualFacets, isEmpty);
    });
  });
}
