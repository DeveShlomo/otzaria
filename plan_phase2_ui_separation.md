# תוכנית Phase 2 — הפרדת UI/UX מלוגיקה

> **מטרה:** המשך Phase 1 — העברת כל קוד תצוגה מתיקיות Phase 2 ל-`lib/ui/`,
> תוך שמירה על **עומק ניווט זהה** ו-0 שגיאות analyze אחרי כל commit.
>
> Phase 1 הושלם ב-7 commits (ראה `plan_commit_order.md`).
> Phase 2 עוסק ב-6 תיקיות שנדחו: `text_book`, `pdf_book`, `search`, `personal_notes`, `tools`, `tabs`.

---

## תיקיית `lib/reading/` — לוגיקת הקריאה (Commit 9)

מקבילה ל-`lib/ui/reading/`. מכילה **לוגיקה בלבד** — ללא קבצי view/widgets.
דפוס זה עקבי עם Phase 1: `lib/reader_memory/` מקביל ל-`lib/ui/reader_memory/`.

```
lib/reading/                    ← NEW (Commit 9)
├── text_book/                  ← lib/text_book/ (bloc, models, utils, editing logic — 27 קבצים)
├── pdf_book/                   ← lib/pdf_book/ (bloc, utils — 4 קבצים)
├── search/                     ← lib/search/ (bloc, models, utils, repository, book_facet — 15 קבצים)
├── personal_notes/             ← lib/personal_notes/ (bloc, models, repository, services, storage, utils — 12 קבצים)
└── tabs/                       ← lib/tabs/ (bloc, models, tabs_repository — 9 קבצים)
```

`lib/tools/` נשאר כמו שהוא — כלים (calendar, gematria, מילונים) אינם "קריאה".

**תלויות צולבות (נשמרות, רק הנתיב משתנה):**
```
reading/tabs/       ←→ reading/text_book/   (הכי הדוק — text_tab, tabs_bloc)
reading/tabs/       ←→ reading/search/      (searching_tab, search_configuration)
reading/text_book/  ←   reading/search/     (search_configuration)
reading/text_book/  ←   reading/personal_notes/ (personal_notes_system)
reading/pdf_book/   ←   reading/search/, reading/tabs/
```

**היקף imports שיתעדכנו (~189 קבצים):**
- `lib/ui/screens/main_window_screen.dart` — מייבא מכל 5 תיקיות
- `lib/main.dart` — tabs, personal_notes
- `lib/navigation/bloc/navigation_bloc.dart` — tabs
- `lib/plugins/bridge/plugin_bridge_adapter.dart` — text_book, search, tabs, personal_notes
- `lib/reader_memory/` — tabs, search
- `lib/utils/navigation/` — text_book, tabs

---

## עיקרון מרכזי: תיקיית `reading/`

רוב פיצ'רי Phase 2 הם **חלק ממסך הקריאה** — לא כלים עצמאיים.
תיקיות אלה יקובצו תחת `lib/ui/reading/`:

```
lib/ui/
├── reading/       ← NEW: text_book + pdf_book + search + personal_notes + tabs + widgets ייעודיים
└── tools/         ← עצמאי — אינו שייך לקריאה
```

---

## ניתוח קבצים מעורבים — ממצאים מאומתים

### קבצים שנראו מעורבים אך הם **לוגיקה טהורה** (אינם דורשים פיצול)

בדיקה של imports אימתה שכל 5 הקבצים הבאים **אינם מייבאים flutter/material ולא Widget** — הם נמצאים בתיקיות view/widgets בטעות בלבד:

