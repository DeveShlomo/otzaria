# סדר עבודה וחלוקת קומיטים

---

## עיקרון: לוגיקה לפני UI

אם מעבירים UI תחילה, כשמשנים לוגיקה (seforim/, reader_memory/) יצטרכו לעדכן imports ב-UI **פעם שנייה**.
אם מעבירים לוגיקה תחילה — UI מעדכן imports **פעם אחת בלבד** כשהוא עובר.

**כלל אחרי כל commit:** `flutter analyze` חייב לעבור ב-0 שגיאות.

---

## Phase 1 — 7 commits

---

### Commit 1: `lib/seforim/`

**מה עושים:**
יוצרים `lib/seforim/` עם: `providers/`, `repository/`, `cache/`, `constants/`, `sync/`, `indexing/`, `migration/`

מעבירים:
- `lib/data/` כולה → `lib/seforim/providers/`, `repository/`, `cache/`, `constants/`, `book_locator.dart`
- `lib/file_sync/bloc/` + `repository/` + `library_diff_sync_worker.dart` → `lib/seforim/sync/`
- `lib/indexing/` כולה → `lib/seforim/indexing/`
- `lib/migration/` כולה → `lib/seforim/migration/`

**נשאר בינתיים:** `lib/file_sync/file_sync_widget.dart` (יעבור ל-UI בשלב 5)

**commit:**
```
refactor: יצירת lib/seforim/ — ריכוז תשתית נתוני הספרים

מאחד: lib/data/, lib/file_sync/ (logic), lib/indexing/, lib/migration/
```

---

### Commit 2: `lib/reader_memory/`

**מה עושים:**
יוצרים `lib/reader_memory/` עם: `bookmarks/`, `history/`, `workspaces/`

מעבירים (logic files בלבד, לא view/):
- `lib/bookmarks/bloc/` + `models/` + `repository/` → `lib/reader_memory/bookmarks/`
- `lib/history/bloc/` + `history_repository.dart` → `lib/reader_memory/history/`
- `lib/workspaces/bloc/` + `workspace.dart` + `workspace_repository.dart` → `lib/reader_memory/workspaces/`

**נשאר בינתיים:** `lib/bookmarks/view/`, `lib/history/view/`, `lib/workspaces/view/` (יעברו לשלב 6)

**commit:**
```
refactor: יצירת lib/reader_memory/ — ריכוז זיכרון קריאה

מאחד: bookmarks, history, workspaces
```

---

### Commit 3: ארגון `lib/core/` + `lib/library/` + `lib/settings/`

**`lib/core/` — חלוקה לתת-תיקיות:**
- יוצר `lib/core/activation/` ← `external_activation_channel.dart`, `external_activation_queue.dart`, `external_uri_router.dart`
- יוצר `lib/core/window/` ← `window_listener.dart`, `window_persistence.dart`
- יוצר `lib/core/lifecycle/` ← `app_runtime_reset.dart`, `http_client_registry.dart`, `pre_close_registry.dart`
- יוצר `lib/core/work_status/` ← `lib/work_status/work_status_cubit.dart`, `work_status_item.dart`

**`lib/library/` — ספיגת empty + external:**
- יוצר `lib/library/empty/bloc/` ← `lib/empty_library/bloc/`
- יוצר `lib/library/external/` ← `lib/external_catalog/repository/`

**`lib/settings/` — ספיגת shortcuts logic:**
- יוצר `lib/settings/shortcuts/` ← `key_map.dart`, `shortcut_helper.dart`, `shortcut_validator.dart`

**commit:**
```
refactor: ארגון lib/core (חלוקה), library (ספיגה), settings (shortcuts)
```

---

### Commit 4: פיצול קבצים מעורבים — לוגיקה בלבד

**מה עושים** (יוצרים קבצי לוגיקה חדשים, עדיין לא מעבירים UI):

1. `lib/utils/ui/context_menu_utils.dart`
   → יוצר `lib/services/commentary_copy_service.dart` (הlוגיקה בלבד)

2. `lib/external_catalog/view/external_catalog_settings_helper.dart`
   → יוצר `lib/library/external/external_catalog_sync_service.dart`

3. `lib/library/view/library_panel_controller.dart`
   → יוצר `lib/library/services/library_panel_service.dart`

4. `lib/settings/services/safer_mode/protected_settings_wrapper.dart`
   → יוצר `lib/settings/services/safer_mode/password_verifier.dart`

5. `lib/widgets/smart_text/text_renderer_service.dart`
   → מעביר ל-`lib/services/text_renderer_service.dart`

6. `lib/main.dart`
   → יוצר `lib/core/app_initializer.dart` (הlוגיקה בלבד, main.dart נשאר ומצטמצם)

7. `lib/navigation/view/main_window_screen.dart`
   → יוצר `lib/core/main_window_coordinator.dart` (לוגיקה בלבד, קובץ המקור נשאר ומצטמצם)

**commit:**
```
refactor: פיצול קבצים מעורבים — חילוץ לוגיקה

יוצר: app_initializer, main_window_coordinator, commentary_copy_service,
library_panel_service, external_catalog_sync_service, password_verifier
מעביר: text_renderer_service → lib/services/
```

---

### Commit 5: יצירת `lib/ui/` — תשתית גלובלית

