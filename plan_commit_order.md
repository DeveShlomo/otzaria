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

## Phase 2 — 9 commits

> ראה פירוט מלא: `plan_phase2_ui_separation.md`

**עיקרון סדר:** לוגיקה לפני UI. ווידג'טים משותפים עוברים לפני הפיצ'רים שמשתמשים בהם.

---

### Commit 8: העברת קבצי לוגיקה מתיקיות view/widgets למיקום נכון

**מה עושים** (לא UI — רק תיקון מיקום, אושרו כלוגיקה טהורה):

1. `lib/text_book/view/page_shape/utils/commentary_sync_helper.dart`
   → `lib/text_book/utils/`
   (import יחיד: `models/links.dart`, ללא flutter)

2. `lib/text_book/view/page_shape/utils/default_commentators.dart`
   → `lib/text_book/utils/`
   (`flutter/services` לצורך rootBundle בלבד, ללא Widget)

3. `lib/text_book/view/page_shape/utils/page_shape_commentary_selection.dart`
   → `lib/text_book/utils/`
   (`dart:convert` בלבד)

4. `lib/text_book/view/page_shape/utils/page_shape_settings_manager.dart`
   → `lib/text_book/utils/`
   (`flutter_settings_screens` לצורך storage, ללא Widget)

5. `lib/tools/shamor_zachor/widgets/hebrew_utils.dart`
   → `lib/tools/shamor_zachor/utils/`
   (`kosher_dart` בלבד)

עדכון כל imports ב-`page_shape/` ו-`shamor_zachor/`.
`flutter analyze` חייב לעבור ב-0 שגיאות.

**commit:**
```
refactor: העברת קבצי לוגיקה מתיקיות view/widgets למיקום נכון

text_book/utils: commentary_sync_helper, default_commentators,
page_shape_commentary_selection, page_shape_settings_manager
tools/shamor_zachor/utils: hebrew_utils
```

---

### Commit 9: יצירת `lib/reading/` — קיבוץ לוגיקת הקריאה

**מה עושים:**
יוצרים `lib/reading/` ומעבירים לתוכה **לוגיקה בלבד** (ללא view/widgets) מ-5 תיקיות:

| מקור | יעד | קבצים |
|------|-----|-------|
| `lib/text_book/` (ללא view/, widgets/, editing/widgets/) | `lib/reading/text_book/` | 27 |
| `lib/pdf_book/` (ללא view/) | `lib/reading/pdf_book/` | 4 |
| `lib/search/` (ללא view/) | `lib/reading/search/` | 15 |
| `lib/personal_notes/` (ללא view/, widgets/) | `lib/reading/personal_notes/` | 12 |
| `lib/tabs/` (ללא reading_screen.dart) | `lib/reading/tabs/` | 9 |

**עדכון imports — ~189 קבצים:**
- **חיצוניים:** `main_window_screen`, `main.dart`, `navigation_bloc`, `plugins/*`, `reader_memory/*`, `utils/navigation/`
- **פנימיים:** כל imports צולבים בין 5 התיקיות (tabs↔text_book, tabs↔search, text_book←search, text_book←personal_notes, pdf_book←search)

**שים לב:** קבצי view/ ו-widgets/ **נשארים** במיקומם הישן — יעברו ל-`lib/ui/reading/` בcommits הבאים.
`flutter analyze` חייב לעבור ב-0 שגיאות.

**commit:**
```
refactor: יצירת lib/reading/ — קיבוץ לוגיקת text_book, pdf_book, search, personal_notes, tabs

~67 קבצים, עדכון ~189 imports
```

---

### Commit 10: העברת ווידג'טים ייעודיים לקריאה → `lib/ui/reading/widgets/`

**מה עושים:**
יוצרים `lib/ui/reading/widgets/` ומעבירים לתוכה 6 קבצים שמיובאים **אך ורק** על-ידי Phase 2:

| מקור | יעד |
|------|-----|
| `lib/ui/widgets/layout/dual_adaptive_reader_pane.dart` | `lib/ui/reading/widgets/` |
| `lib/ui/widgets/layout/reader_side_panel_shell.dart` | `lib/ui/reading/widgets/` |
| `lib/ui/widgets/lists/commentators_selection_panel.dart` | `lib/ui/reading/widgets/` |
| `lib/ui/widgets/layout/commentators_filter_screen.dart` | `lib/ui/reading/widgets/` |
| `lib/ui/widgets/misc/progressive_scrolling.dart` | `lib/ui/reading/widgets/` |
| `lib/ui/widgets/navigation/book_view_actions.dart` | `lib/ui/reading/widgets/` |