| קובץ נוכחי | יעד נכון | סיבה |
|-----------|---------|------|
| `lib/text_book/view/page_shape/utils/commentary_sync_helper.dart` | `lib/text_book/utils/` | לוגיקת חיפוש קישורים, import יחיד: `models/links.dart` |
| `lib/text_book/view/page_shape/utils/default_commentators.dart` | `lib/text_book/utils/` | טעינת JSON + מודלים, `flutter/services` לצורך rootBundle בלבד |
| `lib/text_book/view/page_shape/utils/page_shape_commentary_selection.dart` | `lib/text_book/utils/` | קבועים ו-parsing בלבד, `dart:convert` בלבד |
| `lib/text_book/view/page_shape/utils/page_shape_settings_manager.dart` | `lib/text_book/utils/` | שמירת העדפות דרך `flutter_settings_screens` — storage, לא UI |
| `lib/tools/shamor_zachor/widgets/hebrew_utils.dart` | `lib/tools/shamor_zachor/utils/` | המרות gematria וtarim, `kosher_dart` בלבד |

**פעולה:** העברה ישירה, עדכון imports בקבצי page_shape/ ו-shamor_zachor/.

---

### קובץ מעורב שכן דורש טיפול: `context_menu_entries.dart`

| קובץ | imports | מה הוא עושה | יעד |
|------|---------|------------|-----|
| `lib/tools/dictionary/context_menu_entries.dart` | `flutter/material`, `fluentui_system_icons`, `flutter_bloc`, `ui/widgets/...` | בונה רשימת `AppContextMenuEntry` — מבנה UI | `lib/ui/tools/dictionary/context_menu_entries.dart` |

מיובא על-ידי: `text_book/view/combined_view/combined_book_screen.dart` ו-`page_shape/simple_text_viewer.dart`.

---

### `reading_screen.dart` — מעורב באופן תקין (אין פיצול)

`lib/tabs/reading_screen.dart` הוא StatefulWidget עם BlocListener שמפעיל `SaveTabs`, `CaptureStateForHistory` וכו'.
זהו **דפוס Flutter BLoC סטנדרטי** — ה-Widget מגיב למצבים ומשגר אירועים. הלוגיקה העסקית נמצאת ב-BLoC.
**פעולה:** העברה ישירה ל-`lib/ui/reading/reading_screen.dart` ללא פיצול.

---

## ווידג'טים מ-`lib/ui/widgets/` שיעברו ל-`lib/ui/reading/widgets/`

6 קבצים ב-`lib/ui/widgets/` מיובאים **אך ורק** על-ידי תיקיות Phase 2.
הם יועברו ל-`lib/ui/reading/widgets/` בcommit ייעודי **לפני** העברת קבצי ה-UI של הפיצ'רים.

| קובץ נוכחי | מיובא על-ידי |
|-----------|------------|
| `lib/ui/widgets/layout/dual_adaptive_reader_pane.dart` | `pdf_book/view/pdf_book_screen` בלבד |
| `lib/ui/widgets/layout/reader_side_panel_shell.dart` | `dual_adaptive_reader_pane` בלבד |
| `lib/ui/widgets/lists/commentators_selection_panel.dart` | `text_book/view/`, `pdf_book/view/` |
| `lib/ui/widgets/layout/commentators_filter_screen.dart` | `text_book/view/`, `pdf_book/view/` |
| `lib/ui/widgets/misc/progressive_scrolling.dart` | `text_book/view/` (4 קבצים) |
| `lib/ui/widgets/navigation/book_view_actions.dart` | `text_book/view/`, `pdf_book/view/` |

> **לבדיקה לפני commit:** `lib/ui/widgets/misc/commentators_filter_button.dart` (2 שימושים בPhase 2) — לאמת שאינו מיובא מ-Phase 1 ולהוסיף לרשימה אם כן.

**לאחר ההעברה:** יש לעדכן את כל imports ב-Phase 2 folders מ-`ui/widgets/...` ל-`ui/reading/widgets/...`.

---

## פיצול `search/` — דיאלוג מול תוצאות

מסקנה: ה-search view כולל **שתי תפקידות שונות מהותית** ולכן יחולק ל-2 תת-תיקיות:

