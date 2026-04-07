import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/core/focus_repository.dart';
import 'package:otzaria/settings/settings_exports.dart';
import 'package:otzaria/shortcuts/shortcut_helper.dart';
import 'package:otzaria/shortcuts/shortcut_validator.dart';
import 'package:otzaria/widgets/otzaria_search_field.dart';
import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/tools/acronyms_dictionary/widgets/acronym_result_card.dart';
import 'package:otzaria/tools/dictionary/repository/dictionary_lookup_repository.dart';
import 'package:otzaria/widgets/keyboard_list_focus.dart';
import 'package:otzaria/widgets/tool_empty_state.dart';
import 'package:otzaria/widgets/tool_ui_helpers.dart';
import 'package:otzaria/widgets/app_top_bar.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;

class AcronymsDictionaryScreen extends StatefulWidget {
  const AcronymsDictionaryScreen({super.key});

  @override
  State<AcronymsDictionaryScreen> createState() =>
      _AcronymsDictionaryScreenState();
}

class _AcronymsDictionaryScreenState extends State<AcronymsDictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DictionaryLookupRepository _dictionaryRepository =
      DictionaryLookupRepository.instance;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _listFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late final KeyboardListFocusController _keyboardListFocus;

  Map<String, List<String>> _dictionaryData = {};
  List<MapEntry<String, List<String>>> _filteredResults = [];
  bool _isLoading = true;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _keyboardListFocus = KeyboardListFocusController(
      scrollController: _scrollController,
      estimatedItemExtent: 52,
    );
    _loadDictionary();
    _searchController.addListener(_performSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchField());
  }

  /// מבקש פוקוס לרשימת ראשי התיבות.
  void requestKeyboardFocus() {
    _focusSearchField();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _focusSearchField() {
    if (!mounted || !_searchFocusNode.canRequestFocus) return;
    requestFocusIfNeeded(_searchFocusNode);
  }

  void _focusResultsList() {
    if (!mounted || !_listFocusNode.canRequestFocus) return;
    requestFocusIfNeeded(_listFocusNode);
  }

  void _scrollResults({required bool forward}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final delta = (position.viewportDimension * 0.85) * (forward ? 1 : -1);
    final target =
        (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadDictionary() async {
    try {
      await _dictionaryRepository.ensureAcronymsLoaded();

      if (!mounted) return;

      setState(() {
        _dictionaryData = _dictionaryRepository.getAllAcronyms();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UiSnack.showError('שגיאה בטעינת המילון: $e');
    }
  }

  void _performSearch({bool moveFocusToResults = false}) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredResults = [];
        _focusedIndex = _keyboardListFocus.reset();
      });
      return;
    }

    setState(() {
      _filteredResults = _dictionaryData.entries
          .where((entry) =>
              _dictionaryRepository.acronymMatchesQuery(
                acronym: entry.key,
                query: query,
              ) ||
              entry.value.any((meaning) => _normalizedContains(meaning, query)))
          .toList()
        ..sort((a, b) {
          final rankCompare = _compareSearchRelevance(
            left: a,
            right: b,
            query: query,
          );
          if (rankCompare != 0) {
            return rankCompare;
          }

          final lengthCompare = a.key.length.compareTo(b.key.length);
          if (lengthCompare != 0) {
            return lengthCompare;
          }

          return a.key.compareTo(b.key);
        });
      _focusedIndex = _keyboardListFocus.reset(
        setToFirstWhenNotEmpty: true,
        itemCount: _filteredResults.length,
      );
    });

    if (moveFocusToResults && _filteredResults.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusResultsList());
    }
  }

  int _compareSearchRelevance({
    required MapEntry<String, List<String>> left,
    required MapEntry<String, List<String>> right,
    required String query,
  }) {
    final leftRank = _searchRank(left, query);
    final rightRank = _searchRank(right, query);
    return leftRank.compareTo(rightRank);
  }

  int _searchRank(MapEntry<String, List<String>> entry, String query) {
    final normalizedAcronym = _normalizeAcronym(entry.key);
    final normalizedAcronymQuery = _normalizeAcronym(query);
    final normalizedMeaningQuery = _normalizeSearchText(query);

    if (normalizedAcronym == normalizedAcronymQuery) {
      return 0;
    }
    if (normalizedAcronym.startsWith(normalizedAcronymQuery)) {
      return 1;
    }
    if (normalizedAcronym.contains(normalizedAcronymQuery)) {
      return 2;
    }

    final normalizedMeanings = entry.value.map(_normalizeSearchText).toList();
    if (normalizedMeanings.any((meaning) => meaning == normalizedMeaningQuery)) {
      return 3;
    }
    if (normalizedMeanings
        .any((meaning) => meaning.startsWith(normalizedMeaningQuery))) {
      return 4;
    }
    if (normalizedMeanings
        .any((meaning) => meaning.contains(normalizedMeaningQuery))) {
      return 5;
    }

    return 6;
  }

  bool _normalizedContains(String value, String query) {
    return _normalizeSearchText(value).contains(_normalizeSearchText(query));
  }

  String _normalizeAcronym(String value) {
    return _normalizeSearchText(value)
        .replaceAll('״', '"')
        .replaceAll('׳', "'")
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  String _normalizeSearchText(String value) {
    return utils.removeVolwels(value).trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _moveFocus(int delta) {
    if (_filteredResults.isEmpty) return;
    setState(() {
      _focusedIndex = _keyboardListFocus.moveFocus(
        delta: delta,
        itemCount: _filteredResults.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final searchShortcutSetting = context.select(
      (SettingsBloc bloc) =>
          bloc.state.shortcuts['key-shortcut-search-current-window'] ??
          ShortcutValidator
              .defaultShortcuts['key-shortcut-search-current-window'] ??
          'ctrl+f',
    );
    return CallbackShortcuts(
      bindings: {
        ShortcutHelper.activatorFromShortcut(searchShortcutSetting) ??
            const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          _searchFocusNode.requestFocus();
        },
      },
      child: Focus(
        focusNode: _listFocusNode,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.pageDown) {
            _scrollResults(forward: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.pageUp) {
            _scrollResults(forward: false);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveFocus(1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveFocus(-1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) => AppTopBar(
                center: OtzariaSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'חפש ראשי תיבות...',
                  autofocus: true,
                  onSubmitted: (_) => _performSearch(moveFocusToResults: true),
                  onClear: () => setState(() {
                    _filteredResults = [];
                    _focusedIndex = -1;
                  }),
                ),
              ),
            ),
            Expanded(
              child: ToolPanelWrapper(
                child: _buildResultsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchController.text.isEmpty) {
      return const ToolEmptyState(
        icon: FluentIcons.text_quote_24_regular,
        message: 'הזן ראשי תיבות לחיפוש במילון',
      );
    }

    if (_filteredResults.isEmpty) {
      return const ToolEmptyState(
        icon: FluentIcons.search_24_regular,
        message: 'לא נמצאו תוצאות',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final entry = _filteredResults[index];
        return AcronymResultCard(
          acronym: entry.key,
          meanings: entry.value,
          isFocused: _focusedIndex == index,
          onTap: () => setState(() {
            _focusedIndex = index;
            _keyboardListFocus.focusedIndex = index;
          }),
        );
      },
    );
  }
}
