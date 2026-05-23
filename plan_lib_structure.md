# מבנה `lib/` — תיקיות הלוגיקה

> קובץ זה מתאר את כל תיקיות `lib/` **פרט ל-`lib/ui/`** (שמתועדת ב-`plan_ui_separation.md`).
>
> מצב מוצג: **אחרי Phase 1** (הושלם), **לפני Phase 2**.
> לאחר Phase 2 יווצרו `lib/reading/` ותיקיות Phase 2 יתרוקנו מ-view/widgets שלהן.

---

## תרשים כללי

```
lib/
│
├── main.dart                    ← entry point (מאותחל ע"י core/app_initializer)
├── app_bloc_observer.dart       ← ניטור BLoC גלובלי
│
├── [תשתית]
│   ├── core/                    ← תשתית אפליקציה (חלון, lifecycle, activation)
│   ├── seforim/                 ← תשתית נתוני ספרים (data, sync, indexing, migration)
│   ├── models/                  ← מודלים משותפים גלובליים
│   ├── services/                ← שירותים משותפים
│   └── utils/                   ← כלי עזר כלליים
│
├── [ניווט והגדרות]
│   ├── navigation/              ← ניווט כללי (BLoC)
│   └── settings/                ← הגדרות אפליקציה + קיצורי דרך
│
├── [פיצ'רים — Phase 1, מאורגנים]
│   ├── library/                 ← ספריית הספרים (browser + external + empty)
│   ├── reader_memory/           ← זיכרון קריאה (bookmarks + history + workspaces)
│   ├── find_ref/                ← חיפוש לפי מקור
│   ├── tour/                    ← מדריך למשתמש חדש
│   └── printing/                ← הדפסה וייצוא
│
├── [פיצ'רים — Phase 2, עוברים ל-reading/]
│   ├── text_book/               ← צופה טקסט (לוגיקה + UI — UI עובר ל-ui/reading/)
│   ├── pdf_book/                ← צופה PDF (לוגיקה + UI — UI עובר ל-ui/reading/)
│   ├── search/                  ← מנוע חיפוש (לוגיקה + UI — UI עובר ל-ui/reading/)
│   ├── personal_notes/          ← הערות אישיות (לוגיקה + UI — UI עובר ל-ui/reading/)
│   ├── tabs/                    ← ניהול כרטיסיות (לוגיקה + reading_screen — UI עובר ל-ui/reading/)
│   └── tools/                   ← כלים (לוגיקה נשארת, UI עובר ל-ui/tools/)
│
├── [יווצר ב-Phase 2]
│   └── reading/                 ← NEW: לוגיקת כל פיצ'רי הקריאה
│
└── plugins/                     ← מערכת פלאגינים עצמאית
```

---

## טבלה מפורטת — כל תיקייה

### קבצי שורש

| קובץ | תיאור | Phase 2 |
|------|--------|---------|
| `main.dart` | Entry point — מאותחל `AppInitializer`, מגדיר provider tree | נשאר, מצטמצם |
| `app_bloc_observer.dart` | מאזין גלובלי לאירועי BLoC (logging) | נשאר |

---

### תשתית (`core`, `seforim`, `models`, `services`, `utils`)

| תיקייה | קבצים | תיאור | תת-תיקיות | Phase 2 |
|--------|-------|--------|-----------|---------|
| `core/` | 13 | תשתית חיי האפליקציה | `activation/` (deep links), `window/` (ניהול חלון), `lifecycle/` (pre-close, reset), `work_status/` (cubit + model) | נשאר |
| `seforim/` | 71 | תשתית נתוני הספרים | `providers/` (DB, filesystem, hive, tantivy), `repository/` (base, data, hive list), `cache/` (books, acronyms), `constants/`, `sync/` (file_sync), `indexing/`, `migration/` | נשאר |
| `models/` | 6 | מודלים משותפים גלובליים | — | נשאר |
| `services/` | 8 | שירותים משותפים | — | נשאר |
| `utils/` | 25 | כלי עזר כלליים | `file/`, `navigation/`, `text/`, `ui/`* | נשאר |

