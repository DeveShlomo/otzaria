import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Tab data for [SideSheetHeader].
class SideSheetTab {
  final IconData icon;
  final String? label;

  const SideSheetTab({required this.icon, this.label});
}

/// M3 secondary-style tab bar header for a side sheet.
///
/// Renders a [TabBar] with an [outlineVariant] divider below it and an
/// optional close [IconButton] on the leading edge.
class SideSheetHeader extends StatelessWidget {
  final TabController controller;
  final List<SideSheetTab> tabs;
  final VoidCallback? onClose;
  final List<Widget> extraActions;

  const SideSheetHeader({
    super.key,
    required this.controller,
    required this.tabs,
    this.onClose,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final tabBar = TabBar(
      controller: controller,
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      indicatorColor: cs.primary,
      tabs: tabs
          .map(
            (t) => t.label != null
                ? Tab(
                    height: 48,
                    icon: Icon(t.icon, size: 20),
                    iconMargin: const EdgeInsets.only(bottom: 2),
                    text: t.label,
                  )
                : Tab(height: 48, icon: Icon(t.icon, size: 20)),
          )
          .toList(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (onClose != null)
              IconButton(
                icon: const Icon(FluentIcons.dismiss_24_regular),
                iconSize: 20,
                tooltip: 'סגור',
                onPressed: onClose,
              ),
            Expanded(child: tabBar),
            ...extraActions,
          ],
        ),
        Divider(height: 1, thickness: 1, color: cs.outlineVariant),
      ],
    );
  }
}

/// M3 Standard Side Sheet.
///
/// Co-exists with main content (no scrim/overlay). Slides in/out from the
/// side using an [AnimatedContainer]. Content state is preserved while
/// hidden via [ClipRect] + [OverflowBox].
class SideSheet extends StatefulWidget {
  final bool isOpen;
  final Widget mainContent;

  /// Side-sheet content — typically a [SideSheetScaffold].
  final Widget content;

  final double width;
  final VoidCallback onClose;
  final AlignmentDirectional alignment;

  const SideSheet({
    super.key,
    required this.isOpen,
    required this.mainContent,
    required this.content,
    this.width = 320,
    required this.onClose,
    this.alignment = AlignmentDirectional.centerEnd,
  });

  @override
  State<SideSheet> createState() => _SideSheetState();
}

class _SideSheetState extends State<SideSheet> {
  bool _everOpened = false;

  @override
  void initState() {
    super.initState();
    _everOpened = widget.isOpen;
  }

  @override
  void didUpdateWidget(SideSheet old) {
    super.didUpdateWidget(old);
    if (widget.isOpen && !_everOpened) {
      setState(() => _everOpened = true);
    }
  }

  bool _paneOnRight(BuildContext context) {
    if (widget.alignment == AlignmentDirectional.centerEnd) return true;
    if (widget.alignment == AlignmentDirectional.centerStart) return false;
    return widget.alignment.resolve(Directionality.of(context)).x >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onRight = _paneOnRight(context);

    // פינות מעוגלות 28dp (shape token של M3) רק בצד הפנימי (הפונה לתוכן הראשי)
    final borderRadius = BorderRadius.only(
      topLeft: onRight ? const Radius.circular(28) : Radius.zero,
      bottomLeft: onRight ? const Radius.circular(28) : Radius.zero,
      topRight: onRight ? Radius.zero : const Radius.circular(28),
      bottomRight: onRight ? Radius.zero : const Radius.circular(28),
    );

    final paneSlot = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      width: widget.isOpen ? widget.width : 0,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: widget.width,
          minWidth: 0,
          alignment:
              onRight ? Alignment.centerRight : Alignment.centerLeft,
          child: _everOpened
              ? SizedBox(
                  width: widget.width,
                  child: Material(
                    color: cs.surfaceContainerLow,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: borderRadius,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.content,
                  ),
                )
              : null,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: onRight
          ? [paneSlot, Expanded(child: widget.mainContent)]
          : [Expanded(child: widget.mainContent), paneSlot],
    );
  }
}
