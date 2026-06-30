# תוכנית: הגדרת רקע ספרי טקסט

## סקירה כללית

הוספת הגדרה שמאפשרת למשתמש לבחור את צבע הרקע של מסך עיון הטקסט (וה-PDF).
ה-override יהיה ב-`AppSurfaces.readerBackground` — נקודה אחת, ושאר הקוד ממשיך לעבוד ללא שינוי.

---

## קבצים שמשתנים

| קובץ | סוג שינוי |
|------|-----------|
| `lib/theme/app_surfaces.dart` | שינוי `readerBackground` לקרוא מ-`AppColors` |
| `lib/theme/app_colors.dart` | הוספת פונקציה שממירה enum → Color |
| `lib/settings/engine/settings_state.dart` | הוספת 2 שדות enum |
| `lib/settings/engine/settings_event.dart` | הוספת 2 events |
| `lib/settings/engine/settings_bloc.dart` | הוספת 2 handlers |
| `lib/settings/engine/settings_repository.dart` | הוספת 2 מפתחות ו-load/save |
| `lib/settings/tabs/design_settings_tab.dart` | הוספת SettingsCard עם 2 שורות AppDropdownField |

---

## שלב 1 — הגדרת ה-Enum

**קובץ חדש:** `lib/theme/reader_background_option.dart`

```dart
/// אפשרויות רקע מסך העיון במצב בהיר
enum LightReaderBackground {
  white,     // Colors.white           — לבן
  surface,   // cs.surface             — בהיר
  blended,   // surfaceContainerHighest מוהל — צבע חלש
  surfaceDim, // cs.surfaceDim          — צבעוני
}

/// אפשרויות רקע מסך העיון במצב כהה
enum DarkReaderBackground {
  black,       // Colors.black          — שחור
  darkScaffold, // AppColors.darkScaffold — אפור
  surface,     // cs.surface            — צבע חלש
  surfaceDim,  // cs.surfaceDim         — צבעוני
}
```

---

## שלב 2 — `lib/theme/app_colors.dart`

הוספת שתי פונקציות שמחשבות Color לפי הbרירת המחדל:

```dart
import 'package:otzaria/theme/reader_background_option.dart';

/// ממיר enum של מצב בהיר לצבע בפועל
static Color lightReaderBg(
  LightReaderBackground option,
  ColorScheme cs,
) {
  return switch (option) {
    LightReaderBackground.white     => Colors.white,
    LightReaderBackground.surface   => cs.surface,
    LightReaderBackground.blended   =>
        Color.alphaBlend(cs.surfaceContainerHighest.withValues(alpha: 0.475), cs.surface),
    LightReaderBackground.surfaceDim => cs.surfaceDim,
  };
}

/// ממיר enum של מצב כהה לצבע בפועל
static Color darkReaderBg(
  DarkReaderBackground option,
  ColorScheme cs,
) {
  return switch (option) {
    DarkReaderBackground.black       => Colors.black,
    DarkReaderBackground.darkScaffold => AppColors.darkScaffold,
    DarkReaderBackground.surface     => cs.surface,
    DarkReaderBackground.surfaceDim  => cs.surfaceDim,
  };
}
```

---

## שלב 3 — `lib/theme/app_surfaces.dart`

שינוי `readerBackground` כך שישתמש בבחירת המשתמש:

```dart
// לפני (קיים):
static Color readerBackground(BuildContext context) =>
    _cs(context).isDark ? AppColors.darkScaffold : _cs(context).surface;

// אחרי:
static Color readerBackground(
  BuildContext context, {
  required LightReaderBackground lightBg,
  required DarkReaderBackground darkBg,
}) {
  final cs = _cs(context);
  return cs.isDark
      ? AppColors.darkReaderBg(darkBg, cs)
      : AppColors.lightReaderBg(lightBg, cs);
}
```

> **שימו לב:** כל הקוד שקורא `AppSurfaces.readerBackground(context)` יצטרך להעביר את שני הפרמטרים. בפועל זה 3 קבצים: `reading_screen.dart`, `pdf_book_screen.dart`, `custom_title_bar.dart`.
> הפרמטרים יגיעו מ-`BlocBuilder<SettingsBloc, SettingsState>` בכל אחד מהם.

---

## שלב 4 — `lib/settings/engine/settings_state.dart`

הוספת 2 שדות עם ברירות מחדל זהות להתנהגות הנוכחית:

```dart
// שדות חדשים (הוסף אחרי darkSeedColor):
final LightReaderBackground lightReaderBackground;
final DarkReaderBackground darkReaderBackground;
```

בconstructor — ערכי default:
```dart
this.lightReaderBackground = LightReaderBackground.surface,  // הנוכחי
this.darkReaderBackground  = DarkReaderBackground.darkScaffold, // הנוכחי
```

ב-`copyWith`:
```dart
LightReaderBackground? lightReaderBackground,
DarkReaderBackground? darkReaderBackground,
// ...
lightReaderBackground: lightReaderBackground ?? this.lightReaderBackground,
darkReaderBackground: darkReaderBackground ?? this.darkReaderBackground,
```