**מה עושים:**
- יוצרים מבנה `lib/ui/`
- מעבירים:
  - `lib/theme/` → `lib/ui/theme/`
  - `lib/widgets/` → `lib/ui/widgets/` (ללא `reusable_items_dialog.dart` ו-`items_list_view.dart` שיעברו בשלב 6)
  - `lib/update/` → `lib/ui/update/`
  - `lib/app.dart` → `lib/ui/app.dart`
  - `lib/core/splash_screen.dart` → `lib/ui/core/splash_screen.dart`
  - `lib/core/ui_snack.dart` → `lib/ui/core/ui_snack.dart`
  - `lib/work_status/work_status_overlay.dart` → `lib/ui/core/work_status_overlay.dart`
  - יוצרים `lib/ui/core/app_bootstrap_screen.dart` (UI part מ-main.dart)
  - יוצרים `lib/ui/widgets/misc/context_menu_builder.dart` (UI part מ-context_menu_utils)
- מעדכנים כל imports

**commit:**
```
feat: יצירת lib/ui/ — העברת תשתית UI גלובלית

theme, widgets, update, core (splash/snack/work_status/bootstrap)
עדכון ~250 imports בפרויקט
```

---

### Commit 6: העברת UI של Phase 1 features

**מה עושים:**
- יוצרים `lib/ui/library/`, `lib/ui/settings/`, `lib/ui/reader_memory/`, etc.
- מעבירים:
  - `lib/navigation/view/*.dart` (UI בלבד) → `lib/ui/screens/`
  - `lib/library/view/*.dart` (UI) → `lib/ui/library/`
  - יוצרים `lib/ui/library/library_panel_controller_ui.dart` (UI part)
  - יוצרים `lib/ui/library/external_catalog_settings_ui.dart` (UI part)
  - יוצרים `lib/ui/library/empty_library_screen.dart` ← `lib/empty_library/`
  - `lib/settings/` UI files → `lib/ui/settings/`
  - יוצרים `lib/ui/settings/protected_settings_wrapper.dart` (UI part)
  - `lib/shortcuts/keyboard_shortcuts.dart` + `view/` → `lib/ui/settings/shortcuts/`
  - `lib/bookmarks/view/`, `lib/history/view/`, `lib/workspaces/view/` → `lib/ui/reader_memory/`
  - `lib/widgets/dialogs/reusable_items_dialog.dart` → `lib/ui/reader_memory/` (feature-specific)
  - `lib/widgets/lists/items_list_view.dart` → `lib/ui/reader_memory/` (feature-specific)
  - `lib/find_ref/view/` → `lib/ui/find_ref/`
  - `lib/tour/view/` + `widgets/` → `lib/ui/tour/`
  - `lib/printing/view/` → `lib/ui/printing/`
  - `lib/file_sync/file_sync_widget.dart` → `lib/ui/file_sync/`

**commit:**
```
feat: העברת UI של Phase 1 features ל-lib/ui/

library, settings, reader_memory, find_ref, tour, printing, file_sync
```

---

### Commit 7: ניקוי — מחיקת תיקיות ריקות

מוחקים (לאחר בדיקה שהתרוקנו):
- `lib/data/`, `lib/file_sync/`, `lib/indexing/`, `lib/migration/` → עברו ל-seforim
- `lib/bookmarks/`, `lib/history/`, `lib/workspaces/` → עברו ל-reader_memory
- `lib/empty_library/`, `lib/external_catalog/` → עברו ל-library
- `lib/work_status/` → logic עבר ל-core/work_status, UI עבר ל-ui/core
- `lib/shortcuts/` → logic עבר ל-settings/shortcuts, UI עבר ל-ui/settings/shortcuts
- `lib/theme/`, `lib/widgets/`, `lib/update/` → עברו ל-ui/

```
flutter analyze && flutter test
```

**commit:**
```
chore: מחיקת תיקיות ריקות אחרי Phase 1

הסרת 12 תיקיות שהתרוקנו אחרי הארגון מחדש
```

---

## Phase 2 — בעתיד (commit per feature)

| Commit | תוכן |
|--------|------|
| 8 | `lib/text_book/view/` → `lib/ui/text_book/` |
| 9 | `lib/pdf_book/view/` → `lib/ui/pdf_book/` |
| 10 | `lib/search/view/` → `lib/ui/search/` |
| 11 | `lib/personal_notes/widgets/+view/` → `lib/ui/personal_notes/` |
| 12 | `lib/tools/` (UI) → `lib/ui/tools/` |
| 13 | `lib/tabs/reading_screen.dart` → `lib/ui/tabs/` |
| ? | `lib/plugins/view/` — החלטה עצמאית |

---

## סיכום Phase 1

| Commit | נושא | סוג שינוי | קבצים |
|--------|------|-----------|-------|
| 1 | seforim | logic refactor | ~80 + imports |
| 2 | reader_memory | logic refactor | ~15 + imports |
| 3 | core/library/settings | logic refactor | ~30 + imports |
| 4 | פיצול מעורבים | logic creation | 7 קבצים חדשים |
| 5 | lib/ui/ תשתית | UI move | ~250 imports |
| 6 | Phase 1 features | UI move | ~50 + imports |
| 7 | ניקוי | deletion | 12 תיקיות |