| קובץ | תפקיד | תת-תיקייה |
|------|--------|----------|
| `search_dialog.dart` (963 שורות) | מודל popup לקינפוג חיפוש | `dialog/` |
| `advanced_search_controls.dart` | בקרות חיפוש מתקדם — בתוך הדיאלוג | `dialog/` |
| `category_tree_selector.dart` | בחירת קטגוריה — בתוך הדיאלוג | `dialog/` |
| `full_text_settings_widgets.dart` | הגדרות חיפוש — בתוך הדיאלוג | `dialog/` |
| `search_options_dropdown.dart` | dropdown אפשרויות — בתוך הדיאלוג | `dialog/` |
| `full_text_search_screen.dart` (18 שורות) | wrapper לכרטיסיית תוצאות | `results/` |
| `tantivy_full_text_search.dart` | רכיב חיפוש מלא בתוך הכרטיסייה | `results/` |
| `tantivy_search_results.dart` (515 שורות) | רשימת תוצאות + pagination | `results/` |
| `search_edit_panel.dart` | עריכת חיפוש פעיל בתוך הכרטיסייה | `results/` |
| `full_text_facet_filtering.dart` | סינון facets בתוצאות | `results/` |
| `enhanced_search_field.dart` | שדה קלט — **משותף** לדיאלוג ולתוצאות | `search/` (root) |

---

## ווידג'ט לאיחוד: `continuous_reading_paragraph.dart`

`lib/text_book/view/widgets/continuous_reading_paragraph.dart` — תיקיית `widgets/` עם קובץ אחד בלבד.
מיובא על-ידי: `combined_book_screen.dart` ו-`simple_text_viewer.dart` (2 תיקיות שונות — לא רק page_shape).
**פעולה:** מועבר ל-`lib/ui/reading/text_book/continuous_reading_paragraph.dart` (root text_book, לא תת-תיקייה).

---

## מבנה `lib/ui/reading/` — מלא

