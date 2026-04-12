import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/widgets/inputs/app_input_tokens.dart';
import 'package:otzaria/widgets/rtl_icon.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AppMenuEntry — נתוני פריט בתפריט
// ═══════════════════════════════════════════════════════════════════════════

class AppMenuEntry<T> {
  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool isDestructive;
  final Widget? trailing;

  const AppMenuEntry({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.isDestructive = false,
    this.trailing,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AppContextMenuEntry — פריט בתפריט הקשר (right-click)
// ═══════════════════════════════════════════════════════════════════════════

class AppContextMenuEntry {
  final String? label;
  final IconData? icon;
  final bool enabled;
  final bool isDivider;
  final bool isDestructive;
  final VoidCallback? onTap;

  /// תת-פריטים לתפריט משנה
  final List<AppContextMenuEntry>? children;

  const AppContextMenuEntry({
    required this.label,
    this.icon,
    this.enabled = true,
    this.isDestructive = false,
    this.onTap,
    this.children,
  }) : isDivider = false;

  const AppContextMenuEntry.divider()
      : label = null,
        icon = null,
        enabled = false,
        isDivider = true,
        isDestructive = false,
        onTap = null,
        children = null;
}

// ═══════════════════════════════════════════════════════════════════════════
// AppPopupMenuButton — כפתור שפותח תפריט
// ═══════════════════════════════════════════════════════════════════════════

class AppPopupMenuButton<T> extends StatefulWidget {
  final List<AppMenuEntry<T>>? entries;
  final List<PopupMenuEntry<T>> Function(BuildContext context)? itemBuilder;
  final ValueChanged<T>? onSelected;
  final Widget? child;
  final Widget? icon;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final PopupMenuPosition position;
  final Offset offset;
  final bool enabled;
  final T? initialValue;

  const AppPopupMenuButton({
    super.key,
    this.entries,
    this.itemBuilder,
    this.onSelected,
    this.child,
    this.icon,
    this.tooltip,
    this.padding,
    this.constraints,
    this.position = PopupMenuPosition.under,
    this.offset = const Offset(0, 4),
    this.enabled = true,
    this.initialValue,
  });

  @override
  State<AppPopupMenuButton<T>> createState() => _AppPopupMenuButtonState<T>();
}

class _AppPopupMenuButtonState<T> extends State<AppPopupMenuButton<T>> {
  final GlobalKey _anchorKey = GlobalKey();

  bool get _isTouchMode {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  bool get _hasCompactConstraints {
    final constraints = widget.constraints;
    if (constraints == null) return false;
    final minWidth = constraints.minWidth;
    final maxWidth = constraints.maxWidth;
    final minHeight = constraints.minHeight;
    final maxHeight = constraints.maxHeight;
    final width = minWidth > 0 ? minWidth : maxWidth;
    final height = minHeight > 0 ? minHeight : maxHeight;
    return width > 0 && width <= 40 && height > 0 && height <= 40;
  }

  List<PopupMenuEntry<T>> _buildItems(
    BuildContext context,
    AppMenuMetrics metrics,
  ) {
    return widget.itemBuilder?.call(context) ??
        widget.entries!
            .map<PopupMenuEntry<T>>(
              (entry) => buildAppPopupMenuItem<T>(
                context,
                entry,
                metrics,
                widget.initialValue,
              ),
            )
            .toList();
  }

  Future<void> _showAdaptiveMenu() async {
    if (!widget.enabled) return;
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;

    final selected = await showAnchoredAppMenu<T>(
      context: context,
      anchorContext: anchorContext,
      itemsBuilder: (metrics) => _buildItems(context, metrics),
      position: widget.position,
      offset: widget.offset,
    );

    if (selected != null) {
      widget.onSelected?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.entries != null || widget.itemBuilder != null);

    Widget trigger;
    if (widget.child != null) {
      trigger = InkWell(
        onTap: widget.enabled ? _showAdaptiveMenu : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusMD),
        child: widget.child,
      );
    } else if (_isTouchMode &&
        widget.tooltip != null &&
        !_hasCompactConstraints) {
      trigger = TextButton.icon(
        onPressed: widget.enabled ? _showAdaptiveMenu : null,
        icon: widget.icon ?? const Icon(FluentIcons.more_vertical_24_regular),
        label: Text(
          widget.tooltip!,
          textDirection: TextDirection.rtl,
        ),
      );
    } else {
      trigger = IconButton(
        onPressed: widget.enabled ? _showAdaptiveMenu : null,
        padding: widget.padding ?? EdgeInsets.zero,
        constraints: widget.constraints,
        tooltip: widget.tooltip,
        icon: widget.icon ?? const Icon(FluentIcons.more_vertical_24_regular),
      );
    }

    if (widget.child == null &&
        widget.constraints != null &&
        trigger is! IconButton) {
      trigger = ConstrainedBox(
        constraints: widget.constraints!,
        child: Center(child: trigger),
      );
    }

    return KeyedSubtree(
      key: _anchorKey,
      child: trigger,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// showAnchoredAppMenu — פתיחת תפריט עוגן לרכיב קיים
// ═══════════════════════════════════════════════════════════════════════════

Future<T?> showAnchoredAppMenu<T>({
  required BuildContext context,
  required BuildContext anchorContext,
  required List<PopupMenuEntry<T>> Function(AppMenuMetrics metrics)
      itemsBuilder,
  PopupMenuPosition position = PopupMenuPosition.under,
  Offset offset = Offset.zero,
}) async {
  final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
      AppMenuMetrics.create(compactMenus: false);
  final items = itemsBuilder(metrics);
  if (items.isEmpty) return null;

  final renderBox = anchorContext.findRenderObject() as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final targetRect = MatrixUtils.transformRect(
    renderBox.getTransformTo(overlay),
    Offset.zero & renderBox.size,
  );

  final menuHeight = items.fold<double>(
        metrics.menuPadding.vertical,
        (sum, item) => sum + item.height,
      );
  final spaceAbove = targetRect.top;
  final spaceBelow = overlay.size.height - targetRect.bottom;
  final preferBelow = position == PopupMenuPosition.under;
  final shouldOpenBelow = preferBelow
      ? (spaceBelow >= menuHeight || spaceBelow >= spaceAbove)
      : !(spaceAbove >= menuHeight || spaceAbove >= spaceBelow);

  final anchorTop = shouldOpenBelow
      ? targetRect.bottom + offset.dy
      : (targetRect.top - menuHeight - offset.dy).clamp(
          0.0,
          overlay.size.height,
        );

  final anchorRect = RelativeRect.fromRect(
    Rect.fromLTWH(targetRect.left, anchorTop, targetRect.width, 0),
    Offset.zero & overlay.size,
  );

  return showMenu<T>(
    context: context,
    position: anchorRect,
    items: items,
    // מינימום רוחב תואם רוחב הטריגר — סעיף 4
    constraints: BoxConstraints(minWidth: targetRect.width),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// _buildAppMenuRowContent — בניית שורת תוכן בתפריט
//
// שינויים:
// • הרקע הנבחר ממלא שורה שלמה (ללא borderRadius, ללא גבול)
// • סימן ✓ תמיד מופיע לפריט נבחר
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildAppMenuRowContent(
  BuildContext context,
  AppMenuMetrics metrics, {
  required String label,
  IconData? icon,
  Widget? leading,
  Widget? trailing,
  bool isSelected = false,
  bool isDestructive = false,
  bool enabled = true,
  Color? backgroundColor,
  Color? foregroundColor,
  FontWeight? fontWeight,
}) {
  final selectedBackground = backgroundColor ??
      (isSelected ? _resolveAppMenuSelectedBackground(context) : null);
  final resolvedForegroundColor = foregroundColor ??
      _resolveAppMenuForegroundColor(
        context,
        enabled: enabled,
        isDestructive: isDestructive,
        isSelected: isSelected,
      );
  final resolvedFontWeight =
      fontWeight ?? (isSelected ? FontWeight.w600 : metrics.itemFontWeight);

  return Container(
    constraints: BoxConstraints(
      minWidth: metrics.menuMinWidth,
      minHeight: metrics.itemHeight,
    ),
    // צבע מלא שורה — ללא עיגול פינות וללא גבול
    color: selectedBackground,
    padding: metrics.itemPadding,
    alignment: AlignmentDirectional.centerStart,
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(
              size: metrics.iconSize,
              color: resolvedForegroundColor,
            ),
            child: leading,
          ),
          const SizedBox(width: 8),
        ],
        if (icon != null) ...[
          Icon(icon, size: metrics.iconSize, color: resolvedForegroundColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: metrics.fontSize,
              fontWeight: resolvedFontWeight,
              color: resolvedForegroundColor,
            ),
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.rtl,
          ),
        ),
        // סימן ✓ לפריט נבחר (תמיד, בכל סוג תפריט)
        if (isSelected) ...[
          const SizedBox(width: 8),
          Icon(
            FluentIcons.checkmark_24_regular,
            size: metrics.iconSize,
            color: resolvedForegroundColor,
          ),
        ] else if (trailing != null) ...[
          const SizedBox(width: 8),
          IconTheme.merge(
            data: IconThemeData(
              size: metrics.iconSize,
              color: resolvedForegroundColor,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: resolvedForegroundColor),
              child: trailing,
            ),
          ),
        ],
      ],
    ),
  );
}

Color _resolveAppMenuSelectedBackground(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return colorScheme.primaryContainer.withValues(alpha: 0.95);
}

Color _resolveAppMenuForegroundColor(
  BuildContext context, {
  required bool enabled,
  bool isDestructive = false,
  bool isSelected = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  if (!enabled) {
    return colorScheme.onSurface.withValues(alpha: 0.38);
  }
  if (isDestructive) {
    return colorScheme.error;
  }
  if (isSelected) {
    return colorScheme.onPrimaryContainer;
  }
  return colorScheme.onSurface;
}

// ═══════════════════════════════════════════════════════════════════════════
// _NoSplashPopupMenuItem — PopupMenuItem ללא ripple/highlight פנימי
// ═══════════════════════════════════════════════════════════════════════════

class _NoSplashPopupMenuItem<T> extends PopupMenuItem<T> {
  const _NoSplashPopupMenuItem({
    super.key,
    super.value,
    super.enabled,
    super.height,
    super.padding,
    super.child,
  });

  @override
  PopupMenuItemState<T, PopupMenuItem<T>> createState() =>
      _NoSplashPopupMenuItemState<T>();
}

class _NoSplashPopupMenuItemState<T>
    extends PopupMenuItemState<T, _NoSplashPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: super.build(context),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _AppMenuItemRow — wrapper לניהול hover אחיד עם _AppSubmenuTriggerButton
// ═══════════════════════════════════════════════════════════════════════════

class _AppMenuItemRow extends StatefulWidget {
  final VoidCallback onEnter;
  final bool enabled;
  final Widget Function(bool isHovered) builder;

  const _AppMenuItemRow({
    required this.onEnter,
    required this.enabled,
    required this.builder,
  });

  @override
  State<_AppMenuItemRow> createState() => _AppMenuItemRowState();
}

class _AppMenuItemRowState extends State<_AppMenuItemRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHovered = widget.enabled && _isHovered;
    return MouseRegion(
      onEnter: (_) {
        widget.onEnter();
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: widget.builder(effectiveHovered),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// buildAppPopupMenuItem
// ═══════════════════════════════════════════════════════════════════════════

PopupMenuEntry<T> buildAppPopupMenuItem<T>(
  BuildContext context,
  AppMenuEntry<T> entry,
  AppMenuMetrics metrics,
  T? selectedValue,
) {
  final isSelected = selectedValue != null && entry.value == selectedValue;

  // PopupMenuItem מצייר InkWell פנימי — מבטלים splash/highlight
  // כדי שה-hover יגיע רק מ-_AppMenuItemRow (אחיד עם _AppSubmenuTriggerButton)
  return _NoSplashPopupMenuItem<T>(
    value: entry.value,
    enabled: entry.enabled,
    height: metrics.itemHeight,
    padding: EdgeInsets.zero,
    child: _AppMenuItemRow(
      onEnter: () => _globalSubmenuTracker.closeActive(),
      enabled: entry.enabled,
      builder: (isHovered) => _buildAppMenuRowContent(
        context,
        metrics,
        label: entry.label,
        icon: entry.icon,
        trailing: entry.trailing,
        isSelected: isSelected,
        isDestructive: entry.isDestructive,
        enabled: entry.enabled,
        backgroundColor: isSelected
            ? _resolveAppMenuSelectedBackground(context)
            : isHovered && entry.enabled
                ? Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08)
                : null,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// buildAppCustomPopupMenuItem
// ═══════════════════════════════════════════════════════════════════════════

PopupMenuEntry<T> buildAppCustomPopupMenuItem<T>({
  required BuildContext context,
  required AppMenuMetrics metrics,
  required Widget child,
  bool enabled = false,
  double? height,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return _AppCustomPopupMenuEntry<T>(
    heightValue: height ?? metrics.itemHeight,
    padding: padding,
    child: child,
  );
}

class _AppCustomPopupMenuEntry<T> extends PopupMenuEntry<T> {
  const _AppCustomPopupMenuEntry({
    required this.heightValue,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final double heightValue;
  final EdgeInsets padding;
  final Widget child;

  @override
  double get height => heightValue;

  @override
  bool represents(T? value) => false;

  @override
  State<_AppCustomPopupMenuEntry<T>> createState() =>
      _AppCustomPopupMenuEntryState<T>();
}

class _AppCustomPopupMenuEntryState<T>
    extends State<_AppCustomPopupMenuEntry<T>> {
  @override
  Widget build(BuildContext context) {
    final childHeight = (widget.heightValue - widget.padding.vertical)
        .clamp(0.0, double.infinity);
    return Padding(
      padding: widget.padding,
      child: SizedBox(
        height: childHeight,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// buildAppSubmenuItemStyle
// ═══════════════════════════════════════════════════════════════════════════

ButtonStyle buildAppSubmenuItemStyle(
  BuildContext context,
  AppMenuMetrics metrics, {
  bool isDestructive = false,
  bool enabled = true,
}) {
  final foregroundColor = _resolveAppMenuForegroundColor(
    context,
    enabled: enabled,
    isDestructive: isDestructive,
  );
  return ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    minimumSize:
        WidgetStatePropertyAll(Size(metrics.menuMinWidth, metrics.itemHeight)),
    visualDensity: metrics.visualDensity,
    shape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    alignment: Alignment.centerRight,
    textStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Roboto',
        fontSize: metrics.fontSize,
        fontWeight: metrics.itemFontWeight,
      ),
    ),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return _resolveAppMenuForegroundColor(context, enabled: false);
      }
      return foregroundColor;
    }),
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return _resolveAppMenuForegroundColor(context, enabled: false);
      }
      return foregroundColor;
    }),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  );
}

MenuStyle buildAppSubmenuMenuStyle(BuildContext context) {
  return MenuStyle(
    alignment: const AlignmentDirectional(1.0, -1.0),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// buildAppSubmenuPopupMenuItem
// ═══════════════════════════════════════════════════════════════════════════

PopupMenuEntry<T> buildAppSubmenuPopupMenuItem<T>({
  required BuildContext context,
  required AppMenuMetrics metrics,
  required String label,
  IconData? icon,
  bool isDestructive = false,
  required List<Widget> menuChildren,
}) {
  final controller = MenuController();

  return buildAppCustomPopupMenuItem<T>(
    context: context,
    metrics: metrics,
    child: _AppSubmenuTriggerButton(
      controller: controller,
      metrics: metrics,
      label: label,
      icon: icon,
      isDestructive: isDestructive,
      menuChildren: menuChildren,
      onHoverEnter: () {
        if (!_globalSubmenuTracker.isActive(controller)) {
          _globalSubmenuTracker.closeActive();
        }
      },
      onOpen: () => _globalSubmenuTracker.setActive(controller),
      onClose: () => _globalSubmenuTracker.clearActive(controller),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// showAppMenu — הצגת תפריט במיקום מוחלט
// ═══════════════════════════════════════════════════════════════════════════

Future<T?> showAppMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<AppMenuEntry<T>> entries,
}) {
  final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
      AppMenuMetrics.create(compactMenus: false);
  return showMenu<T>(
    context: context,
    position: position,
    items: entries
        .map<PopupMenuEntry<T>>(
          (entry) => buildAppPopupMenuItem<T>(context, entry, metrics, null),
        )
        .toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AppContextMenuRegion — תפריט הקשר (right-click) בסגנון האפליקציה
//
// שימוש:
//   AppContextMenuRegion(
//     menuBuilder: (context) => [
//       AppContextMenuEntry(label: 'העתק', icon: FluentIcons.copy_24_regular, onTap: ...),
//       const AppContextMenuEntry.divider(),
//       AppContextMenuEntry(
//         label: 'מפרשים',
//         icon: FluentIcons.book_24_regular,
//         children: [...],
//       ),
//     ],
//     child: myWidget,
//   )
// ═══════════════════════════════════════════════════════════════════════════

class AppContextMenuRegion extends StatelessWidget {
  final Widget child;
  final List<AppContextMenuEntry> Function(BuildContext) menuBuilder;

  const AppContextMenuRegion({
    super.key,
    required this.child,
    required this.menuBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.buttons == 2) {
          _showContextMenu(context, event.position);
        }
      },
      child: child,
    );
  }

  Future<void> _showContextMenu(
      BuildContext context, Offset globalPosition) async {
    final entries = menuBuilder(context);
    if (entries.isEmpty) return;

    final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
        AppMenuMetrics.create(compactMenus: false);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // מעקב אחר ה-submenu הפתוח כרגע — לסגירה בעת ריחוף על שורה אחרת
    final submenuTracker = _SubmenuTracker();

    await showMenu<_ContextMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: _buildMenuItems(context, entries, metrics, submenuTracker),
    ).then((action) => action?.call());
  }

  List<PopupMenuEntry<_ContextMenuAction>> _buildMenuItems(
    BuildContext context,
    List<AppContextMenuEntry> entries,
    AppMenuMetrics metrics,
    _SubmenuTracker submenuTracker,
  ) {
    final normalized = _normalizeEntries(entries);
    return normalized.map((entry) {
      if (entry.isDivider) {
        return const PopupMenuDivider();
      }
      if (entry.children != null && entry.children!.isNotEmpty) {
        return _buildSubmenuItem(context, entry, metrics, submenuTracker);
      }
      return _buildMenuItem(context, entry, metrics, submenuTracker);
    }).toList();
  }

  List<AppContextMenuEntry> _normalizeEntries(
      List<AppContextMenuEntry> entries) {
    final result = <AppContextMenuEntry>[];
    for (final e in entries) {
      if (e.isDivider) {
        if (result.isEmpty || result.last.isDivider) continue;
        result.add(e);
      } else {
        result.add(e);
      }
    }
    while (result.isNotEmpty && result.last.isDivider) {
      result.removeLast();
    }
    return result;
  }

  PopupMenuEntry<_ContextMenuAction> _buildMenuItem(
    BuildContext context,
    AppContextMenuEntry entry,
    AppMenuMetrics metrics,
    _SubmenuTracker submenuTracker,
  ) {
    return _NoSplashPopupMenuItem<_ContextMenuAction>(
      value: entry.onTap,
      enabled: entry.enabled,
      height: metrics.itemHeight,
      padding: EdgeInsets.zero,
      child: _AppMenuItemRow(
        onEnter: submenuTracker.closeActive,
        enabled: entry.enabled,
        builder: (isHovered) => _buildAppMenuRowContent(
          context,
          metrics,
          label: entry.label ?? '',
          icon: entry.icon,
          isDestructive: entry.isDestructive,
          enabled: entry.enabled,
          backgroundColor: isHovered
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
              : null,
        ),
      ),
    );
  }

  PopupMenuEntry<_ContextMenuAction> _buildSubmenuItem(
    BuildContext context,
    AppContextMenuEntry entry,
    AppMenuMetrics metrics,
    _SubmenuTracker submenuTracker,
  ) {
    final controller = MenuController();
    final subChildren = entry.children!
        .where((c) => !c.isDivider)
        .map(
          (child) => _buildContextSubmenuChildButton(
            context: context,
            metrics: metrics,
            entry: child,
          ),
        )
        .toList();

    return buildAppCustomPopupMenuItem<_ContextMenuAction>(
      context: context,
      metrics: metrics,
      height: metrics.itemHeight,
      child: _AppSubmenuTriggerButton(
        controller: controller,
        metrics: metrics,
        label: entry.label ?? '',
        icon: entry.icon,
        enabled: entry.enabled,
        isDestructive: entry.isDestructive,
        menuChildren: subChildren,
        onHoverEnter: () {
          if (!submenuTracker.isActive(controller)) {
            submenuTracker.closeActive();
          }
        },
        onOpen: () => submenuTracker.setActive(controller),
        onClose: () => submenuTracker.clearActive(controller),
      ),
    );
  }
}

class _AppSubmenuTriggerButton extends StatefulWidget {
  const _AppSubmenuTriggerButton({
    required this.controller,
    required this.metrics,
    required this.label,
    required this.menuChildren,
    required this.onHoverEnter,
    required this.onOpen,
    required this.onClose,
    this.icon,
    this.enabled = true,
    this.isDestructive = false,
  });

  final MenuController controller;
  final AppMenuMetrics metrics;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool isDestructive;
  final List<Widget> menuChildren;
  final VoidCallback onHoverEnter;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  State<_AppSubmenuTriggerButton> createState() =>
      _AppSubmenuTriggerButtonState();
}

class _AppSubmenuTriggerButtonState extends State<_AppSubmenuTriggerButton> {
  bool _isHovered = false;
  bool _isSubmenuOpen = false;

  void _handleOpen() {
    if (!_isSubmenuOpen) {
      setState(() => _isSubmenuOpen = true);
    }
    widget.onOpen();
  }

  void _handleClose() {
    if (_isSubmenuOpen) {
      setState(() => _isSubmenuOpen = false);
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _resolveAppMenuForegroundColor(
      context,
      enabled: widget.enabled,
      isDestructive: widget.isDestructive,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = (_isHovered || _isSubmenuOpen) && widget.enabled
        ? colorScheme.onSurface.withValues(alpha: 0.08)
        : null;

    return MouseRegion(
      onEnter: (_) {
        widget.onHoverEnter();
        if (!_isHovered) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (_isHovered) {
          setState(() => _isHovered = false);
        }
      },
      child: SubmenuButton(
        controller: widget.controller,
        menuChildren: widget.menuChildren,
        style: buildAppSubmenuItemStyle(
          context,
          widget.metrics,
          isDestructive: widget.isDestructive,
          enabled: widget.enabled,
        ),
        menuStyle: buildAppSubmenuMenuStyle(context),
        onOpen: _handleOpen,
        onClose: _handleClose,
        leadingIcon: null,
        trailingIcon: null,
        child: _buildAppMenuRowContent(
          context,
          widget.metrics,
          label: widget.label,
          icon: widget.icon,
          trailing: RtlIcon(
            FluentIcons.chevron_left_24_regular,
            size: widget.metrics.iconSize,
            color: foregroundColor,
          ),
          enabled: widget.enabled,
          isDestructive: widget.isDestructive,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          fontWeight: widget.metrics.itemFontWeight,
        ),
      ),
    );
  }
}

MenuItemButton _buildContextSubmenuChildButton({
  required BuildContext context,
  required AppMenuMetrics metrics,
  required AppContextMenuEntry entry,
}) {
  final foregroundColor = WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return _resolveAppMenuForegroundColor(context, enabled: false);
    }
    return _resolveAppMenuForegroundColor(
      context,
      enabled: entry.enabled,
      isDestructive: entry.isDestructive,
    );
  });
  return MenuItemButton(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll(
          Size(metrics.menuMinWidth, metrics.itemHeight)),
      alignment: Alignment.centerRight,
      visualDensity: metrics.visualDensity,
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      foregroundColor: foregroundColor,
      iconColor: foregroundColor,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    onPressed: entry.enabled ? entry.onTap : null,
    child: _AppMenuItemRow(
      onEnter: () {},
      enabled: entry.enabled,
      builder: (isHovered) => _buildAppMenuRowContent(
        context,
        metrics,
        label: entry.label ?? '',
        icon: entry.icon,
        enabled: entry.enabled,
        isDestructive: entry.isDestructive,
        backgroundColor: isHovered
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)
            : null,
      ),
    ),
  );
}

final _globalSubmenuTracker = _SubmenuTracker();

/// מעקב אחר ה-SubmenuButton הפתוח כרגע — מאפשר סגירה ב-hover על שורה אחרת.
class _SubmenuTracker {
  MenuController? _active;

  void setActive(MenuController c) => _active = c;

  void clearActive(MenuController c) {
    if (_active == c) _active = null;
  }

  bool isActive(MenuController c) => _active == c;

  void closeActive() {
    _active?.close();
    _active = null;
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// טיפוס פנימי — callback של פריט תפריט הקשר
typedef _ContextMenuAction = VoidCallback?;

// ═══════════════════════════════════════════════════════════════════════════
// AppSelectionField — שדה-בחירה (trigger לתפריט נפתח)
//
// עיצוב: זהה לשורת הטריגר של DropdownMenu עם חיפוש
// • ללא גבול במצב רגיל
// • גבול עדין בעת hover
// ═══════════════════════════════════════════════════════════════════════════

const double _dropdownFieldRadius = AppInputTokens.compactRadius;
const double _dropdownFieldIdleFillAlpha = AppInputTokens.unfocusedAlpha;
const double _dropdownFieldDisabledFillAlpha = AppInputTokens.disabledAlpha;
const double _dropdownFieldHoverFillAlpha = 0.10;
const double _dropdownFieldBorderWidth = 1.4;
const double _dropdownFieldMinHeight = 40.0;
const EdgeInsets _dropdownFieldContentPadding =
    EdgeInsets.symmetric(horizontal: 10, vertical: 5);

Color _dropdownFieldBorderColor(BuildContext context) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return theme.brightness == Brightness.light
      ? cs.primary.withValues(alpha: 0.22)
      : cs.primary.withValues(alpha: 0.40);
}

class AppSelectionField extends StatefulWidget {
  final Widget child;
  final InputDecoration? decoration;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool isSelected;
  final FocusNode? focusNode;

  /// `null` = ברירת מחדל (40px/20px), `true` = compact (36px/20px), `false` = רגיל (48px/28px)
  final bool? slim;

  const AppSelectionField({
    super.key,
    required this.child,
    this.decoration,
    this.enabled = true,
    this.onTap,
    this.leading,
    this.isSelected = false,
    this.focusNode,
    this.slim,
  });

  @override
  State<AppSelectionField> createState() => _AppSelectionFieldState();
}

class _AppSelectionFieldState extends State<AppSelectionField> {
  bool _isHovering = false;
  bool _isFocused = false;

  static const Duration _animDuration = Duration(milliseconds: 120);

  double get _effectiveRadius =>
      widget.slim == false ? 28.0 : _dropdownFieldRadius;

  double get _effectiveMinHeight {
    if (widget.slim == false) return 48.0;
    if (widget.slim == true) return 36.0;
    return _dropdownFieldMinHeight;
  }

  BoxDecoration _buildFieldDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = _effectiveRadius;

    if (_isFocused && widget.enabled) {
      return BoxDecoration(
        color: cs.onSurface.withValues(alpha: _dropdownFieldHoverFillAlpha),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: _dropdownFieldBorderColor(context),
          width: _dropdownFieldBorderWidth,
        ),
      );
    }
    if (_isHovering && widget.enabled) {
      return BoxDecoration(
        color: cs.onSurface.withValues(alpha: _dropdownFieldHoverFillAlpha),
        borderRadius: BorderRadius.circular(r),
      );
    }
    return BoxDecoration(
      color: cs.onSurface.withValues(
        alpha: widget.enabled
            ? _dropdownFieldIdleFillAlpha
            : _dropdownFieldDisabledFillAlpha,
      ),
      borderRadius: BorderRadius.circular(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentPadding =
        widget.decoration?.contentPadding ?? _dropdownFieldContentPadding;

    final content = Padding(
      padding: contentPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 8),
          ],
          Flexible(child: widget.child),
          // ללא חץ — המראה הוויזואלי של הכרטיס מספיק כ-affordance
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOut,
        decoration: _buildFieldDecoration(context),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            focusNode: widget.focusNode,
            canRequestFocus: widget.enabled,
            onFocusChange: (isFocused) {
              if (_isFocused != isFocused) {
                setState(() => _isFocused = isFocused);
              }
            },
            borderRadius: BorderRadius.circular(_effectiveRadius),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: _effectiveMinHeight),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AppDropdownField — שדה בחירה עם תפריט נפתח
//
// • enableSearch: false → AppSelectionField + popup menu
// • enableSearch: true  → DropdownMenu עם חיפוש + auto-select בפתיחה
//   ההבדל היחיד: האם ניתן להקליד ולסנן
// ═══════════════════════════════════════════════════════════════════════════

class AppDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<AppMenuEntry<T>> entries;
  final ValueChanged<T?>? onSelected;
  final InputDecoration? decoration;
  final bool enabled;
  final bool isExpanded;
  final bool enableSearch;
  final Widget Function(BuildContext context, T? value)? selectedBuilder;
  final String Function(T value)? labelBuilder;

  const AppDropdownField({
    super.key,
    required this.value,
    required this.entries,
    required this.onSelected,
    this.decoration,
    this.enabled = true,
    this.isExpanded = true,
    this.enableSearch = false,
    this.selectedBuilder,
    this.labelBuilder,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final GlobalKey _selectionAnchorKey = GlobalKey();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final MenuController _menuController;
  String _menuVisibleText = '';
  bool _isSyncingControllerText = false;
  bool _restoreTextAfterNavigation = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedLabel);
    _controller.addListener(_handleControllerChanged);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _menuController = MenuController();
    _menuVisibleText = _controller.text;
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.entries != widget.entries) {
      _setControllerText(_selectedLabel);
      _menuVisibleText = _selectedLabel;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_isSyncingControllerText) return;

    if (widget.enableSearch &&
        _restoreTextAfterNavigation &&
        _menuController.isOpen) {
      _restoreTextAfterNavigation = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_menuController.isOpen) return;
        _setControllerText(
          _menuVisibleText,
          selection: TextSelection.collapsed(offset: _menuVisibleText.length),
        );
      });
      return;
    }

    _menuVisibleText = _controller.text;
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      // בחירת כל הטקסט אוטומטית בפתיחה — סעיף 6
      Future.microtask(() {
        if (mounted && _focusNode.hasFocus) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
          _menuVisibleText = _controller.text;
        }
      });
      return;
    }
    if (_controller.text != _selectedLabel) {
      _restoreSelectedText();
    }
  }

