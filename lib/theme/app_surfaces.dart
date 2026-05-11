import 'package:flutter/material.dart';
import 'package:otzaria/theme/app_colors.dart';
import 'package:otzaria/theme/app_tokens.dart';

/// סגנון רקע מסך — plain (חלק) או tinted (עם גוון)
///
/// בעתיד: יגיע מהגדרות המשתמש במקום להיות hardcoded בכל מסך.
enum AppScreenBackground { plain, tinted }

/// רקעי מסך לסביבות שימוש שונות באפליקציה
class AppSurfaces {
  AppSurfaces._();

  /// צבע רקע מסך לפי [AppScreenBackground].
  ///
  /// - [AppScreenBackground.plain] — רקע חלק, כמו מסך העיון הראשי
  /// - [AppScreenBackground.tinted] — רקע עם גוון, כמו הגדרות/ספריה/כלים
  ///
  /// **שימוש:**
  /// ```dart
  /// Scaffold(
  ///   backgroundColor: AppSurfaces.screen(context, AppScreenBackground.tinted),
  /// )
  /// ```
  static Color screen(BuildContext context, AppScreenBackground style) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return switch (style) {
      AppScreenBackground.plain =>
        isDark ? AppColors.darkScaffold : cs.surface,
      AppScreenBackground.tinted => isDark
          ? AppColors.darkScreenTinted
          : Color.alphaBlend(
              cs.surfaceContainerHighest.withValues(alpha: 0.475),
              cs.surface,
            ),
    };
  }

  /// רקע מסכי לוח (הגדרות, ספריה, כלים) — tinted.
  ///
  /// נשמר לתאימות עם קוד קיים.
  /// שימוש חדש: העדף [screen] עם [AppScreenBackground.tinted].
  static Color panelBackground(BuildContext context) =>
      screen(context, AppScreenBackground.tinted);

  /// זהה ל-[panelBackground] — נשמר לתאימות עם קוד קיים.
  static Color solidPanelBackground(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  /// צבע ברירת המחדל לכרטיסי תוכן באפליקציה.
  static Color card(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surface;
  }

  /// צבע הצל של פאנלים צפים (AdaptiveSidePane, FloatingPanel, ContextOverlayPanel)
  static Color panelShadow(BuildContext context) => Theme.of(context)
      .colorScheme
      .shadow
      .withValues(alpha: AppTokens.shadowAlphaStrong);

  /// elevation של פאנלים צפים
  static const double panelElevation = AppTokens.elevationMedium;
}