> **⚠️ `lib/utils/ui/`** — מכיל `fullscreen_helper.dart` ו-`reading_left_pane_policy.dart`.
> אלו עזרי UI שנמצאים בתיקייה לא נכונה — מועמדים למעבר ל-`lib/ui/widgets/` בעתיד (Phase 3).

**`lib/models/` — פירוט:**
```
models/
├── books.dart           ← מודל ספר: title, path, category, metadata
├── links.dart           ← קישורים בין ספרים (commentary links)
├── link_types.dart      ← סוגי קישורים
├── pdf_headings.dart    ← כותרות PDF
├── phone_report_data.dart ← דיווח שגיאות
└── direct_error_report.dart
```

**`lib/services/` — פירוט:**
```
services/
├── commentary_copy_service.dart  ← העתקת טקסט עם מפרשים (נוצר ב-Phase 1)
├── text_renderer_service.dart    ← רנדור טקסט (הועבר מ-widgets/ ב-Phase 1)
├── commentary_service.dart
├── book_details_service.dart
├── ad_popup_service.dart
├── data_collection_service.dart
├── direct_error_report_service.dart
└── phone_report_service.dart
```

---

### ניווט והגדרות

| תיקייה | קבצים | תיאור | תת-תיקיות | Phase 2 |
|--------|-------|--------|-----------|---------|
| `navigation/` | 5 | ניווט כללי בין מסכי האפליקציה | `bloc/` (navigation_bloc, event, state), `navigation_repository.dart`, `startup_indexing_decision.dart` | נשאר |
| `settings/` | 23 | הגדרות האפליקציה וקיצורי דרך | `engine/` (BLoC, repository), `services/` (backup, nikud, per_book, safer_mode/, custom_folders/), `shortcuts/` (key_map, helper, validator), `search/` (logic) | נשאר |

---

### פיצ'רים — Phase 1, מאורגנים ✅

| תיקייה | קבצים | תיאור | תת-תיקיות | Phase 2 |
|--------|-------|--------|-----------|---------|
| `library/` | 9 | ספריית הספרים | `bloc/`, `models/`, `services/` (library_panel + book_preview), `empty/bloc/`, `external/` (catalog) | נשאר |
| `reader_memory/` | 13 | זיכרון קריאה | `bookmarks/` (bloc, models, repository), `history/` (bloc, repository), `workspaces/` (bloc, workspace, repository) | נשאר |
| `find_ref/` | 6 | חיפוש הפניות מקוריות | `bloc/`, `repository/` | נשאר |
| `tour/` | 6 | מדריך למשתמש | `bloc/`, `models/`, `tour_target_keys.dart` | נשאר |
| `printing/` | 4 | הדפסה וייצוא | — | נשאר |

---

### פיצ'רים — Phase 2, עוברים שינוי

#### מצב נוכחי — לפני Phase 2

| תיקייה | קבצים סה"כ | לוגיקה | UI (view/widgets) | Phase 2: לוגיקה | Phase 2: UI |
|--------|-----------|--------|------------------|----------------|------------|
| `text_book/` | 68 | 27 | 37 | → `reading/text_book/` | → `ui/reading/text_book/` |
| `pdf_book/` | 13 | 4 | 9 | → `reading/pdf_book/` | → `ui/reading/pdf_book/` |
| `search/` | 26 | 15 | 11 | → `reading/search/` | → `ui/reading/search/` |
| `personal_notes/` | 22 | 12 | 10 | → `reading/personal_notes/` | → `ui/reading/personal_notes/` |
| `tabs/` | 10 | 9 | 1 | → `reading/tabs/` | → `ui/reading/` |
| `tools/` | 60 | 31 | 29 | נשאר ב-`tools/` | → `ui/tools/` |

#### מצב אחרי Phase 2 — מה נשאר בכל תיקייה

