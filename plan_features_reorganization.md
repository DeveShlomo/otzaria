# תוכנית ארגון מחדש — תיקיות פיצ'רים ולוגיקה

> מסמך זה מתמקד בשלושה נושאים:
> 1. ארגון מחדש של תיקיות הלוגיקה (seforim, reader_memory, core, library)
> 2. איחוד תיקיות קטנות
> 3. ניהול Phase 1 vs Phase 2

---

## שאלת ה-Plugins

### מדוע לא מעבירים את UI של plugins ל-`lib/ui/`?

`lib/plugins/` היא מודול עצמאי ומבוצר:
- יש לה כלים משלה, RPC, WebView, storage, services
- היא מייצאת API מוגדר לשאר האפליקציה
- שבירת ה-view/ מתוכה לתוך lib/ui/ תפגע באנקפסולציה שלה

**החלטה:** plugins נשארת לא נגועה. אם בעתיד יוחלט לפצל — זה שלב 3 עצמאי.

---

## ה-`lib/seforim/` — תשתית נתוני הספרים

### הבעיה: בלבול בין "ספרייה" כמסך ל"ספרייה" כנתונים

| כוונה | תיקייה כיום | בעיה |
|-------|------------|------|
| מסך הספרייה (browser + BLoC) | `lib/library/` | שם נכון |
| תשתית נתוני הספרים | `lib/data/`, `lib/file_sync/`, `lib/indexing/`, `lib/migration/` | 4 תיקיות נפרדות |

### הפתרון: `lib/seforim/` = שכבת הנתונים

```
lib/seforim/                        ← NEW: תשתית נתוני ספרים
│
├── providers/                      ← ← lib/data/data_providers/
│   ├── book_composite_key.dart
│   ├── book_database_resolver.dart
│   ├── database_library_provider.dart
│   ├── external_catalog_mapper.dart
│   ├── file_system_data_provider.dart
│   ├── file_system_library_provider.dart
│   ├── hive_data_provider.dart
│   ├── library_provider.dart
│   ├── library_provider_manager.dart
│   ├── sqlite_data_provider.dart
│   ├── tantivy_data_provider.dart
│   └── user_books_database_holder.dart
│
├── repository/                     ← ← lib/data/repository/
│   ├── base_list_repository.dart
│   ├── data_repository.dart
│   └── hive_list_repository.dart
│
├── cache/                          ← ← lib/data/cache/
│   ├── books_cache.dart
│   └── acronyms_cache.dart
│
├── constants/                      ← ← lib/data/constants/
│   └── database_constants.dart
│
├── book_locator.dart               ← ← lib/data/book_locator.dart
│
├── sync/                           ← ← lib/file_sync/
│   ├── bloc/
│   │   ├── file_sync_bloc.dart
│   │   ├── file_sync_event.dart
│   │   └── file_sync_state.dart
│   ├── repository/
│   │   └── file_sync_repository.dart
│   └── library_diff_sync_worker.dart
│
├── indexing/                       ← ← lib/indexing/
│   ├── bloc/
│   │   ├── indexing_bloc.dart
│   │   ├── indexing_event.dart
│   │   └── indexing_state.dart
│   ├── repository/
│   │   └── indexing_repository.dart
│   └── services/
│       └── indexing_isolate_service.dart
│
└── migration/                      ← ← lib/migration/
    ├── database/
    ├── generator/
    ├── models/
    └── sync/
```

**UI מ-file_sync:** `file_sync_widget.dart` עובר ל-`lib/ui/features/file_sync/` (Phase 1).

### למה זה נכון ארכיטקטורית?
- כל ה-4 תיקיות עוסקות ב"מה יש לאפליקציה לקרוא"
- data/ מספק ספרים, file_sync/ מסנכרן אותם, indexing/ מאנדקס אותם, migration/ בונה אותם
- שם `seforim/` מבחין בין "מנגנון הספרים" לבין "מסך הספרייה"

---