ב-`props`:
```dart
lightReaderBackground,
darkReaderBackground,
```

---

## שלב 5 — `lib/settings/engine/settings_event.dart`

```dart
class UpdateLightReaderBackground extends SettingsEvent {
  final LightReaderBackground value;
  const UpdateLightReaderBackground(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateDarkReaderBackground extends SettingsEvent {
  final DarkReaderBackground value;
  const UpdateDarkReaderBackground(this.value);

  @override
  List<Object?> get props => [value];
}
```

---

## שלב 6 — `lib/settings/engine/settings_bloc.dart`

```dart
// ב-constructor:
on<UpdateLightReaderBackground>(_onUpdateLightReaderBackground);
on<UpdateDarkReaderBackground>(_onUpdateDarkReaderBackground);

// Handlers:
Future<void> _onUpdateLightReaderBackground(
  UpdateLightReaderBackground event,
  Emitter<SettingsState> emit,
) async {
  emit(state.copyWith(lightReaderBackground: event.value));
  await _repository.saveLightReaderBackground(event.value);
}

Future<void> _onUpdateDarkReaderBackground(
  UpdateDarkReaderBackground event,
  Emitter<SettingsState> emit,
) async {
  emit(state.copyWith(darkReaderBackground: event.value));
  await _repository.saveDarkReaderBackground(event.value);
}
```

ב-`_onLoadSettings` — טעינה מה-repository:
```dart
lightReaderBackground: settings['lightReaderBackground'] ?? LightReaderBackground.surface,
darkReaderBackground:  settings['darkReaderBackground']  ?? DarkReaderBackground.darkScaffold,
```

---

## שלב 7 — `lib/settings/engine/settings_repository.dart`

```dart
static const String keyLightReaderBackground = 'key-light-reader-background';
static const String keyDarkReaderBackground  = 'key-dark-reader-background';
```

ב-`loadSettings`:
```dart
'lightReaderBackground': LightReaderBackground.values.firstWhere(
  (e) => e.name == SettingsWrapper.getString(keyLightReaderBackground),
  orElse: () => LightReaderBackground.surface,
),
'darkReaderBackground': DarkReaderBackground.values.firstWhere(
  (e) => e.name == SettingsWrapper.getString(keyDarkReaderBackground),
  orElse: () => DarkReaderBackground.darkScaffold,
),
```

פונקציות save:
```dart
Future<void> saveLightReaderBackground(LightReaderBackground v) =>
    SettingsWrapper.setString(keyLightReaderBackground, v.name);

Future<void> saveDarkReaderBackground(DarkReaderBackground v) =>
    SettingsWrapper.setString(keyDarkReaderBackground, v.name);
```

---

## שלב 8 — `lib/settings/tabs/design_settings_tab.dart`

הוספת `SettingsCard` חדש בין "ערכת נושא" לבין "תצוגת PDF".
כל הגדרה היא שורת `ListTile` עם `AppDropdownField` בצד — אותו pattern כמו `shortcut_dropdown_tile.dart`.

```dart
SettingsAnchor(
  cardId: 'design.reader_background',
  child: SettingsCard(
    title: 'רקע ספרי טקסט',
    children: [
      _ReaderBgTile<LightReaderBackground>(
        icon: FluentIcons.weather_sunny_24_regular,
        title: 'רקע מצב בהיר',
        subtitle: _lightBgSubtitle(state.lightReaderBackground),
        entries: const [
          AppMenuEntry(value: LightReaderBackground.white,      label: 'לבן'),
          AppMenuEntry(value: LightReaderBackground.surface,    label: 'בהיר'),
          AppMenuEntry(value: LightReaderBackground.blended,    label: 'צבע חלש'),
          AppMenuEntry(value: LightReaderBackground.surfaceDim, label: 'צבעוני'),
        ],
        value: state.lightReaderBackground,
        onSelected: (v) =>
            context.read<SettingsBloc>().add(UpdateLightReaderBackground(v)),
      ),
      _ReaderBgTile<DarkReaderBackground>(
        icon: FluentIcons.weather_moon_24_regular,
        title: 'רקע מצב כהה',
        subtitle: _darkBgSubtitle(state.darkReaderBackground),
        entries: const [
          AppMenuEntry(value: DarkReaderBackground.black,        label: 'שחור'),
          AppMenuEntry(value: DarkReaderBackground.darkScaffold, label: 'אפור'),
          AppMenuEntry(value: DarkReaderBackground.surface,      label: 'צבע חלש'),
          AppMenuEntry(value: DarkReaderBackground.surfaceDim,   label: 'צבעוני'),
        ],
        value: state.darkReaderBackground,
        onSelected: (v) =>
            context.read<SettingsBloc>().add(UpdateDarkReaderBackground(v)),
      ),
    ],
  ),
),

kSettingsCardSpacing,
```

### Widget עזר פרטי — `_ReaderBgTile`

מוסיפים בתחתית הקובץ (מחוץ ל-`DesignSettingsTab`), אותה מבנה כמו `shortcut_dropdown_tile.dart`:

```dart
class _ReaderBgTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<AppMenuEntry<T>> entries;
  final T value;
  final ValueChanged<T> onSelected;

  const _ReaderBgTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final dropdown = SizedBox(
            width: isCompact ? double.infinity : 160,
            child: AppDropdownField<T>(
              value: value,
              entries: entries,
              onSelected: (v) { if (v != null) onSelected(v); },
            ),
          );

          final titleSection = Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: kSettingsTitleStyle,
                          textDirection: TextDirection.rtl),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: kSettingsSubtitleStyle,
                          textDirection: TextDirection.rtl),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleSection, const SizedBox(height: 8), dropdown],
            );
          }
          return Row(
            children: [titleSection, const SizedBox(width: 12), dropdown],
          );
        },
      ),
    );
  }
}
```

### פונקציות subtitle (static, בתוך `DesignSettingsTab`)

```dart
static String _lightBgSubtitle(LightReaderBackground v) => switch (v) {
  LightReaderBackground.white      => 'רקע לבן לגמרי',
  LightReaderBackground.surface    => 'רקע בהיר — ברירת המחדל',
  LightReaderBackground.blended    => 'רקע עם גוון עדין',
  LightReaderBackground.surfaceDim => 'רקע עם גוון צבעוני',
};

static String _darkBgSubtitle(DarkReaderBackground v) => switch (v) {
  DarkReaderBackground.black        => 'רקע שחור לגמרי',
  DarkReaderBackground.darkScaffold => 'רקע אפור — ברירת המחדל',
  DarkReaderBackground.surface      => 'רקע עם גוון עדין',
  DarkReaderBackground.surfaceDim   => 'רקע עם גוון צבעוני',
};
```

הוספה ל-`searchEntries`:
```dart
SettingsSearchEntry(
  id: 'design.reader_background.light',
  title: 'רקע ספרי טקסט — מצב בהיר',
  subtitle: 'בחירת צבע הרקע של מסך העיון במצב בהיר',
  tab: SettingsTab.design,
  cardId: 'design.reader_background',
  keywords: ['רקע', 'טקסט', 'בהיר', 'לבן', 'surface'],
),
SettingsSearchEntry(
  id: 'design.reader_background.dark',
  title: 'רקע ספרי טקסט — מצב כהה',
  subtitle: 'בחירת צבע הרקע של מסך העיון במצב כהה',
  tab: SettingsTab.design,
  cardId: 'design.reader_background',
  keywords: ['רקע', 'טקסט', 'כהה', 'שחור', 'אפור', 'surface'],
),
```

---

## שלב 9 — עדכון קוראי `readerBackground`

כל הקבצים שקוראים `AppSurfaces.readerBackground(context)` צריכים כעת להעביר את הפרמטרים:

### `lib/tabs/reading_screen.dart` (שורה 154)
```dart
// לפני:
final readerBg = AppSurfaces.readerBackground(context);

// אחרי — עטוף ב-BlocBuilder או קרא מה-state הקיים:
final settingsState = context.read<SettingsBloc>().state;
final readerBg = AppSurfaces.readerBackground(
  context,
  lightBg: settingsState.lightReaderBackground,
  darkBg: settingsState.darkReaderBackground,
);
```

### `lib/pdf_book/view/pdf_book_screen.dart` (שורה 1033, 2234)
אותו שינוי — העבר `lightBg` ו-`darkBg` מה-state.

### `lib/navigation/view/custom_title_bar.dart` (שורות 176, 586)
אותו שינוי.

---

## סדר ביצוע מומלץ

```
1. יצירת lib/theme/reader_background_option.dart
2. עדכון lib/theme/app_colors.dart — הוספת lightReaderBg / darkReaderBg
3. עדכון lib/theme/app_surfaces.dart — שינוי חתימת readerBackground
4. עדכון settings_state.dart
5. עדכון settings_event.dart
6. עדכון settings_repository.dart
7. עדכון settings_bloc.dart
8. עדכון שלושת קוראי readerBackground
9. עדכון design_settings_tab.dart
10. flutter analyze — תיקון כל שגיאות קומפילציה
11. flutter test test/unit/settings/ + בדיקות widget רלוונטיות
```

---

## הערות חשובות

- **ברירת מחדל** — בחרנו `LightReaderBackground.surface` ו-`DarkReaderBackground.darkScaffold` כי הם זהים להתנהגות הנוכחית. משתמשים קיימים לא יחוו שינוי.
- **`withValues(alpha: ...)` בקוד הצבעים** — מותר כי הוא נמצא ב-`lib/theme/` (ב-`app_colors.dart`), לא בקובץ feature.
- **`Colors.white` ו-`Colors.black`** — אלו ערכים מוחלטים, לא hardcoded לצורכי עיצוב UI, ולכן מותרים כאן.
- **`_ReaderBgTile` — widget פרטי** לא StatefulWidget, לא צריך מצב. ה-`AppDropdownField` עצמו מנהל את מצב הpopup.
