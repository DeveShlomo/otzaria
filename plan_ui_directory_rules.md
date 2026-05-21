# כללי תיקיית `lib/ui/` — הגדרה ומבנה

---

## הגדרה: מה זה `lib/ui/`?

`lib/ui/` מכיל **אך ורק** קוד שמתאר **איך האפליקציה נראית**.

קוד שייך ל-`lib/ui/` אם הוא:
- מגדיר `Widget`, `StatelessWidget`, `StatefulWidget`
- משתמש ב-`BuildContext`
- מגדיר `ThemeData`, `ColorScheme`, צבעים, פונטים, טוקני עיצוב
- מציג תוכן על המסך (מסכים, דיאלוגים, פאנלים, כפתורים)

**הבהרה:** "לוגיקת תצוגה" (animation timing, haptic feedback, variant styling) שייכת ל-UI.
רק לוגיקה **עסקית** (repositories, services, data processing) לא שייכת ל-UI.

---

## כלל ברזל: מה **אסור** להיות ב-`lib/ui/`

| אסור | שייך ל |
|------|--------|
| `BLoC`, `Cubit`, `Event`, `State` | `lib/[feature]/bloc/` |
| `Repository`, שאילתות DB | `lib/[feature]/repository/` |
| `Service` (עסקי, data) | `lib/services/` או `lib/[feature]/services/` |
| `util`, `helper`, עיבוד טקסט | `lib/utils/` |
| אתחול אפליקציה, bootstrap logic | `lib/core/app_initializer.dart` |
| קוד ללא `import 'package:flutter/...'` | לוגיקה — אל תכניס |

---

## עקרון עומק — ללא רגרסיה

```
עכשיו:    lib / library / view / library_browser.dart    = 3 רמות
יעד:      lib / ui / library / library_browser.dart       = 3 רמות ✅
שגוי:     lib / ui / features / library / library_browser = 4 רמות ❌
```

**פיצ'רים נמצאים ישירות תחת `lib/ui/[feature]/`** — אין תיקיית `features/` ביניים.

---

## מבנה התיקייה

```
lib/ui/
│
├── app.dart                     ← MaterialApp ראשי
│
├── theme/                       ← קונפיגורציית עיצוב גלובלית
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
├── widgets/                     ← רכיבי UI לשימוש חוזר (cross-feature בלבד)
│   ├── buttons/
│   ├── dialogs/
│   ├── feedback/
│   ├── inputs/
│   ├── layout/
│   ├── lists/
│   ├── misc/
│   ├── navigation/
│   ├── smart_text/
│   ├── text/
│   └── widgets_exports.dart
│
├── update/                      ← UI לעדכון גרסה
│
├── screens/                     ← מסכים ראשיים של האפליקציה (app shell)
│   ├── main_window_screen.dart
│   ├── custom_title_bar.dart
│   ├── favorites_screen.dart
│   └── startup_work_gate.dart
│
├── core/                        ← UI גלובלי + תשתית תצוגה
│   ├── splash_screen.dart
│   ├── ui_snack.dart
│   ├── work_status_overlay.dart ← כמו ui_snack — גלובלי, שייך ל-core
│   └── app_bootstrap_screen.dart
│
├── library/                     ← Phase 1
├── settings/                    ← Phase 1
├── reader_memory/               ← Phase 1
├── find_ref/                    ← Phase 1
├── tour/                        ← Phase 1
├── printing/                    ← Phase 1
└── file_sync/                   ← Phase 1
    (Phase 2: text_book, pdf_book, search, etc.)
```

---

## מתי ל-`widgets/` ומתי ל-`ui/[feature]/`?

| קריטריון | → `ui/widgets/` | → `ui/[feature]/` |
|---------|-----------------|-------------------|
| משמש ביותר מפיצ'ר אחד? | ✅ | ❌ |
| ספציפי לפיצ'ר אחד? | ❌ | ✅ |
| מכיל BlocBuilder ספציפי לפיצ'ר? | ❌ | ✅ |
| דיאלוג גנרי (confirm, input, password)? | ✅ | ❌ |
| מסך/screen שלם? | ❌ | ✅ |
| טוקן עיצוב / קבוע עיצובי? | → `ui/theme/` | — |

