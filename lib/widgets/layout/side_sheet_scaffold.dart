import 'package:flutter/material.dart';

/// Base scaffold for side sheet content, following the Material 3 side sheet
/// component spec (standard and modal variants).
///
/// Provides the standard internal column structure:
///   header (optional) → body (fills remaining space).
///
/// The outer container (elevation, rounded corners, surface color) is provided
/// by the parent — typically [AdaptiveSidePane].
///
/// Usage:
/// ```dart
/// SideSheetScaffold(
///   header: PanelTabHeader(controller: ..., tabs: [...], onClose: ...),
///   body: TabBarView(controller: ..., children: [...]),
/// )
/// ```
class SideSheetScaffold extends StatelessWidget {
  /// Optional header shown at the top of the sheet.
  /// Typically a [PanelTabHeader] (TabBar + close/action buttons).
  final Widget? header;

  /// Main content of the sheet, fills all remaining vertical space.
  final Widget body;

  const SideSheetScaffold({
    super.key,
    this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        Expanded(child: body),
      ],
    );
  }
}
