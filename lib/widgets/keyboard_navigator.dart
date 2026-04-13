import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/widgets/rtl_icon.dart';

/// Widget גנרי לניהול ניווט מקלדת
/// תומך ב-Ctrl+Tab / Ctrl+Shift+Tab למעבר בין טאבים
/// ומאפשר ניווט עם חיצים ו-Tab בתוך תוכן הטאב
class KeyboardNavigator extends StatelessWidget {
  final Widget child;
  final int currentTabIndex;
  final int totalTabs;
  final ValueChanged<int> onTabChange;
  final FocusNode? contentFocusNode;
  final VoidCallback? onBack;

  const KeyboardNavigator({
    super.key,
    required this.child,
    required this.currentTabIndex,
    required this.totalTabs,
    required this.onTabChange,
    this.contentFocusNode,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        // Escape - חזרה (אם מוגדר callback)
        if (event.logicalKey == LogicalKeyboardKey.escape && onBack != null) {
          onBack!();
          return KeyEventResult.handled;
        }

        // Ctrl + Tab - טאב הבא
        if (event.logicalKey == LogicalKeyboardKey.tab &&
            HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isShiftPressed) {
          final nextIndex = (currentTabIndex + 1) % totalTabs;
          onTabChange(nextIndex);
          return KeyEventResult.handled;
        }

        // Ctrl + Shift + Tab - טאב קודם
        if (event.logicalKey == LogicalKeyboardKey.tab &&
            HardwareKeyboard.instance.isControlPressed &&
            HardwareKeyboard.instance.isShiftPressed) {
          final prevIndex = (currentTabIndex - 1 + totalTabs) % totalTabs;
          onTabChange(prevIndex);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

class MobileNavigationItem<T> {
  final T value;
  final String label;
  final Widget leading;

  const MobileNavigationItem({
    required this.value,
    required this.label,
    required this.leading,
  });
}

class MobileNavigationGroup<T> {
  final String label;
  final List<T> values;

  const MobileNavigationGroup({
    required this.label,
    required this.values,
  });
}

class GroupedMobileNavigationList<T> extends StatefulWidget {
  final List<MobileNavigationItem<T>> items;
  final List<MobileNavigationGroup<T>> groups;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;
  final T? initialFocusValue;

  const GroupedMobileNavigationList({
    super.key,
    required this.items,
    required this.groups,
    required this.onSelected,
    this.padding = const EdgeInsets.all(12),
    this.initialFocusValue,
  });

  @override
  State<GroupedMobileNavigationList<T>> createState() =>
      _GroupedMobileNavigationListState<T>();
}

class _GroupedMobileNavigationListState<T>
    extends State<GroupedMobileNavigationList<T>> {
  late List<FocusNode> _focusNodes;
  late Map<T, int> _indexByValue;

  @override
  void initState() {
    super.initState();
    _rebuildFocusState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
  }

  @override
  void didUpdateWidget(covariant GroupedMobileNavigationList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        !_sameValues(oldWidget.items, widget.items)) {
      for (final node in _focusNodes) {
        node.dispose();
      }
      _rebuildFocusState();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _requestInitialFocus());
    }
  }

  bool _sameValues(
    List<MobileNavigationItem<T>> oldItems,
    List<MobileNavigationItem<T>> newItems,
  ) {
    if (oldItems.length != newItems.length) return false;
    for (var i = 0; i < oldItems.length; i++) {
      if (oldItems[i].value != newItems[i].value) return false;
    }
    return true;
  }

  void _rebuildFocusState() {
    _focusNodes = List.generate(
      widget.items.length,
      (_) => FocusNode(debugLabel: 'groupedMobileNavigationItem'),
    );
    _indexByValue = {
      for (var i = 0; i < widget.items.length; i++) widget.items[i].value: i,
    };
  }

  void _requestInitialFocus() {
    if (!mounted || _focusNodes.isEmpty) return;
    final targetIndex = widget.initialFocusValue != null
        ? (_indexByValue[widget.initialFocusValue!] ?? 0)
        : 0;
    final focusNode = _focusNodes[targetIndex];
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }

  void _focusSibling(int currentIndex, int offset) {
    final nextIndex = (currentIndex + offset).clamp(0, _focusNodes.length - 1);
    _focusNodes[nextIndex].requestFocus();
  }

  Widget _buildTile(MobileNavigationItem<T> item, int index) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _focusSibling(index, 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _focusSibling(index, -1),
      },
      child: FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: ListTile(
          focusNode: _focusNodes[index],
          leading: item.leading,
          title: Text(item.label),
          trailing: const RtlIcon(Icons.chevron_left),
          onTap: () => widget.onSelected(item.value),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: ListView(
        padding: widget.padding,
        children: [
          for (final group in widget.groups) ...[
            SettingsCard(
              title: group.label,
              children: [
                for (final value in group.values)
                  _buildTile(
                    widget.items[_indexByValue[value]!],
                    _indexByValue[value]!,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
