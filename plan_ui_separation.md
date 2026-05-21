# תוכנית הפרדת UI/UX מלוגיקה — סקירה מלאה

> **מטרה:** העברת כל קוד תצוגה לתיקיית `lib/ui/`, תוך שמירה על אותה **עומק ניווט** כמו היום.
> הבחנה בין **Phase 1** (תשתית גלובלית) ל-**Phase 2** (פיצ'רים מורכבים).

---

## עקרון עומק ניווט — ללא רגרסיה

```
עכשיו:    lib / library / view / library_browser.dart     = 3 רמות
יעד:      lib / ui / library / library_browser.dart        = 3 רמות ✅
שגוי:     lib / ui / features / library / library_browser  = 4 רמות ❌
```

**כלל:** פיצ'רים נכנסים **ישירות** תחת `lib/ui/[feature]/` — אין תיקיית `features/` ביניים.

---

## הבהרות קונספטואליות

### `lib/core/ui_snack.dart` — UI טהור
לוגיקת `UiSnack` (timing, haptic, variants) היא **לוגיקת תצוגה** — לא לוגיקה עסקית.
עובר ל-`lib/ui/core/ui_snack.dart` ללא שינוי.

### `lib/work_status/work_status_overlay.dart` → `lib/ui/core/`
`WorkStatusOverlay` הוא UI גלובלי (כמו ui_snack) — עובר ל-`lib/ui/core/`, **לא** ל-`lib/ui/work_status/`.

### `lib/theme/` — עובר כולו ל-`lib/ui/theme/`
קונפיגורציית עיצוב (צבעים, פונטים, ThemeData) שייכת ל-UI בלבד. ללא פיצול.

### ווידג'טים feature-specific יעברו עם הפיצ'ר
`reusable_items_dialog.dart` ו-`items_list_view.dart` מיובאים **רק** על-ידי bookmark ו-history.
הם אינם "shared widgets" — יעברו ל-`lib/ui/reader_memory/`.

### `lib/plugins/` — לא נוגעים ב-Phase 1
מודול עצמאי. Phase 2 יחליט בנפרד.

---

## מבנה `lib/ui/` — מלא

```
lib/ui/
│
├── app.dart                               ← lib/app.dart
│
├── theme/                                 ← lib/theme/ (כולו)
│   ├── app_theme_data.dart
│   ├── app_colors.dart
│   ├── app_seed_colors.dart
│   ├── app_surfaces.dart
│   ├── app_fonts.dart
│   ├── app_tokens.dart
│   ├── layout_tokens.dart
│   ├── app_interactions.dart
│   └── theme_exports.dart
│
├── widgets/                               ← lib/widgets/ (ללא ה-2 שעוברים ל-reader_memory)
│   ├── buttons/
│   ├── dialogs/                           ← reusable_items_dialog.dart עובר מכאן ל-reader_memory/
│   ├── feedback/
│   ├── inputs/
│   ├── layout/
│   ├── lists/                             ← items_list_view.dart עובר מכאן ל-reader_memory/
│   ├── misc/
│   │   └── context_menu_builder.dart      ← NEW (פיצול מ-context_menu_utils)
│   ├── navigation/
│   ├── smart_text/
│   ├── text/
│   └── widgets_exports.dart               ← יש לעדכן (הסרת שני הקבצים שעברו)
│
├── update/                                ← lib/update/ (כולו)
│
├── screens/                               ← מסכים ראשיים של האפליקציה
│   ├── main_window_screen.dart            ← lib/navigation/view/ (UI בלבד אחרי פיצול)
│   ├── custom_title_bar.dart
│   ├── favorites_screen.dart
│   └── startup_work_gate.dart
│
├── core/                                  ← UI גלובלי + תשתית תצוגה
│   ├── splash_screen.dart                 ← lib/core/splash_screen.dart
│   ├── ui_snack.dart                      ← lib/core/ui_snack.dart
│   ├── work_status_overlay.dart           ← lib/work_status/work_status_overlay.dart
│   └── app_bootstrap_screen.dart          ← NEW (פיצול מ-main.dart)
│
│   ── Phase 1 features (ישירות תחת lib/ui/) ──────────────────────
│
├── library/                               ← 3 רמות: lib/ui/library/[file]
│   ├── library_browser.dart               ← lib/library/view/
│   ├── grid_items.dart
│   ├── book_preview_panel.dart
│   ├── otzar_book_dialog.dart
│   ├── library_daf_yomi.dart
│   ├── library_panel_controller_ui.dart   ← NEW (פיצול)
│   ├── empty_library_screen.dart          ← lib/empty_library/
│   └── external_catalog_settings_ui.dart  ← NEW (פיצול)
│
├── settings/
│   ├── settings_screen.dart               ← lib/settings/view/
│   ├── tabs/                              ← lib/settings/tabs/
│   ├── panels/                            ← lib/settings/panels/
│   ├── dialogs/                           ← lib/settings/dialogs/
│   ├── search/                            ← lib/settings/search/ (UI files)
│   ├── protected_settings_wrapper.dart    ← NEW (פיצול)
│   ├── custom_folders_tile.dart
│   └── shortcuts/                         ← lib/shortcuts/ (UI files)
│       ├── keyboard_shortcuts.dart
│       ├── custom_shortcut_dialog.dart
│       └── shortcut_dropdown_tile.dart
│
├── reader_memory/
│   ├── bookmark_screen.dart               ← lib/bookmarks/view/
│   ├── history_screen.dart                ← lib/history/view/
│   ├── workspace_switcher_dialog.dart     ← lib/workspaces/view/
│   ├── reusable_items_dialog.dart         ← lib/widgets/dialogs/ (feature-specific)
│   └── items_list_view.dart               ← lib/widgets/lists/ (feature-specific)
│
├── find_ref/
│   └── find_ref_dialog.dart               ← lib/find_ref/view/
│
├── tour/
│   ├── tour_overlay_screen.dart           ← lib/tour/view/
│   ├── tour_tooltip_card.dart
│   ├── tour_progress_dots.dart
│   ├── live_tip_card.dart
│   └── spotlight_overlay.dart
│
├── printing/
│   └── printing_screen.dart               ← lib/printing/view/
│
├── file_sync/
│   └── file_sync_widget.dart              ← lib/file_sync/
│
│   ── Phase 2 (לא נעברים עכשיו) ──────────────────────────────────
│
│   (text_book, pdf_book, search, personal_notes, tools, tabs, plugins)
```

---

## קבצים מעורבים שיש לפצל

### 🔴 קריטי

| קובץ מקור | UI חדש | לוגיקה חדשה |
|-----------|--------|-------------|
| `lib/main.dart` | `lib/ui/core/app_bootstrap_screen.dart` | `lib/core/app_initializer.dart` |
| `lib/navigation/view/main_window_screen.dart` | `lib/ui/screens/main_window_screen.dart` | `lib/core/main_window_coordinator.dart` |

### 🟠 גבוה

| קובץ מקור | UI חדש | לוגיקה חדשה |
|-----------|--------|-------------|
| `lib/utils/ui/context_menu_utils.dart` | `lib/ui/widgets/misc/context_menu_builder.dart` | `lib/services/commentary_copy_service.dart` |
| `lib/library/view/library_panel_controller.dart` | `lib/ui/library/library_panel_controller_ui.dart` | `lib/library/services/library_panel_service.dart` |
| `lib/external_catalog/view/external_catalog_settings_helper.dart` | `lib/ui/library/external_catalog_settings_ui.dart` | `lib/library/external/external_catalog_sync_service.dart` |
| `lib/settings/services/safer_mode/protected_settings_wrapper.dart` | `lib/ui/settings/protected_settings_wrapper.dart` | `lib/settings/services/safer_mode/password_verifier.dart` |

---

## קובץ לוגיקה במקום הלא נכון

| קובץ | בעיה | יעד |
|------|------|-----|
| `lib/widgets/smart_text/text_renderer_service.dart` | שירות לוגיקה בתוך widgets | `lib/services/text_renderer_service.dart` |

---

## עדכוני ייבוא — היקף Phase 1

| נתיב ישן | נתיב חדש | כמות משוערת |
|----------|---------|------------|
| `package:otzaria/widgets/...` | `package:otzaria/ui/widgets/...` | ~150 קבצים |
| `package:otzaria/theme/...` | `package:otzaria/ui/theme/...` | ~100 קבצים |
| `package:otzaria/core/scaffold_messenger.dart` | `package:otzaria/ui/core/ui_snack.dart` | ~50 קבצים |
| `package:otzaria/widgets/dialogs/reusable_items_dialog.dart` | `package:otzaria/ui/reader_memory/reusable_items_dialog.dart` | bookmark + history |
| `package:otzaria/widgets/lists/items_list_view.dart` | `package:otzaria/ui/reader_memory/items_list_view.dart` | bookmark + history |
| `package:otzaria/library/view/...` | `package:otzaria/ui/library/...` | ~10 קבצים |
| `package:otzaria/navigation/view/...` | `package:otzaria/ui/screens/...` | ~10 קבצים |
