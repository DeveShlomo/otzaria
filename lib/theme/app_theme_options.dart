/// אפשרויות ערכות נושא לרקע מסך העיון.
/// ניתן להוסיף כאן אפשרויות נוספות לערכות נושא עתידיות.
library;

import 'package:flutter/material.dart';
import 'package:otzaria/theme/app_colors.dart';

/// אפשרויות רקע מסך העיון במצב בהיר
enum LightReaderBackground {
  white('לבן', 'רקע לבן לגמרי'),
  surface('בהיר', 'רקע בהיר — ברירת המחדל'),
  blended('צבע חלש', 'רקע עם גוון עדין'),
  surfaceDim('צבעוני', 'רקע עם גוון צבעוני'),
  parchment('פרגמנט', 'רקע חם המדמה דף ספר'),
  mint('מנטה', 'רקע ירוק עדין ומרגיע');

  const LightReaderBackground(this.label, this.subtitle);
  final String label;
  final String subtitle;

  Color color(ColorScheme cs) => switch (this) {
        LightReaderBackground.white => Colors.white,
        LightReaderBackground.surface => cs.surface,
        LightReaderBackground.blended => Color.alphaBlend(
            cs.surfaceContainerHighest.withValues(alpha: 0.475),
            cs.surface,
          ),
        LightReaderBackground.surfaceDim => const Color(0xFFF8F5F0),
        LightReaderBackground.parchment => const Color(0xFFF5EAD6),
        LightReaderBackground.mint => const Color(0xFFEBF2EA),
      };
}

/// אפשרויות רקע מסך העיון במצב כהה
enum DarkReaderBackground {
  black('שחור', 'רקע שחור לגמרי'),
  darkScaffold('אפור', 'רקע אפור — ברירת המחדל'),
  surface('צבע חלש', 'רקע עם גוון עדין'),
  surfaceDim('צבעוני', 'רקע עם גוון צבעוני'),
  darkSepia('ספיה כהה', 'רקע חום כהה וחם לקריאה לילית');

  const DarkReaderBackground(this.label, this.subtitle);
  final String label;
  final String subtitle;

  Color color(ColorScheme cs) => switch (this) {
        DarkReaderBackground.black => Colors.black,
        DarkReaderBackground.darkScaffold => AppColors.darkScaffold,
        DarkReaderBackground.surface => cs.surface,
        DarkReaderBackground.surfaceDim => const Color(0xFF1A1F29),
        DarkReaderBackground.darkSepia => const Color(0xFF1F1A16),
      };
}
