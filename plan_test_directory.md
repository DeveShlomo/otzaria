# תוכנית ארגון מחדש של תיקיית `test/`

> תיקיית `test/` משקפת את מבנה `lib/`. כשמזיזים קבצים ב-`lib/`, יש להזיז את הטסטים שלהם **באותו commit**.

---

## עיקרון: test/ ו-lib/ זהים במבנה

```
lib/seforim/providers/database_library_provider.dart
   ↕
test/seforim/providers/database_library_provider_test.dart
```

---

## מפת שינויים — תיקיות test/ (Phase 1)

### Commit 1: עם `lib/seforim/`

| נתיב ישן | נתיב חדש |
|----------|---------|
| `test/data_providers/database_library_provider_test.dart` | `test/seforim/providers/database_library_provider_test.dart` |
| `test/data_providers/database_library_provider_has_book_test.dart` | `test/seforim/providers/database_library_provider_has_book_test.dart` |
| `test/data_providers/user_books_database_holder_test.dart` | `test/seforim/providers/user_books_database_holder_test.dart` |
| `test/data_providers/file_system_library_provider_test.dart` | `test/seforim/providers/file_system_library_provider_test.dart` |
| `test/data_providers/external_catalog_mapper_test.dart` | `test/seforim/providers/external_catalog_mapper_test.dart` |
| `test/data/data_providers/tantivy_data_provider_test.dart` | `test/seforim/providers/tantivy_data_provider_test.dart` |
| `test/data/data_providers/scan_external_books_test.dart` | `test/seforim/providers/scan_external_books_test.dart` |
| `test/file_sync/file_sync_bloc_test.dart` | `test/seforim/sync/file_sync_bloc_test.dart` |
| `test/file_sync/library_diff_sync_worker_test.dart` | `test/seforim/sync/library_diff_sync_worker_test.dart` |
| `test/file_sync_test.dart` | `test/seforim/sync/file_sync_test.dart` |
| `test/indexing/repository/indexing_repository_test.dart` | `test/seforim/indexing/indexing_repository_test.dart` |
| `test/indexing/indexing_isolate_service_test.dart` | `test/seforim/indexing/indexing_isolate_service_test.dart` |
| `test/migration/sync/background_sync_initializer_test.dart` | `test/seforim/migration/sync/background_sync_initializer_test.dart` |
| `test/migration/generator_create_and_process_book_test.dart` | `test/seforim/migration/generator_create_and_process_book_test.dart` |
| `test/migration/database_locked_test.dart` | `test/seforim/migration/database_locked_test.dart` |

---

### Commit 2: עם `lib/reader_memory/`

| נתיב ישן | נתיב חדש |
|----------|---------|
| `test/bookmarks/bookmark_bloc_test.dart` | `test/reader_memory/bookmarks/bookmark_bloc_test.dart` |
| `test/workspaces/bloc/workspace_bloc_test.dart` | `test/reader_memory/workspaces/workspace_bloc_test.dart` |
| `test/unit/settings/history/bookmark_model_test.dart` | `test/reader_memory/bookmarks/bookmark_model_test.dart` |

**הערה:** טסטים של `history/` אם קיימים יעברו ל-`test/reader_memory/history/`.

---

### Commit 3: עם ארגון `lib/library/` + `lib/settings/`

| נתיב ישן | נתיב חדש |
|----------|---------|
| `test/empty_library/empty_library_screen_test.dart` | `test/library/empty/empty_library_screen_test.dart` |
| `test/external_catalog/external_catalog_repository_test.dart` | `test/library/external/external_catalog_repository_test.dart` |
| `test/external_catalog/external_catalog_settings_helper_test.dart` | `test/library/external/external_catalog_settings_helper_test.dart` |
| `test/shortcuts/` (כל הקבצים) | `test/settings/shortcuts/` |

---

### Commit 5: עם `lib/ui/`

