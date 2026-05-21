# ארכיטקטורת הפרויקט — Otzaria

---

## עקרונות עיצוב

- **BLoC Pattern** — ניהול state לכל פיצ'ר
- **Repository Pattern** — הפרדת גישה לנתונים מלוגיקה
- **UI/Logic Separation** — כל קוד תצוגה ב-`lib/ui/`, לוגיקה עסקית בחוץ

---

## מצב נוכחי (לפני ארגון מחדש)

```
lib/
├── app.dart / main.dart           ← entry point
├── core/                          ← תשתית אפליקציה
├── data/                          ← data providers ו-repositories
├── file_sync/                     ← סנכרון קבצים
├── indexing/                      ← אינדקס חיפוש
├── migration/                     ← DB generation ו-migration
├── models/                        ← מודלי נתונים משותפים
├── services/                      ← שירותים גלובליים
├── utils/                         ← כלי עזר
├── navigation/                    ← BLoC ניווט + מסכים ראשיים
├── widgets/                       ← רכיבי UI משותפים
├── theme/                         ← עיצוב גלובלי
├── update/                        ← עדכון גרסה
├── bookmarks/ history/ workspaces/← זיכרון קריאה
├── settings/ shortcuts/           ← הגדרות
├── library/ empty_library/ external_catalog/ ← ספרייה
└── [feature directories]/         ← text_book, pdf_book, search, etc.
```

---

## מבנה יעד (אחרי ארגון מחדש)

> **סטטוס:** תכנון הושלם. ביצוע טרם החל.
> קבצי תוכנית: `plan_ui_separation.md`, `plan_features_reorganization.md`, `plan_commit_order.md`

```
lib/
│
├── ui/                            ← כל קוד UI/UX
│   ├── app.dart
│   ├── theme/                     ← עיצוב גלובלי
│   ├── widgets/                   ← רכיבים משותפים
│   ├── update/                    ← עדכון גרסה
│   ├── screens/                   ← מסכים ראשיים
│   ├── core/                      ← ui_snack, splash, work_status_overlay, bootstrap
│   ├── library/                   ← Phase 1
│   ├── settings/                  ← Phase 1
│   ├── reader_memory/             ← Phase 1
│   ├── find_ref/                  ← Phase 1
│   ├── tour/                      ← Phase 1
│   ├── printing/                  ← Phase 1
│   ├── file_sync/                 ← Phase 1
│   └── [Phase 2: text_book, pdf_book, search, personal_notes, tools]
│
├── seforim/                       ← שכבת נתוני הספרים (NEW)
│   ├── providers/                 ← data providers
│   ├── repository/                ← repositories
│   ├── cache/                     ← caching
│   ├── constants/
│   ├── sync/                      ← file sync
│   ├── indexing/                  ← search indexing
│   └── migration/                 ← DB generation
│
├── reader_memory/                 ← זיכרון קריאה (NEW)
│   ├── bookmarks/
│   ├── history/
│   └── workspaces/
│
├── core/                          ← תשתית אפליקציה (מחולק)
│   ├── activation/
│   ├── window/
│   ├── lifecycle/
│   └── work_status/
│
├── library/                       ← browser + empty + external catalog
├── settings/                      ← engine + services + shortcuts
├── models/
├── services/
├── utils/
├── navigation/
│
└── [Phase 2 features — unchanged for now]
    text_book, pdf_book, search, personal_notes, tools, tabs, plugins
```

---

## שכבות ותלויות

```
┌─────────────────────────────────────────┐
│              lib/ui/                    │  Presentation Layer
│  (Widgets, Screens, Theme)              │
└──────────────┬──────────────────────────┘
               │ imports (one-way only)
┌──────────────▼──────────────────────────┐
│         Feature BLoCs / Services        │  Business Logic Layer
│  (lib/[feature]/bloc/, lib/services/)   │
└──────────────┬──────────────────────────┘
               │ imports (one-way only)
┌──────────────▼──────────────────────────┐
│              lib/seforim/               │  Data Layer
│  (providers, repositories, cache)       │
└─────────────────────────────────────────┘
```

**חוק:** כל שכבה מייבאת רק משכבות **מתחתיה**. אסור לייבא "למעלה".

---

## מבנה פיצ'ר סטנדרטי

```
lib/[feature]/
├── bloc/
│   ├── [feature]_bloc.dart
│   ├── [feature]_event.dart
│   └── [feature]_state.dart
├── models/
│   └── [feature]_model.dart
├── repository/
│   └── [feature]_repository.dart
├── services/                      (אם נדרש)
└── [view/ רק אם עדיין לא עבר ל-lib/ui/]
```

---

## מוסכמות טכניות

| נושא | כלל |
|------|-----|
| Icons | `fluentui_system_icons` בלבד |
| הודעות למשתמש | `UiSnack` בלבד |
| שדות טקסט | `RtlTextField` בלבד |
| דיאלוגים | `showSingleActionDialog` / `showTwoActionsDialog` / `showWarningDialog` |
| כפתורים | `RecommendedActionButton` / `NeutralActionButton` |
| Settings cards | `SettingsCard` |
| צבעים | `Theme.of(context).colorScheme` בלבד — ללא hardcoded |
