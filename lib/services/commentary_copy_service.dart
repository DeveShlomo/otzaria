import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:otzaria/ui/core/ui_snack.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/links.dart';
import 'package:otzaria/utils/text/text_manipulation.dart' as utils;
import 'package:otzaria/utils/text/copy_utils.dart';
import 'package:otzaria/settings/settings_exports.dart';
import 'package:otzaria/settings/services/nikud_display_service.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/view/selection/selected_text_copy.dart';

TextBook targetBookFromLink(Link link) {
  return TextBook(
    title: utils.getTitleFromPath(link.path2),
    categoryId: link.targetCategoryId,
    fileType: link.targetFileType,
  );
}

/// העתקת פסקה שלמה של מפרש
Future<void> copyCommentaryParagraph({
  required BuildContext context,
  required Link link,
  required double fontSize,
}) async {
  try {
    final settingsState = context.read<SettingsBloc>().state;

    final content = await link.content;
    if (content.trim().isEmpty) {
      UiSnack.show('אין תוכן להעתקה');
      return;
    }

    final removeNikud = await resolveRemoveNikudForBook(
      title: utils.getTitleFromPath(link.path2),
      defaultRemoveNikud: settingsState.defaultRemoveNikud,
      removeNikudFromTanach: settingsState.removeNikudFromTanach,
      categoryId: link.targetCategoryId,
      fileType: link.targetFileType,
    );

    final processedContent =
        removeNikud ? utils.removeVolwels(content) : content;
    final plainText = utils.stripHtmlIfNeeded(processedContent);

    String finalText = plainText;
    String finalHtmlText = processedContent;

    if (settingsState.copyWithHeaders != 'none') {
      final targetBook = targetBookFromLink(link);
      final bookName = CopyUtils.extractBookName(targetBook);
      final currentPath = await CopyUtils.extractCurrentPath(
        targetBook,
        link.index2 - 1,
      );

      finalText = CopyUtils.formatTextWithHeaders(
        originalText: plainText,
        copyWithHeaders: settingsState.copyWithHeaders,
        copyHeaderFormat: settingsState.copyHeaderFormat,
        bookName: bookName,
        currentPath: currentPath,
      );

      finalHtmlText = CopyUtils.formatTextWithHeaders(
        originalText: processedContent,
        copyWithHeaders: settingsState.copyWithHeaders,
        copyHeaderFormat: settingsState.copyHeaderFormat,
        bookName: bookName,
        currentPath: currentPath,
      );
    }

    final copyContent = CopyUtils.applyCopyPreferencesForClipboard(
      plainText: finalText,
      htmlText: finalHtmlText,
      replaceHolyNames: settingsState.replaceHolyNames,
    );

    final htmlText = CopyUtils.buildStyledHtml(
      htmlText: copyContent.htmlText,
      fontFamily: settingsState.commentatorsFontFamily,
      fontSize: fontSize,
    );

    final clipboard = SystemClipboard.instance;
    if (clipboard != null) {
      final item = DataWriterItem();
      item.add(Formats.plainText(copyContent.plainText));
      item.add(Formats.htmlText(htmlText));
      await clipboard.write([item]);
      UiSnack.show('הפסקה הועתקה בהצלחה');
    }
  } catch (e) {
    debugPrint('Error copying commentary paragraph: $e');
    UiSnack.showError('שגיאה בהעתקת הפסקה');
  }
}

/// העתקת טקסט מעוצב (HTML) ללוח
Future<void> copyFormattedText({
  required BuildContext context,
  required String? savedSelectedText,
  required double fontSize,
  Link? link,
}) async {
  final plainText = savedSelectedText;

  if (plainText == null || plainText.trim().isEmpty) {
    UiSnack.show('אנא בחר טקסט להעתקה');
    return;
  }

  try {
    final clipboard = SystemClipboard.instance;
    if (clipboard != null) {
      final settingsState = context.read<SettingsBloc>().state;
      if (link != null && settingsState.copyWithHeaders != 'none') {
        final textBookState = context.read<TextBookBloc>().state;
        if (textBookState is! TextBookLoaded) return;

        await copySelectedTextForBook(
          plainText: plainText,
          selectedIndex: link.index2 - 1,
          sourceContent: [plainText],
          textBookState: textBookState,
          settingsState: settingsState,
          fontFamily: settingsState.commentatorsFontFamily,
          fontSize: fontSize,
          headerBookOverride: targetBookFromLink(link),
        );
        return;
      }

      final finalPlainText = CopyUtils.applyCopyPreferences(
        text: plainText,
        replaceHolyNames: settingsState.replaceHolyNames,
      );

      final htmlText = CopyUtils.buildStyledHtml(
        htmlText: finalPlainText,
        fontFamily: settingsState.commentatorsFontFamily,
        fontSize: fontSize,
      );

      final item = DataWriterItem();
      item.add(Formats.plainText(finalPlainText));
      item.add(Formats.htmlText(htmlText));

      await clipboard.write([item]);
      UiSnack.show('הטקסט הועתק');
    }
  } catch (e) {
    debugPrint('Error copying text: $e');
    UiSnack.showError('שגיאה בהעתקת הטקסט');
  }
}