**לבדוק:** `commentators_filter_button.dart` — אם גם הוא Phase 2-only, להוסיף לרשימה.

עדכון כל imports ב-Phase 2 folders מ-`otzaria/ui/widgets/...` ל-`otzaria/ui/reading/widgets/...`.
(קבצי Phase 2 עדיין נמצאים במיקומם הישן, רק ה-imports מתעדכנים.)

**commit:**
```
refactor: העברת ווידג'טים ייעודיים לקריאה ל-lib/ui/reading/widgets/

dual_adaptive_reader_pane, reader_side_panel_shell,
commentators_selection_panel, commentators_filter_screen,
progressive_scrolling, book_view_actions
```

---

### Commit 11: יצירת `lib/ui/reading/` + העברת text_book UI

**מה עושים:**
יוצרים את המבנה הבא:
- `lib/ui/reading/text_book/` + תת-תיקיות: `combined_view/`, `page_shape/`, `selection/`, `splited_view/`, `strategies/`, `editing/`

מעבירים:
- `lib/text_book/view/*.dart` (13 קבצים) → `lib/ui/reading/text_book/`
- `lib/text_book/view/widgets/continuous_reading_paragraph.dart` → `lib/ui/reading/text_book/`  
  (תיקיית `widgets/` עם קובץ אחד — נספגת ל-root)
- `lib/text_book/widgets/text_book_state_builder.dart` → `lib/ui/reading/text_book/`
- `lib/text_book/view/combined_view/*.dart` (3) → `.../combined_view/`
- `lib/text_book/view/page_shape/*.dart` (4, ללא utils/) → `.../page_shape/`
- `lib/text_book/view/selection/*.dart` (6) → `.../selection/`
- `lib/text_book/view/splited_view/*.dart` (2) → `.../splited_view/`
- `lib/text_book/view/strategies/*.dart` (5) → `.../strategies/`
- `lib/text_book/editing/widgets/*.dart` (2) → `.../editing/`

עדכון ~40 imports.

**commit:**
```
feat: יצירת lib/ui/reading/ — העברת text_book UI

37 קבצי UI, עדכון ~40 imports
```

---

### Commit 12: העברת pdf_book UI → `lib/ui/reading/pdf_book/`

**מה עושים:**
- יוצרים `lib/ui/reading/pdf_book/`
- מעבירים `lib/pdf_book/view/*.dart` (9 קבצים)
- עדכון ~10 imports

**commit:**
```
feat: העברת pdf_book UI ל-lib/ui/reading/pdf_book/
```

---

### Commit 13: העברת search UI עם פיצול dialog/results

**מה עושים:**
יוצרים `lib/ui/reading/search/` עם תת-תיקיות:

**`search/` (root — משותף):**
- `enhanced_search_field.dart` ← משמש גם דיאלוג וגם תוצאות

**`search/dialog/` (קינפוג החיפוש):**
- `search_dialog.dart`, `advanced_search_controls.dart`,
  `category_tree_selector.dart`, `full_text_settings_widgets.dart`, `search_options_dropdown.dart`

**`search/results/` (כרטיסיית התוצאות):**
- `full_text_search_screen.dart`, `tantivy_full_text_search.dart`,
  `tantivy_search_results.dart`, `search_edit_panel.dart`, `full_text_facet_filtering.dart`

עדכון ~10 imports (שימו לב: imports חייבים להצביע ל-dialog/ או results/ לפי המיקום החדש).

**commit:**
```
feat: העברת search UI ל-lib/ui/reading/search/ עם פיצול dialog/results

11 קבצי UI בשתי תת-תיקיות, עדכון ~10 imports
```

---

### Commit 14: העברת personal_notes UI + reading_screen