  void _restoreSelectedText() {
    final selectedLabel = _selectedLabel;
    _setControllerText(selectedLabel);
    _menuVisibleText = selectedLabel;
  }

  void _setControllerText(
    String text, {
    TextSelection? selection,
  }) {
    _isSyncingControllerText = true;
    _controller.value = TextEditingValue(
      text: text,
      selection: selection ?? TextSelection.collapsed(offset: text.length),
    );
    _isSyncingControllerText = false;
  }

  String get _selectedLabel {
    if (widget.value == null) return '';
    for (final entry in widget.entries) {
      if (entry.value == widget.value) return entry.label;
    }
    if (widget.labelBuilder != null) {
      return widget.labelBuilder!(widget.value as T);
    }
    return '';
  }

  AppMenuEntry<T>? get _selectedEntry {
    if (widget.value == null) return null;
    for (final entry in widget.entries) {
      if (entry.value == widget.value) return entry;
    }
    return null;
  }

  Future<void> _openSelectionMenu() async {
    if (!widget.enabled ||
        widget.onSelected == null ||
        widget.entries.isEmpty) {
      return;
    }
    final anchorContext = _selectionAnchorKey.currentContext;
    if (anchorContext == null) return;

    final selected = await showAnchoredAppMenu<T>(
      context: context,
      anchorContext: anchorContext,
      offset: const Offset(0, 4),
      itemsBuilder: (metrics) => widget.entries
          .map<PopupMenuEntry<T>>(
            (entry) => buildAppPopupMenuItem<T>(
              context,
              entry,
              metrics,
              widget.value,
            ),
          )
          .toList(),
    );

    if (!mounted) return;

    _focusNode.requestFocus();
    if (selected != null) {
      widget.onSelected?.call(selected);
    }
  }