**`text_book/`** (27 קבצי לוגיקה → יעברו ל-`reading/text_book/`):
```
reading/text_book/
├── bloc/          ← text_book_bloc, event, state
├── models/        ← commentator_group, search_results, text_book_searcher
├── utils/         ← commentator_group_builder, he_categories_enricher, link_processing,
│                     reading_segments, reading_segment_navigation, search_query_sync,
│                     section_search_utils, visible_index
│                  + 4 קבצים מ-view/page_shape/utils/ (לוגיקה שהייתה שגויה שם)
├── editing/
│   ├── helpers/   ← editor_settings_helper
│   ├── models/    ← editor_settings, editor_state, section_identifier, text_draft, text_override
│   ├── repository/ ← local_overrides_repository, overrides_repository
│   └── services/  ← editor_cache_service, markdown_processor, overrides_rebase_service, preview_renderer
└── text_book_repository.dart
```

**`pdf_book/`** (4 קבצים → יעברו ל-`reading/pdf_book/`):
```
reading/pdf_book/
├── bloc/          ← pdf_book_bloc, event, state
└── utils/         ← pdf_spread_layout
```

**`search/`** (15 קבצים → יעברו ל-`reading/search/`):
```
reading/search/
├── bloc/          ← search_bloc, event, state
├── models/        ← search_configuration, search_terms_model
├── utils/         ← facet_helper, find_match_utils, hebrew_morphology,
│                     regex_patterns, search_catalogue_order_helper, snippet_builder
├── book_facet.dart
├── search_query_builder.dart
├── search_repository.dart
└── search_scope_preferences.dart
```

**`personal_notes/`** (12 קבצים → יעברו ל-`reading/personal_notes/`):
```
reading/personal_notes/
├── bloc/          ← personal_notes_bloc, event, state
├── models/        ← personal_note
├── repository/    ← personal_notes_repository
├── services/      ← personal_note_draft_service, personal_notes_import_export_service,
│                     personal_notes_service
├── storage/       ← personal_notes_database
├── utils/         ← note_collection_utils, note_text_utils
└── personal_notes_system.dart
```

**`tabs/`** (9 קבצים → יעברו ל-`reading/tabs/`):
```
reading/tabs/
├── bloc/          ← tabs_bloc, event, state
├── models/        ← tab, text_tab, pdf_tab, searching_tab, combined_tab
└── tabs_repository.dart
```

**`tools/`** (31 קבצי לוגיקה נשארים, 29 UI עוברים ל-`ui/tools/`):
```
tools/ (נשאר — לוגיקה בלבד)
├── calendar/
│   ├── helpers/   ← date_helpers, navigation_helpers, print_helpers, daf_yomi_navigation,
│   │                  molad_helpers, zmanim_helpers
│   ├── models/    ← calendar_location
│   ├── services/  ← google_calendar_credentials, google_calendar_service, notification_service
│   └── utils/     ← calendar_cubit, calendar_print_helper
├── dictionary/
│   └── repository/ ← dictionary_lookup_repository
├── gematria/
│   ├── gematria_search.dart
│   └── models/    ← gematria_search_result
├── measurement_converter/
│   └── measurement_data.dart
└── shamor_zachor/
    ├── shamor_zachor.dart, shamor_zachor_config.dart
    ├── config/    ← built_in_books_config
    ├── models/    ← book_model, error_model, progress_model
    ├── providers/ ← data_provider, progress_provider
    ├── services/  ← data_loader, progress_service, bootstrap_worker
    └── utils/     ← json_utils, message_utils, hebrew_utils (יועבר מ-widgets/ ב-Commit 8)
```

---

### `reading/` — יווצר ב-Phase 2, Commit 9

```
lib/reading/                    ← NEW
├── text_book/                  ← לוגיקת צופה הטקסט
├── pdf_book/                   ← לוגיקת צופה ה-PDF
├── search/                     ← לוגיקת החיפוש
├── personal_notes/             ← לוגיקת ההערות האישיות
└── tabs/                       ← לוגיקת ניהול הכרטיסיות
```

**מקביל ל-`lib/ui/reading/`** — אותם פיצ'רים, שני שכבות נפרדות.

**תלויות צולבות פנימיות (נשמרות לאחר המעבר):**
```
reading/tabs/       ←→ reading/text_book/   (text_tab מייבא text_book_bloc + repository)
reading/tabs/       ←→ reading/search/      (searching_tab מייבא search_bloc + query_builder)
reading/text_book/  ←   reading/search/     (bloc מייבא search_configuration)
reading/text_book/  ←   reading/personal_notes/ (view מייבא personal_notes_system)
reading/pdf_book/   ←   reading/search/     (bloc מייבא search_configuration)
reading/pdf_book/   ←   reading/tabs/       (bloc מייבא pdf_tab)
```

