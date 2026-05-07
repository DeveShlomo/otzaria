import 'package:flutter/services.dart';
import 'package:otzaria/shortcuts/shortcut_helper.dart';
import 'package:otzaria/shortcuts/shortcut_validator.dart';

/// קיצורי מקשים משותפים לספרי טקסט ו-PDF.
class BookKeyboardShortcuts {
  BookKeyboardShortcuts._();

  /// מזהה קיצורי מקשים של ספר ומפעיל את הפעולה המתאימה.
  ///
  /// מחזיר true אם האירוע טופל, false אם לא.
  static bool handle({
    required KeyEvent event,
    required void Function() onPrint,
    required void Function() onSearch,
    required void Function() onBookmark,
    required void Function() onNote,
  }) {
    if (event is! KeyDownEvent) return false;

    if (ShortcutHelper.matchesShortcut(
        event,
        ShortcutValidator.getShortcutValue('key-shortcut-print') ??
            ShortcutValidator.defaultShortcuts['key-shortcut-print']!)) {
      onPrint();
      return true;
    }

    if (ShortcutHelper.matchesShortcut(
        event,
        ShortcutValidator.getShortcutValue(
                ShortcutValidator.currentWindowSearchKey) ??
            ShortcutValidator
                .defaultShortcuts[ShortcutValidator.currentWindowSearchKey]!)) {
      onSearch();
      return true;
    }

    if (ShortcutHelper.matchesShortcut(
        event,
        ShortcutValidator.getShortcutValue('key-shortcut-add-bookmark') ??
            ShortcutValidator.defaultShortcuts['key-shortcut-add-bookmark']!)) {
      onBookmark();
      return true;
    }

    if (ShortcutHelper.matchesShortcut(
        event,
        ShortcutValidator.getShortcutValue('key-shortcut-add-note') ??
            ShortcutValidator.defaultShortcuts['key-shortcut-add-note']!)) {
      onNote();
      return true;
    }

    return false;
  }
}

/// Mixin נוחות לשימוש ב-State classes.
mixin BookKeyboardShortcutsMixin {
  bool handleBookKeyEvent({
    required KeyEvent event,
    required void Function() onPrint,
    required void Function() onSearch,
    required void Function() onBookmark,
    required void Function() onNote,
  }) =>
      BookKeyboardShortcuts.handle(
        event: event,
        onPrint: onPrint,
        onSearch: onSearch,
        onBookmark: onBookmark,
        onNote: onNote,
      );
}