```
lib/ui/reading/
│
├── reading_screen.dart                        ← lib/tabs/reading_screen.dart
│
├── widgets/                                   ← NEW: ווידג'טים ייעודיים לקריאה
│   ├── dual_adaptive_reader_pane.dart         ← lib/ui/widgets/layout/
│   ├── reader_side_panel_shell.dart           ← lib/ui/widgets/layout/
│   ├── commentators_selection_panel.dart      ← lib/ui/widgets/lists/
│   ├── commentators_filter_screen.dart        ← lib/ui/widgets/layout/
│   ├── progressive_scrolling.dart             ← lib/ui/widgets/misc/
│   └── book_view_actions.dart                 ← lib/ui/widgets/navigation/
│
├── text_book/
│   ├── continuous_reading_paragraph.dart      ← lib/text_book/view/widgets/ (single file)
│   ├── text_book_screen.dart                  ← lib/text_book/view/
│   ├── text_book_scaffold.dart
│   ├── text_book_search_screen.dart
│   ├── alt_toc_sidebar_view.dart
│   ├── book_source_dialog.dart
│   ├── commentary_list_base.dart
│   ├── commentators_list_screen.dart
│   ├── error_report_dialog.dart
│   ├── selected_line_links_view.dart
│   ├── tabbed_commentary_panel.dart
│   ├── toc_filter.dart
│   ├── toc_navigator_internals.dart
│   ├── toc_navigator_screen.dart
│   ├── text_book_state_builder.dart           ← lib/text_book/widgets/
│   │
│   ├── combined_view/
│   │   ├── combined_book_screen.dart
│   │   ├── commentary_content.dart
│   │   └── commentary_list_for_combined_view.dart
│   │
│   ├── page_shape/
│   │   ├── links_notes_sidebar.dart
│   │   ├── page_shape_screen.dart
│   │   ├── page_shape_settings_dialog.dart
│   │   └── simple_text_viewer.dart
│   │    (utils/ הוסרה — כל הקבצים עברו ל-lib/text_book/utils/ ב-Commit 8)
│   │
│   ├── selection/
│   │   ├── enhanced_gesture_detector.dart
│   │   ├── selected_text_copy.dart
│   │   ├── selected_text_restore.dart
│   │   ├── selection_persistence.dart
│   │   ├── selection_sync_controller.dart
│   │   └── text_selection_manager.dart
│   │
│   ├── splited_view/
│   │   ├── commentary_list_for_splited_view.dart
│   │   └── splited_view_screen.dart
│   │
│   ├── strategies/
│   │   ├── combined_view_strategy.dart
│   │   ├── page_shape_strategy.dart
│   │   ├── split_view_strategy.dart
│   │   ├── strategies.dart
│   │   └── text_book_view_strategy.dart
│   │
│   └── editing/
│       ├── markdown_toolbar.dart              ← lib/text_book/editing/widgets/
│       └── text_section_editor_dialog.dart
│
├── pdf_book/
│   ├── pdf_book_screen.dart                   ← lib/pdf_book/view/
│   ├── pdf_commentary_content.dart
│   ├── pdf_commentary_panel.dart
│   ├── pdf_outlines_screen.dart
│   ├── pdf_page_number_display.dart
│   ├── pdf_scrollbar.dart
│   ├── pdf_search_screen.dart
│   ├── pdf_thumbnails_screen.dart
│   └── pdf_zoom_bar.dart
│
├── search/
│   ├── enhanced_search_field.dart             ← lib/search/view/ (משותף!)
│   │
│   ├── dialog/                                ← חיפוש: קינפוג ופתיחה
│   │   ├── search_dialog.dart
│   │   ├── advanced_search_controls.dart
│   │   ├── category_tree_selector.dart
│   │   ├── full_text_settings_widgets.dart
│   │   └── search_options_dropdown.dart
│   │
│   └── results/                               ← חיפוש: כרטיסיית תוצאות
│       ├── full_text_search_screen.dart
│       ├── tantivy_full_text_search.dart
│       ├── tantivy_search_results.dart
│       ├── search_edit_panel.dart
│       └── full_text_facet_filtering.dart
│
└── personal_notes/
    ├── personal_notes_screen.dart             ← lib/personal_notes/view/
    ├── inline_note_editor.dart                ← lib/personal_notes/widgets/
    ├── note_tile.dart
    ├── notes_search_header.dart
    ├── personal_note_content_view.dart
    ├── personal_note_editor_dialog.dart
    ├── personal_note_editor.dart
    ├── personal_note_link_dialog.dart
    ├── personal_notes_export_dialog.dart
    └── personal_notes_sidebar.dart
```

---

## מבנה `lib/ui/tools/` — מלא

```
lib/ui/tools/
│
├── tools_screen.dart                          ← lib/tools/tools_screen.dart
│
├── acronyms_dictionary/
│   ├── acronyms_dictionary_screen.dart
│   └── widgets/
│       └── acronym_result_card.dart
│
├── aramaic_dictionary/
│   ├── aramaic_dictionary_screen.dart
│   └── widgets/
│       └── aramaic_result_card.dart
│
├── calendar/
│   ├── calendar_screen.dart
│   ├── dialogs/
│   │   ├── calendar_event_dialog.dart
│   │   ├── calendar_print_dialog.dart
│   │   ├── calendar_zman_alert_dialog.dart
│   │   └── jump_to_date_dialog.dart
│   └── widgets/
│       ├── calendar_day_cell.dart
│       ├── calendar_events_panel.dart
│       ├── calendar_main_panel.dart
│       ├── calendar_settings_panel.dart
│       ├── calendar_side_panel.dart
│       ├── calendar_times_panel.dart
│       └── calendar_top_bar.dart
│
├── dictionary/
│   ├── context_menu_entries.dart              ← lib/tools/dictionary/ (MIXED → UI)
│   └── widgets/
│       └── aramaic_dictionary_entry_view.dart
│
├── gematria/
│   ├── gematria_search_screen.dart
│   └── widgets/
│       └── gematria_result_card.dart
│
├── measurement_converter/
│   └── measurement_converter_screen.dart
│
└── shamor_zachor/
    ├── shamor_zachor_widget.dart
    ├── screens/
    │   ├── book_detail_screen.dart
    │   └── shamor_zachor_main_screen.dart
    └── widgets/
        ├── book_card_widget.dart
        ├── category_books_grid.dart
        ├── completion_animation_overlay.dart
        ├── error_boundary.dart
        └── shamor_zachor_sidebar.dart
        (hebrew_utils.dart הוסר — עבר ל-lib/tools/shamor_zachor/utils/)
```