| נתיב ישן | נתיב חדש |
|----------|---------|
| `test/widgets/work_status_overlay_test.dart` | `test/ui/core/work_status_overlay_test.dart` |
| `test/widgets/indexing_status_overlay_test.dart` | `test/ui/widgets/feedback/indexing_status_overlay_test.dart` |
| `test/widgets/app_menu_test.dart` | `test/ui/widgets/misc/app_menu_test.dart` |
| `test/widgets/app_top_bar_test.dart` | `test/ui/widgets/navigation/app_top_bar_test.dart` |
| `test/widgets/context_overlay_panel_test.dart` | `test/ui/widgets/layout/context_overlay_panel_test.dart` |
| `test/widgets/dual_adaptive_reader_pane_test.dart` | `test/ui/widgets/layout/dual_adaptive_reader_pane_test.dart` |
| `test/widgets/nav_rail_item_test.dart` | `test/ui/widgets/navigation/nav_rail_item_test.dart` |
| `test/widgets/reader_side_panel_shell_test.dart` | `test/ui/widgets/layout/reader_side_panel_shell_test.dart` |
| `test/widgets/responsive_action_bar_test.dart` | `test/ui/widgets/navigation/responsive_action_bar_test.dart` |
| `test/widgets/scrollable_positioned_list_scrollbar_test.dart` | `test/ui/widgets/feedback/scrollable_positioned_list_scrollbar_test.dart` |
| `test/widgets/smart_text/render_settings_test.dart` | `test/ui/widgets/smart_text/render_settings_test.dart` |
| `test/widgets/app_dropdown_field_test.dart` | `test/ui/widgets/misc/app_dropdown_field_test.dart` |
| `test/widgets/app_search_menu_test.dart` | `test/ui/widgets/misc/app_search_menu_test.dart` |
| `test/widgets/search_pane_base_test.dart` | `test/ui/widgets/misc/search_pane_base_test.dart` |
| `test/widgets/segmented_settings_tile_test.dart` | `test/ui/widgets/inputs/segmented_settings_tile_test.dart` |
| `test/widgets/switch_settings_tile_test.dart` | `test/ui/widgets/inputs/switch_settings_tile_test.dart` |

---

### Commit 6: עם Phase 1 features UI

| נתיב ישן | נתיב חדש |
|----------|---------|
| `test/library/view/library_browser_preview_width_test.dart` | `test/ui/library/library_browser_preview_width_test.dart` |
| `test/library/view/grid_items_test.dart` | `test/ui/library/grid_items_test.dart` |

---

## תיקיות שנשארות ללא שינוי (Phase 1)

| תיקייה | סיבה |
|--------|------|
| `test/text_book/` | Phase 2 |
| `test/pdf_book/` | Phase 2 |
| `test/search/` | Phase 2 |
| `test/personal_notes/` | Phase 2 |
| `test/tools/` | Phase 2 |
| `test/plugins/` | Phase 2 / עצמאי |
| `test/navigation/` | נשאר |
| `test/settings/` | נשאר (רק shortcuts מתווסף) |
| `test/core/` | נשאר |
| `test/models/` | נשאר |
| `test/utils/` | נשאר |
| `test/services/` | נשאר |
| `test/printing/` | נשאר |
| `test/tour/` | Phase 1 commit 6 (קטן, ייבדק) |

---

## עדכון CLAUDE.md — Test File Map

אחרי כל commit, יש לעדכן את קטע "Test File Map" ב-CLAUDE.md וב-AGENTS.md
לפי הטבלאות למעלה.

**לא לעדכן מראש** — יש לעדכן רק אחרי שהקוד בפועל עבר.

---

## עדכון imports בתוך קבצי הטסטים

כשמזיזים טסט, יש לעדכן בתוכו:
```dart
// לפני:
import 'package:otzaria/data/data_providers/database_library_provider.dart';

// אחרי:
import 'package:otzaria/seforim/providers/database_library_provider.dart';
```