---

### `plugins/` — עצמאי, לא נוגעים

| תיקייה | קבצים | תיאור |
|--------|-------|--------|
| `plugins/` | 50 | מערכת פלאגינים: API, WebView, RPC, storage, bridge — מבוצרת ועצמאית |

מועמד ל-Phase 3 (החלטה עצמאית).

---

## סיכום — מצב אחרי Phase 2

```
lib/
├── main.dart + app_bloc_observer.dart
│
├── core/           ← תשתית אפליקציה
├── seforim/        ← תשתית נתוני ספרים
├── models/         ← מודלים משותפים
├── services/       ← שירותים משותפים
├── utils/          ← כלי עזר (כולל utils/ui/ שממתין ל-Phase 3)
│
├── navigation/     ← ניווט
├── settings/       ← הגדרות
│
├── library/        ← ספרייה
├── reader_memory/  ← זיכרון קריאה
├── find_ref/       ← חיפוש הפניות
├── tour/           ← מדריך
├── printing/       ← הדפסה
│
├── reading/        ← NEW: לוגיקת כל פיצ'רי הקריאה
│   ├── text_book/
│   ├── pdf_book/
│   ├── search/
│   ├── personal_notes/
│   └── tabs/
│
├── tools/          ← כלים (לוגיקה בלבד, UI עבר ל-ui/tools/)
│
├── plugins/        ← מערכת פלאגינים
│
└── ui/             ← כל ה-UI (ראה plan_ui_separation.md)
    ├── reading/
    ├── tools/
    └── [שאר Phase 1 features]
```

### טבלת סטטוס סופית

| תיקייה | מצב אחרי Phase 1 | מצב אחרי Phase 2 | הערה |
|--------|-----------------|-----------------|------|
| `core/` | ✅ מאורגן | ✅ ללא שינוי | activation, window, lifecycle, work_status |
| `seforim/` | ✅ נוצר ב-Phase 1 | ✅ ללא שינוי | data + sync + indexing + migration |
| `models/` | ✅ | ✅ ללא שינוי | |
| `services/` | ✅ | ✅ ללא שינוי | |
| `utils/` | ✅ | ⚠️ utils/ui/ ממתין ל-Phase 3 | |
| `navigation/` | ✅ | ✅ ללא שינוי | |
| `settings/` | ✅ מאורגן | ✅ ללא שינוי | כולל shortcuts/ |
| `library/` | ✅ נוצר ב-Phase 1 | ✅ ללא שינוי | כולל empty + external |
| `reader_memory/` | ✅ נוצר ב-Phase 1 | ✅ ללא שינוי | |
| `find_ref/` | ✅ | ✅ ללא שינוי | |
| `tour/` | ✅ | ✅ ללא שינוי | |
| `printing/` | ✅ | ✅ ללא שינוי | |
| `text_book/` | ⏳ Phase 2 | 📦 לוגיקה → reading/text_book/ | תיקייה תישאר אם יש תת-תיקיות שלא עברו |
| `pdf_book/` | ⏳ Phase 2 | 📦 לוגיקה → reading/pdf_book/ | |
| `search/` | ⏳ Phase 2 | 📦 לוגיקה → reading/search/ | |
| `personal_notes/` | ⏳ Phase 2 | 📦 לוגיקה → reading/personal_notes/ | |
| `tabs/` | ⏳ Phase 2 | 📦 לוגיקה → reading/tabs/ | reading_screen → ui/reading/ |
| `tools/` | ⏳ Phase 2 | 🔀 UI → ui/tools/, לוגיקה נשארת | |
| `reading/` | — | ✨ נוצר ב-Phase 2 | |
| `plugins/` | 🔒 עצמאי | 🔒 ממתין ל-Phase 3 | |
| `ui/` | ✅ נוצר ב-Phase 1 | ✅ מורחב ב-Phase 2 | ראה plan_ui_separation.md |