## ה-`lib/reader_memory/` — זיכרון הקריאה

### הבעיה: 3 תיקיות קטנות לאותה מטרה

| תיקייה | מה היא | קבצים |
|--------|--------|-------|
| `lib/bookmarks/` | מיקומים שמורים בתוך ספרים | 4 |
| `lib/history/` | היסטוריית קריאה | 4 |
| `lib/workspaces/` | קבוצות טאבים שמורות | 6 |

כל שלוש שומרות **מצב קריאה של המשתמש**. זוהי קטגוריה ברורה.

### הפתרון:

```
lib/reader_memory/                  ← NEW: זיכרון קריאה מאוחד
│
├── bookmarks/                      ← ← lib/bookmarks/ (logic)
│   ├── bloc/
│   │   ├── bookmark_bloc.dart
│   │   └── bookmark_state.dart
│   ├── models/
│   │   └── bookmark.dart
│   └── repository/
│       └── bookmark_repository.dart
│
├── history/                        ← ← lib/history/ (logic)
│   ├── bloc/
│   │   ├── history_bloc.dart
│   │   ├── history_event.dart
│   │   └── history_state.dart
│   └── history_repository.dart
│
└── workspaces/                     ← ← lib/workspaces/ (logic)
    ├── bloc/
    │   ├── workspace_bloc.dart
    │   ├── workspace_event.dart
    │   └── workspace_state.dart
    ├── workspace.dart
    └── workspace_repository.dart
```

**UI מהשלוש:** עובר ל-`lib/ui/features/reader_memory/` (Phase 1).

---

## `lib/library/` — ספרייה מורחבת

### ספיגת תיקיות קטנות

`lib/empty_library/` ו-`lib/external_catalog/` הן שתיהן חלק מ-**flow הספרייה**.

```
lib/library/                        ← מורחב
│
├── bloc/                           ← נשאר
├── models/                         ← נשאר
│
├── services/
│   ├── book_preview_pdf_logic.dart ← נשאר
│   └── library_panel_service.dart  ← NEW (פיצול מ-library_panel_controller)
│
├── empty/                          ← ← lib/empty_library/
│   └── bloc/
│       ├── empty_library_bloc.dart
│       ├── empty_library_event.dart
│       └── empty_library_state.dart
│
└── external/                       ← ← lib/external_catalog/
    ├── external_catalog_repository.dart
    └── external_catalog_sync_service.dart ← NEW (פיצול)
```

---

## `lib/settings/` + `lib/shortcuts/` — איחוד

### shortcuts הוא חלק מ-settings

settings כבר יש לה `shortcuts_settings_tab.dart`.
`lib/shortcuts/` מכילה רק 6 קבצים, כולם קשורים להגדרות.

```
lib/settings/                       ← מורחב
│
├── engine/                         ← נשאר (BLoC, repository, wrapper)
├── services/
│   ├── backup_service.dart
│   ├── nikud_display_service.dart
│   ├── per_book_settings_service.dart
│   ├── safer_mode/
│   │   ├── password_verifier.dart  ← NEW (פיצול)
│   │   └── [שאר קבצים]
│   └── custom_folders/
│       ├── bloc/
│       └── custom_folder.dart
│
├── shortcuts/                      ← ← lib/shortcuts/ (logic files)
│   ├── key_map.dart
│   ├── shortcut_helper.dart
│   └── shortcut_validator.dart
│
└── search/ (logic)                 ← נשאר
```

---

## `lib/core/` — חלוקה לתת-תיקיות

### הבעיה: 13+ קבצים שונים בלי ארגון

