// lib/tools/gematria/widgets/gematria_settings_panel.dart
//
// שינויים:
//  • מסך צר (< 800): הפאנל נפתח כ-Overlay צד מהצד (Stack+Positioned) — לא דוחק תוכן
//  • מסך רחב: AnimatedContainer בצד ימין (כמו קודם)
//
// ה-Widget עצמו מחליט לפי LayoutBuilder.
// הקריאה: GematriaSettingsPanel(isVisible, onToggle) — ללא שינוי ב-API.

import 'package:flutter/material.dart';
import 'package:otzaria/settings/settings_exports.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/widgets/context_overlay_panel.dart';

class GematriaSettingsPanel extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  /// callback לסגירה בלבד (לשימוש ב-overlay) — ברירת מחדל: onToggle
  final VoidCallback? onClose;

  static const double _panelWidth = 360.0;
  static const double _narrowBreakpoint = 800.0;

  const GematriaSettingsPanel({
    super.key,
    required this.isVisible,
    required this.onToggle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // LayoutBuilder כאן מקבל את הרוחב הזמין לפאנל בתוך ה-Row.
        // במסך צר, GematriaSearchScreen שולח SizedBox(width: 0) כ-fallback,
        // וה-Overlay מופעל דרך Stack בשכבת הhero.
        // לכן אנו משתמשים ב-MediaQuery לבדיקת הרוחב האמיתי.
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < _narrowBreakpoint;

        if (isNarrow) {
          // במסך צר: הפאנל מנוהל ע"י GematriaSearchScreen דרך Stack.
          // Widget זה מחזיר SizedBox.shrink כאן.
          return const SizedBox.shrink();
        }

        return _buildWidePanel(context);
      },
    );
  }

  // ── פאנל רחב (AnimatedContainer) ──────────────────────────────────────────
  Widget _buildWidePanel(BuildContext context) {
    return AnimatedContainer(
      duration: AppTokens.animSlow,
      curve: Curves.easeInOut,
      width: isVisible ? _panelWidth : 0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerRight,
          maxWidth: _panelWidth,
          minWidth: 0,
          child: SizedBox(
            width: _panelWidth,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: _buildPanelContent(context),
            ),
          ),
        ),
      ),
    );
  }

  // ── תוכן הפאנל (משותף לצר ולרחב) ─────────────────────────────────────────
  Widget buildNarrowOverlay(BuildContext context) {
    return ContextOverlayPanel(
      isOpen: isVisible,
      onClose: onClose ?? onToggle,
      width: _panelWidth,
      alignment: AlignmentDirectional.centerStart,
      child: _buildPanelContent(context),
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    return Column(
      children: [
        // ── כותרת ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.spaceMD,
            AppTokens.spaceMD,
            AppTokens.spaceMD,
            0,
          ),
          child: Row(
            children: [
              Text(
                'הגדרות',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // ── הגדרות גימטריה ────────────────────────────────────────────────
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppTokens.spaceMD),
            child: GematriaSettingsTab(),
          ),
        ),
      ],
    );
  }
}
