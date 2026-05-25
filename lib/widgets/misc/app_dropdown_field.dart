import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/widgets/misc/app_popup_menu.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AppSelectionField — שדה-בחירה (trigger לתפריט נפתח)
//
// עיצוב: FilledButton.tonal קומפקטי — זהה ל-NeutralActionButton
// • secondaryContainer / onSecondaryContainer — אוטומטי מהתמה
// • hover / press / focus / disabled מנוהלים ע"י ButtonStyle (M3)
// • גובה מינימלי 32dp, IntrinsicWidth כשלא מורחב
// ═══════════════════════════════════════════════════════════════════════════


class AppSelectionField extends StatelessWidget {
  final Widget child;
  final InputDecoration? decoration;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool isExpanded;

  const AppSelectionField({
    super.key,
    required this.child,
    this.decoration,
    this.enabled = true,
    this.onTap,
    this.leading,
    this.trailing,
    this.focusNode,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        child,
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );

    return FilledButton.tonal(
      onPressed: enabled ? onTap : null,
      focusNode: focusNode,
      style: FilledButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: row,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AppDropdownField — שדה בחירה עם תפריט נפתח
//
// • enableSearch: false → AppSelectionField + popup menu
// • enableSearch: true  → popup menu עם חיפוש + auto-select בפתיחה
// • isExpanded: false (ברירת מחדל) → IntrinsicWidth — רוחב לפי תוכן
// • isExpanded: true → מתרחב למלא את רוחב ההורה
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
    this.isExpanded = false,
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
  bool _isMenuOpen = false;

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

  void _setControllerText(String text, {TextSelection? selection}) {
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

    setState(() => _isMenuOpen = true);

    final Future<T?> menuFuture = widget.enableSearch
        ? showAnchoredAppSearchMenu<T>(
            context: context,
            anchorContext: anchorContext,
            entries: widget.entries,
            initialValue: widget.value,
            searchHint: widget.decoration?.hintText ??
                widget.decoration?.labelText ??
                'חיפוש',
          )
        : showAnchoredAppMenu<T>(
            context: context,
            anchorContext: anchorContext,
            initialValue: widget.value,
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
    final selected = await menuFuture;

    if (!mounted) return;

    setState(() => _isMenuOpen = false);
    _focusNode.requestFocus();
    if (selected != null) {
      widget.onSelected?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = Theme.of(context).extension<AppMenuMetrics>() ??
        AppMenuMetrics.create(compactMenus: false);
    final effectiveEnabled = widget.enabled &&
        widget.onSelected != null &&
        widget.entries.isNotEmpty;
    final cs = Theme.of(context).colorScheme;

    final selectedEntry = _selectedEntry;
    final displayText = widget.selectedBuilder?.call(context, widget.value) ??
        Text(
          _selectedLabel,
          style: TextStyle(
            fontSize: metrics.fontSize,
            fontWeight: metrics.itemFontWeight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );

    final fieldContent = selectedEntry?.icon == null
        ? displayText
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedEntry!.icon,
                size: metrics.iconSize,
                color: cs.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              displayText,
            ],
          );

    final chevron = AnimatedRotation(
      turns: _isMenuOpen ? 0.5 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        FluentIcons.chevron_down_24_regular,
        size: 16,
        color: cs.onSecondaryContainer,
      ),
    );

    final field = KeyedSubtree(
      key: _selectionAnchorKey,
      child: AppSelectionField(
        enabled: effectiveEnabled,
        focusNode: _focusNode,
        onTap: _openSelectionMenu,
        decoration: widget.decoration,
        trailing: chevron,
        isExpanded: widget.isExpanded,
        child: fieldContent,
      ),
    );

    if (widget.isExpanded) {
      return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          child: field,
        ),
      );
    }
    return IntrinsicWidth(child: field);
  }
}