  void _openSearchMenu() {
    if (!_menuController.isOpen) {
      _menuVisibleText = _controller.text;
      _menuController.open();
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  KeyEventResult _handleSearchFieldKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final isActivateKey = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;

    if (!_menuController.isOpen &&
        (key == LogicalKeyboardKey.space || isActivateKey)) {
      _openSearchMenu();
      return KeyEventResult.handled;
    }

    if (_menuController.isOpen &&
        (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowUp)) {
      _menuVisibleText = _controller.text;
      _restoreTextAfterNavigation = true;
      return KeyEventResult.ignored;
    }

    if (_menuController.isOpen && key == LogicalKeyboardKey.escape) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _menuController.isOpen) return;
        _restoreSelectedText();
        _focusNode.requestFocus();
      });
    }

    return KeyEventResult.ignored;
  }

  InputDecorationTheme _buildDecorationTheme(
    BuildContext context,
    AppMenuMetrics metrics,
  ) {
    final cs = Theme.of(context).colorScheme;
    final borderColor = _dropdownFieldBorderColor(context);
    final isCompact = metrics.compactMenus;
    final r = AppInputTokens.radius(isCompact);
    final minH = AppInputTokens.height(isCompact);

    return InputDecorationTheme(
      filled: true,
      fillColor: cs.onSurface.withValues(
        alpha: widget.enabled
            ? AppInputTokens.unfocusedAlpha
            : AppInputTokens.disabledAlpha,
      ),
      isDense: true,
      contentPadding: _dropdownFieldContentPadding,
      constraints: BoxConstraints(minHeight: minH),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide(
          color: borderColor,
          width: _dropdownFieldBorderWidth,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: metrics.fontSize,
      ),
    );
  }

  InputDecoration _buildSearchFieldDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFocus = _focusNode.hasFocus;

    // קבלת metrics כדי לדעת אם compact
    final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
        AppMenuMetrics.create(compactMenus: false);
    final isCompact = metrics.compactMenus;

    // גובה, פונט ורדיוס תלויים ב-compact mode - משתמשים ב-AppInputTokens
    final fieldHeight = AppInputTokens.height(isCompact);
    final fieldFontSize = AppInputTokens.fontSize(isCompact);
    final fieldRadius = AppInputTokens.radius(isCompact);
    final iconSize = AppInputTokens.iconSize(isCompact);
    final minWidth = AppInputTokens.prefixMinWidth(isCompact);

    return InputDecoration(
      hintText: widget.decoration?.hintText ?? widget.decoration?.labelText,
      hintStyle: TextStyle(
        fontSize: fieldFontSize,
        color: cs.onSurfaceVariant,
        height: 1.0,
      ),
      filled: true,
      isDense: true,
      fillColor: hasFocus
          ? cs.primary.withValues(alpha: AppInputTokens.focusedAlpha)
          : cs.onSurface.withValues(alpha: AppInputTokens.unfocusedAlpha),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceXS, vertical: 0),
      constraints: BoxConstraints(minHeight: fieldHeight),
      prefixIcon: Icon(
        FluentIcons.search_24_regular,
        size: iconSize,
        color: hasFocus ? cs.primary : cs.onSurfaceVariant,
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: fieldHeight,
      ),
      suffixIcon: const SizedBox.shrink(),
      suffixIconConstraints: BoxConstraints(
        minWidth: AppInputTokens.suffixMinWidth(isCompact),
        minHeight: fieldHeight,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
        AppMenuMetrics.create(compactMenus: false);
    final isCompact = metrics.compactMenus;
    final effectiveEnabled = widget.enabled &&
        widget.onSelected != null &&
        widget.entries.isNotEmpty;
    final cs = Theme.of(context).colorScheme;
    final width = widget.isExpanded ? double.infinity : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth =
            width == double.infinity && constraints.hasBoundedWidth
                ? constraints.maxWidth
                : width;

        // ── מצב ללא חיפוש: AppSelectionField + popup ──────────────────────
        if (!widget.enableSearch) {
          final selectedEntry = _selectedEntry;
          final displayText =
              widget.selectedBuilder?.call(context, widget.value) ??
                  Text(
                    _selectedLabel,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: metrics.fontSize,
                      fontWeight: metrics.itemFontWeight,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                  );

          final fieldContent = selectedEntry?.icon == null
              ? displayText
              : Row(
                  children: [
                    Icon(
                      selectedEntry!.icon,
                      size: metrics.iconSize,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: displayText),
                  ],
                );

          return SizedBox(
            width: resolvedWidth,
            child: KeyedSubtree(
              key: _selectionAnchorKey,
              child: AppSelectionField(
                enabled: effectiveEnabled,
                focusNode: _focusNode,
                onTap: _openSelectionMenu,
                decoration: widget.decoration,
                isSelected: widget.value != null,
                slim: isCompact ? true : false,
                child: SizedBox(
                  width: double.infinity,
                  child: fieldContent,
                ),
              ),
            ),
          );
        }

        // ── מצב עם חיפוש: DropdownMenu ────────────────────────────────────
        return SizedBox(
          width: resolvedWidth,
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: _handleSearchFieldKeyEvent,
            child: DropdownMenu<T>(
              controller: _controller,
              focusNode: _focusNode,
              menuController: _menuController,
              enabled: effectiveEnabled,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap:
                  true, // auto-select בפתיחה (דרך _handleFocusChanged)
              initialSelection: widget.value,
              menuHeight:
                  (metrics.itemHeight * 8) + metrics.menuPadding.vertical,
              width: resolvedWidth,
              alignmentOffset: const Offset(0, 4),
              showTrailingIcon: false,
              textStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: AppInputTokens.fontSize(metrics.compactMenus),
                fontWeight: metrics.itemFontWeight,
                color: cs.onSurface,
                height: 1.0,
              ),
              inputDecorationTheme: _buildDecorationTheme(context, metrics),
              decorationBuilder: (context, _) =>
                  _buildSearchFieldDecoration(context),
              leadingIcon: null,
              trailingIcon: null,
              selectedTrailingIcon: null,
              dropdownMenuEntries: widget.entries.map((entry) {
                final isSelected = entry.value == widget.value;
                return DropdownMenuEntry<T>(
                  value: entry.value,
                  label: entry.label,
                  labelWidget: _buildAppMenuRowContent(
                    context,
                    metrics,
                    label: entry.label,
                    icon: entry.icon,
                    trailing: entry.trailing,
                    isSelected: isSelected,
                    isDestructive: entry.isDestructive,
                  ),
                  enabled: entry.enabled,
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    minimumSize: WidgetStatePropertyAll(
                      Size(metrics.menuMinWidth, metrics.itemHeight),
                    ),
                    shape: const WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                );
              }).toList(),
              onSelected: (value) {
                if (value == null) {
                  _restoreSelectedText();
                  return;
                }
                final selectedEntry = widget.entries
                    .where((entry) => entry.value == value)
                    .firstOrNull;
                _menuVisibleText = selectedEntry?.label ?? _selectedLabel;
                widget.onSelected?.call(value);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _focusNode.requestFocus();
                });
              },
            ),
          ),
        );
      },
    );
  }
}
