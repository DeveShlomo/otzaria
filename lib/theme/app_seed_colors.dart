import 'package:flutter/material.dart';

/// צבעי הבסיס הזמינים לבחירת ערכת הצבעים של האפליקציה.
///
/// כל צבע משמש כ-seed ל-[ColorScheme.fromSeed] ומייצר ערכת צבעים מלאה.
/// הסדר תואם את פלטת הצבעים המוכרת (גלגל הצבעים).
class AppSeedColors {
  AppSeedColors._();

  // ── ברירות מחדל ————————————————————————————————
  // הצבעים שמוגדרים כברירת מחדל לכל מצב תצוגה.
  // אינם חלק מרשימת options — הם קבועים נפרדים.
  static const Color defaultLight = darkBrown;
  static const Color defaultDark = lightPurple;

  // ── צבעים (לפי סדר גלגל הצבעים) —————————————
  static const Color darkBrown = Color(0xFF2C1B02);
  static const Color red = Color(0xFFF44336);
  static const Color pink = Color(0xFFE91E63);
  static const Color purple = Color(0xFF9C27B0);
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color lightPurple = Color(0xFFCE93D8);
  static const Color indigo = Color(0xFF3F51B5);
  static const Color blue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF03A9F4);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color teal = Color(0xFF009688);
  static const Color green = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF8BC34A);
  static const Color lime = Color(0xFFCDDC39);
  static const Color amber = Color(0xFFFFC107);
  static const Color orange = Color(0xFFFF9800);
  static const Color deepOrange = Color(0xFFFF5722);
  static const Color brown = Color(0xFF795548);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color grey = Color(0xFF9E9E9E);

  /// רשימת כל הצבעים עם שמותיהם בעברית, לפי סדר גלגל הצבעים
  static const List<({Color color, String name})> options = [
    (color: darkBrown, name: 'חום כהה'),
    (color: red, name: 'אדום'),
    (color: pink, name: 'ורוד'),
    (color: purple, name: 'סגול'),
    (color: deepPurple, name: 'סגול כהה'),
    (color: lightPurple, name: 'סגול בהיר'),
    (color: indigo, name: 'אינדיגו'),
    (color: blue, name: 'כחול'),
    (color: lightBlue, name: 'כחול בהיר'),
    (color: cyan, name: 'ציאן'),
    (color: teal, name: 'ירקרק'),
    (color: green, name: 'ירוק'),
    (color: lightGreen, name: 'ירוק בהיר'),
    (color: lime, name: 'לימוני'),
    (color: amber, name: 'ענבר'),
    (color: orange, name: 'כתום'),
    (color: deepOrange, name: 'כתום כהה'),
    (color: brown, name: 'חום'),
    (color: blueGrey, name: 'אפור-כחול'),
    (color: grey, name: 'אפור'),
  ];

  /// מחזיר את השם העברי של צבע, או null אם לא נמצא ברשימה.
  static String? nameOf(Color color) {
    for (final entry in options) {
      if (entry.color == color) return entry.name;
    }
    return null;
  }
}