**כלל usage:** אם ווידג'ט מיובא מפיצ'ר אחד בלבד → שייך לפיצ'ר, **לא** ל-`widgets/`.
דוגמה: `reusable_items_dialog` ו-`items_list_view` מיובאים רק מ-reader_memory → נמצאים ב-`lib/ui/reader_memory/`.

**כלל קידום:** אם ווידג'ט שהיה feature-specific נדרש בפיצ'ר נוסף → מקדמים אותו ל-`ui/widgets/` באותו commit.

---

## `ui/core/` — מה נכנס לשם?

רכיבי UI **גלובליים** שאינם שייכים לפיצ'ר ספציפי:

| קובץ | מה הוא |
|------|--------|
| `splash_screen.dart` | מסך הפתיחה הראשוני |
| `ui_snack.dart` | toast notifications כלל-אפליקטיביים |
| `work_status_overlay.dart` | תצוגת תהליכי רקע (indexing, sync) — גלובלי |
| `app_bootstrap_screen.dart` | AppBootstrap Widget (BlocProvider setup) |

`work_status_overlay` שייך ל-`core/` ולא ל-`ui/work_status/` מאותה סיבה ש-`ui_snack` שייך ל-`core/` — שניהם כלי תצוגת סטטוס גלובליים.

---

## כלל Imports — חד-כיווני

```
lib/ui/ → מותר לייבא מ: lib/services/, lib/utils/, lib/[feature]/bloc/, lib/models/, lib/core/
lib/services/ / lib/utils/ / lib/core/ → אסור לייבא מ-lib/ui/ !
```

---

## טיפול בקבצים מעורבים

| קובץ מקור | UI → `lib/ui/` | לוגיקה → `lib/` |
|-----------|---------------|-----------------|
| `lib/main.dart` | `ui/core/app_bootstrap_screen.dart` | `core/app_initializer.dart` |
| `lib/navigation/view/main_window_screen.dart` | `ui/screens/main_window_screen.dart` | `core/main_window_coordinator.dart` |
| `lib/utils/ui/context_menu_utils.dart` | `ui/widgets/misc/context_menu_builder.dart` | `services/commentary_copy_service.dart` |
| `lib/library/view/library_panel_controller.dart` | `ui/library/library_panel_controller_ui.dart` | `library/services/library_panel_service.dart` |
| `lib/external_catalog/view/external_catalog_settings_helper.dart` | `ui/library/external_catalog_settings_ui.dart` | `library/external/external_catalog_sync_service.dart` |
| `lib/settings/services/safer_mode/protected_settings_wrapper.dart` | `ui/settings/protected_settings_wrapper.dart` | `settings/services/safer_mode/password_verifier.dart` |

---

## Color Overrides — FORBIDDEN

**אסור בכל `lib/ui/`:**
- `hoverColor` על InkWell/ListTile (אלא `Colors.transparent` על ListTile עם כפתורים)
- `splashColor`, `overlayColor`
- `.withValues(alpha: ...)` לצבעי interaction

כל הגדרות interaction color → ב-`lib/ui/theme/` בלבד.

---

## Checklist לפני PR

- [ ] כל Widget חדש נמצא ב-`lib/ui/`
- [ ] ווידג'ט feature-specific נמצא ב-`lib/ui/[feature]/` ולא ב-`lib/ui/widgets/`
- [ ] `lib/services/`, `lib/utils/`, `lib/core/` לא מייבאים מ-`lib/ui/`
- [ ] קובץ exports עודכן אם נוסף קובץ חדש
- [ ] אין BLoC/Repository ב-`lib/ui/`
- [ ] `flutter analyze` עובר ב-0 שגיאות