```
lib/core/                           ← מחולק לתת-תיקיות
│
├── activation/                     ← deep links + URI routing
│   ├── external_activation_channel.dart
│   ├── external_activation_queue.dart
│   └── external_uri_router.dart
│
├── window/                         ← ניהול חלון
│   ├── window_listener.dart
│   └── window_persistence.dart
│
├── lifecycle/                      ← מחזור חיי האפליקציה
│   ├── app_runtime_reset.dart
│   ├── http_client_registry.dart
│   └── pre_close_registry.dart
│
├── work_status/                    ← ← lib/work_status/ (logic)
│   ├── work_status_item.dart
│   └── work_status_cubit.dart
│
├── app_paths.dart                  ← נשאר (single file, paths)
├── error_log_file.dart             ← נשאר
├── focus_repository.dart           ← נשאר (Flutter-aware infrastructure)
├── app_initializer.dart            ← NEW (פיצול מ-main.dart)
└── main_window_coordinator.dart    ← NEW (פיצול מ-main_window_screen)
```

**הערה על `focus_repository.dart`:** משתמש ב-`flutter/widgets.dart` (FocusNode) אבל הוא תשתית ניווט — נשאר ב-core.
**הערה על `external_activation_channel.dart`:** משתמש ב-`flutter/services.dart` (MethodChannel) — נשאר ב-core כי זה platform channel, לא UI.

---

## Phase 2 — פיצ'רים מורכבים (נדחה)

**לא נוגעים ב-Phase 1:**

| תיקייה | גודל | סיבה לדחייה |
|--------|------|------------|
| `lib/text_book/` | 66 קבצים | מורכב מאוד (combined/split/page_shape views) |
| `lib/pdf_book/` | 13 קבצים | PdfViewerController דורש refactor מקדים |
| `lib/search/` | 25 קבצים | תלויות מורכבות |
| `lib/personal_notes/` | 22 קבצים | עם editing system |
| `lib/tools/` | 57 קבצים | כולל calendar, gematria, shamor_zachor |
| `lib/tabs/` | 10 קבצים | קשור ל-text_book ו-pdf_book |
| `lib/plugins/` | 51 קבצים | מערכת עצמאית |

**Phase 2 יתחיל אחרי שה-Phase 1 יהיה יציב ו-tests יעברו.**

---

## המבנה הסופי — אחרי כל השינויים

```
lib/
├── main.dart                          ← entry point קצר
├── app_bloc_observer.dart
│
├── ui/                                ← כל UI (ראה plan_ui_separation.md)
│
├── core/
│   ├── activation/
│   ├── window/
│   ├── lifecycle/
│   ├── work_status/
│   ├── app_paths.dart
│   ├── error_log_file.dart
│   ├── focus_repository.dart
│   ├── app_initializer.dart
│   └── main_window_coordinator.dart
│
├── seforim/                           ← NEW (מ-data + file_sync + indexing + migration)
│   ├── providers/
│   ├── repository/
│   ├── cache/
│   ├── constants/
│   ├── book_locator.dart
│   ├── sync/
│   ├── indexing/
│   └── migration/
│
├── reader_memory/                     ← NEW (מ-bookmarks + history + workspaces)
│   ├── bookmarks/
│   ├── history/
│   └── workspaces/
│
├── library/                           ← מורחב (ספיגת empty_library + external_catalog)
│   ├── bloc/
│   ├── models/
│   ├── services/
│   ├── empty/
│   └── external/
│
├── settings/                          ← מורחב (ספיגת shortcuts logic)
│   ├── engine/
│   ├── services/
│   ├── shortcuts/
│   └── search/ (logic)
│
├── models/                            ← נשאר
├── services/
│   ├── commentary_copy_service.dart   ← NEW
│   ├── text_renderer_service.dart     ← הועבר מ-widgets/
│   └── [שאר services קיימים]
├── utils/                             ← נשאר
├── navigation/                        ← BLoC + repository בלבד
├── find_ref/                          ← נשאר (נשקל ב-Phase 2 להכניס ל-tools)
│
│   ─── Phase 2 (לא נגעים עכשיו) ───────────────
│
├── text_book/
├── pdf_book/
├── search/
├── personal_notes/
├── tools/
├── tabs/
└── plugins/                          ← עצמאי, לא נגעים
```