**מה עושים:**
- יוצרים `lib/ui/reading/personal_notes/`
- מעבירים:
  - `lib/personal_notes/view/personal_notes_screen.dart` → `.../personal_notes/`
  - `lib/personal_notes/widgets/*.dart` (9 קבצים) → `.../personal_notes/`
  - `lib/tabs/reading_screen.dart` → `lib/ui/reading/reading_screen.dart`
    (StatefulWidget עם BlocListener — **לא מפצלים**, דפוס Flutter סטנדרטי)
- עדכון ~10 imports

**commit:**
```
feat: העברת personal_notes UI + reading_screen ל-lib/ui/reading/

personal_notes (10 קבצים), reading_screen
```

---

### Commit 15: העברת tools UI → `lib/ui/tools/`

**מה עושים:**
יוצרים `lib/ui/tools/` עם תת-תיקיות לכל כלי.
מעבירים (30 קבצי UI + context_menu_entries שהוא MIXED):

- `lib/tools/tools_screen.dart` → `lib/ui/tools/`
- `lib/tools/acronyms_dictionary/` (UI) → `lib/ui/tools/acronyms_dictionary/`
- `lib/tools/aramaic_dictionary/` (UI) → `lib/ui/tools/aramaic_dictionary/`
- `lib/tools/calendar/` (UI: screen + dialogs/ + widgets/) → `lib/ui/tools/calendar/`
- `lib/tools/dictionary/context_menu_entries.dart` → `lib/ui/tools/dictionary/`
  (מיובא על-ידי text_book — עדכן imports גם בtext_book לנתיב החדש)
- `lib/tools/dictionary/widgets/` → `lib/ui/tools/dictionary/widgets/`
- `lib/tools/gematria/` (UI) → `lib/ui/tools/gematria/`
- `lib/tools/measurement_converter/` (UI) → `lib/ui/tools/measurement_converter/`
- `lib/tools/shamor_zachor/` (UI: widget, screens/, widgets/) → `lib/ui/tools/shamor_zachor/`

עדכון ~30 imports.

**commit:**
```
feat: העברת tools UI ל-lib/ui/tools/

30 קבצי UI, עדכון ~30 imports
```

---

### Commit 16: ניקוי Phase 2 — מחיקת תיקיות ריקות

מוחקים (לאחר בדיקה שהתרוקנו):
- `lib/text_book/view/` (כולל כל תת-תיקיותיה)
- `lib/text_book/widgets/`
- `lib/text_book/editing/widgets/`
- `lib/pdf_book/view/`
- `lib/search/view/`
- `lib/personal_notes/view/`
- `lib/personal_notes/widgets/`

```
flutter analyze && flutter test
```

**commit:**
```
chore: מחיקת תיקיות UI ריקות אחרי Phase 2

הסרת view/ + widgets/ מ-text_book, pdf_book, search, personal_notes
```

---

## Phase 3 — plugins (החלטה עצמאית בעתיד)

`lib/plugins/` — מערכת עצמאית ומבוצרת. לא נוגעים עד החלטה נפרדת.

---

## סיכום Phase 1 ✅ (הושלם)

| Commit | נושא | סוג שינוי | קבצים |
|--------|------|-----------|-------|
| 1 | seforim | logic refactor | ~80 + imports |
| 2 | reader_memory | logic refactor | ~15 + imports |
| 3 | core/library/settings | logic refactor | ~30 + imports |
| 4 | פיצול מעורבים | logic creation | 7 קבצים חדשים |
| 5 | lib/ui/ תשתית | UI move | ~250 imports |
| 6 | Phase 1 features | UI move | ~50 + imports |
| 7 | ניקוי | deletion | 12 תיקיות |

---

## סיכום Phase 2

| Commit | נושא | סוג שינוי | קבצים |
|--------|------|-----------|-------|
| 8 | לוגיקה במיקום שגוי | העברה בלבד | 5 + imports |
| **9** | **lib/reading/ — לוגיקת קריאה** | **logic move** | **~67 + ~189 imports** |
| 10 | reading widgets | העברה מ-ui/widgets/ | 6 + imports |
| 11 | text_book UI | UI move | ~37 + imports |
| 12 | pdf_book UI | UI move | 9 + imports |
| 13 | search UI (dialog/results) | UI move + פיצול | 11 + imports |
| 14 | personal_notes + reading_screen | UI move | 11 + imports |
| 15 | tools UI | UI move | ~30 + imports |
| 16 | ניקוי Phase 2 | deletion | 7+ תיקיות |