---

## עדכוני ייבוא — היקף Phase 2

| נתיב ישן | נתיב חדש | מושפעים |
|----------|---------|---------|
| `package:otzaria/ui/widgets/layout/dual_adaptive_reader_pane` | `ui/reading/widgets/...` | pdf_book |
| `package:otzaria/ui/widgets/layout/reader_side_panel_shell` | `ui/reading/widgets/...` | reading/widgets/ (internal) |
| `package:otzaria/ui/widgets/lists/commentators_selection_panel` | `ui/reading/widgets/...` | text_book, pdf_book |
| `package:otzaria/ui/widgets/layout/commentators_filter_screen` | `ui/reading/widgets/...` | text_book, pdf_book |
| `package:otzaria/ui/widgets/misc/progressive_scrolling` | `ui/reading/widgets/...` | text_book (×4) |
| `package:otzaria/ui/widgets/navigation/book_view_actions` | `ui/reading/widgets/...` | text_book, pdf_book |
| `package:otzaria/text_book/view/...` | `ui/reading/text_book/...` | ~40 קבצים |
| `package:otzaria/text_book/widgets/...` | `ui/reading/text_book/...` | ~5 קבצים |
| `package:otzaria/text_book/editing/widgets/...` | `ui/reading/text_book/editing/...` | ~5 קבצים |
| `package:otzaria/pdf_book/view/...` | `ui/reading/pdf_book/...` | ~10 קבצים |
| `package:otzaria/search/view/...` | `ui/reading/search/...` (כולל dialog/ ו-results/) | ~10 קבצים |
| `package:otzaria/personal_notes/view/...` | `ui/reading/personal_notes/...` | ~5 קבצים |
| `package:otzaria/personal_notes/widgets/...` | `ui/reading/personal_notes/...` | ~5 קבצים |
| `package:otzaria/tools/...` (UI) | `ui/tools/...` | ~30 קבצים |
| `package:otzaria/tools/dictionary/context_menu_entries` | `ui/tools/dictionary/context_menu_entries` | text_book (×2) |
| `package:otzaria/tabs/reading_screen` | `ui/reading/reading_screen` | ~5 קבצים |
| `package:otzaria/text_book/view/page_shape/utils/...` | `text_book/utils/...` | ~5 קבצים |

---

## מה **לא** נוגעים ב-Phase 2

| תיקייה | נשאר ב |
|--------|--------|
| `lib/text_book/bloc/`, `models/`, `utils/`, `editing/` (logic) | `lib/text_book/` |
| `lib/pdf_book/bloc/`, `utils/` | `lib/pdf_book/` |
| `lib/search/bloc/`, `models/`, `utils/` | `lib/search/` |
| `lib/personal_notes/bloc/`, `models/`, `repository/`, `services/` | `lib/personal_notes/` |
| `lib/tools/calendar/helpers/`, `models/`, `services/`, `utils/` | `lib/tools/` |
| `lib/tools/shamor_zachor/` (logic) | `lib/tools/shamor_zachor/` |
| `lib/tabs/` (bloc, models, repository) | `lib/tabs/` |
| `lib/plugins/` | עצמאי — החלטה עצמאית בעתיד |
