// lib/widgets/nav_rail_item.dart
//
// NavRailItem — כפתור ניווט אנכי בסגנון Material 3.
//
// • אייקון (24px) מעל תווית
// • Active Indicator: AnimatedContainer + AnimatedScale → secondaryContainer pill
// • AnimatedSwitcher להחלפת regular ↔ filled
// • AnimatedDefaultTextStyle לאנימציית צבע הטקסט
// • Tooltip על כל הכפתור (לא רק על האייקון)
// • InkWell — רק על האינדיקטור (כמו Material 3 NavigationRail)

import 'package:flutter/material.dart';

class NavRailItem extends StatelessWidget {
  final IconData icon;
  final IconData? iconFilled;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  /// האם להדגיש את הפריט בגלל סיור מודרך
  final bool isTourHighlighted;

  /// מפתח לאזור המדויק שמסומן בסיור המודרך.
  final Key? tourTargetKey;

  /// מפתח לפריט הניווט כולו, כולל התווית.
  final Key? tourItemKey;

  const NavRailItem({
    super.key,
    required this.icon,
    this.iconFilled,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
    this.tourTargetKey,
    this.tourItemKey,
    this.isTourHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // האינדיקטור עם InkWell — ריחוף רק עליו
    final indicator = AnimatedScale(
      scale: isSelected ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubicEmphasized,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        decoration: BoxDecoration(
          color: isSelected ? cs.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return cs.onSurface.withValues(alpha: 0.12);
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return cs.onSurface.withValues(alpha: 0.08);
              }
              return null;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOutCubicEmphasized,
                switchOutCurve: Curves.easeInOutCubicEmphasized,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Icon(
                  isSelected && iconFilled != null ? iconFilled! : icon,
                  key: ValueKey<bool>(isSelected),
                  size: 24,
                  color: isSelected
                      ? cs.onSecondaryContainer
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubicEmphasized,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Tooltip עוטף את כל הכפתור — מופיע בריחוף על כל השטח
    if (tooltip != null) {
      content = Tooltip(
        preferBelow: false,
        message: tooltip!,
        child: content,
      );
    }

    return SizedBox(
      key: tourItemKey,
      width: 74,
      child: content,
    );
  }
}
