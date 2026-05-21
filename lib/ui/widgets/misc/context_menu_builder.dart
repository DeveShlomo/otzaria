import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/utils/text/text_manipulation.dart' as utils;
import 'package:otzaria/ui/widgets/misc/app_menu_exports.dart';
import 'package:otzaria/services/commentary_copy_service.dart';

/// פונקציות עזר לתפריטי הקשר במפרשים
class ContextMenuUtils {
  /// בניית רשימת פריטי תפריט הקשר למפרש ספציפי.
  ///
  /// מחזיר [List<AppContextMenuEntry>] לשימוש עם [AppContextMenuRegion].
  ///
  /// דוגמה:
  /// ```dart
  /// AppContextMenuRegion(
  ///   menuBuilder: (ctx) => ContextMenuUtils.buildCommentaryContextMenu(
  ///     context: ctx,
  ///     link: link,
  ///     openBookCallback: ...,
  ///     fontSize: fontSize,
  ///     savedSelectedText: _savedText,
  ///     onCopySelected: _copy,
  ///   ),
  ///   child: myCommentaryWidget,
  /// )
  /// ```
  static List<AppContextMenuEntry> buildCommentaryContextMenu({
    required BuildContext context,
    required Link link,
    required Function(TextBookTab) openBookCallback,
    required double fontSize,
    String? savedSelectedText,
    required VoidCallback onCopySelected,
  }) {
    return [
      AppContextMenuEntry(
        label: 'העתק',
        icon: FluentIcons.copy_24_regular,
        enabled:
            savedSelectedText != null && savedSelectedText.trim().isNotEmpty,
        onTap: onCopySelected,
      ),
      AppContextMenuEntry(
        label: 'העתק את כל הפסקה',
        icon: FluentIcons.document_copy_24_regular,
        onTap: () => copyCommentaryParagraph(
          context: context,
          link: link,
          fontSize: fontSize,
        ),
      ),
      const AppContextMenuEntry.divider(),
      AppContextMenuEntry(
        label: 'פתח ספר זה בחלון נפרד',
        icon: FluentIcons.open_24_regular,
        onTap: () {
          openBookCallback(TextBookTab(
            book: TextBook(title: utils.getTitleFromPath(link.path2)),
            index: link.index2 - 1,
            openLeftPane: (Settings.getValue<bool>('key-pin-sidebar') ??
                    false) ||
                (Settings.getValue<bool>('key-default-sidebar-open') ?? false),
          ));
        },
      ),
    ];
  }
}
