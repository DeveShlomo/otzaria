import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/memory_cache_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';
import 'package:otzaria/workspaces/workspace.dart';
import 'package:otzaria/workspaces/workspace_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceBloc tab isolation', () {
    setUp(() async {
      await setUpInMemorySettings();
    });

    test('שומר snapshot נפרד של הטאבים בעת החלפת שולחן עבודה', () async {
      final firstWorkspace = Workspace(name: 'א', tabs: const []);
      final secondWorkspace = Workspace(name: 'ב', tabs: const []);
      final repository = _FakeWorkspaceRepository(
        workspaces: [firstWorkspace, secondWorkspace],
        activeWorkspaceId: firstWorkspace.id,
      );

      List<OpenedTab>? callbackTabs;
      final bloc = WorkspaceBloc(
        repository: repository,
        onWorkspaceTabsChanged: (tabs, _) {
          callbackTabs = tabs;
        },
      )..add(LoadWorkspaces());

      // Wait for LoadWorkspaces to complete (isLoading transitions false→true→false)
      await bloc.stream.firstWhere((s) => !s.isLoading);

      final liveTab = _createTextTab('ספר חי');
      bloc.add(
        SwitchToWorkspace(
          targetWorkspaceId: secondWorkspace.id,
          currentTabsToSave: [liveTab],
          currentTabIndexToSave: 0,
        ),
      );

      // Wait for workspace switch to complete (activeWorkspaceId changes)
      await bloc.stream
          .firstWhere((s) => s.activeWorkspaceId == secondWorkspace.id);

      final savedWorkspace =
          bloc.state.workspaces.firstWhere((w) => w.id == firstWorkspace.id);
      expect(savedWorkspace.tabs, hasLength(1));
      expect(savedWorkspace.tabs.first, isNot(same(liveTab)));
      expect(callbackTabs, isNotNull);
      expect(callbackTabs, isEmpty);

      await bloc.close();
      liveTab.dispose();
    });

    test('מעביר ל-UI עותקים נפרדים של טאבי שולחן העבודה היעד', () async {
      final targetTab = _createTextTab('ספר יעד');
      final sourceWorkspace = Workspace(name: 'א', tabs: const []);
      final targetWorkspace = Workspace(name: 'ב', tabs: [targetTab]);
      final repository = _FakeWorkspaceRepository(
        workspaces: [sourceWorkspace, targetWorkspace],
        activeWorkspaceId: sourceWorkspace.id,
      );

      List<OpenedTab>? callbackTabs;
      final bloc = WorkspaceBloc(
        repository: repository,
        onWorkspaceTabsChanged: (tabs, _) {
          callbackTabs = tabs;
        },
      )..add(LoadWorkspaces());

      await bloc.stream.firstWhere((s) => !s.isLoading);

      bloc.add(
        SwitchToWorkspace(
          targetWorkspaceId: targetWorkspace.id,
          currentTabsToSave: const [],
          currentTabIndexToSave: 0,
        ),
      );

      await bloc.stream
          .firstWhere((s) => s.activeWorkspaceId == targetWorkspace.id);

      expect(callbackTabs, isNotNull);
      expect(callbackTabs, hasLength(1));
      expect(callbackTabs!.first, isNot(same(targetWorkspace.tabs.first)));

      await bloc.close();
      targetTab.dispose();
    });
  });
}

TextBookTab _createTextTab(String title) {
  return TextBookTab(
    book: TextBook(title: title),
    index: 0,
  );
}

class _FakeWorkspaceRepository extends WorkspaceRepository {
  _FakeWorkspaceRepository({
    required List<Workspace> workspaces,
    required String activeWorkspaceId,
  })  : _workspaces = List<Workspace>.from(workspaces),
        _activeWorkspaceId = activeWorkspaceId;

  List<Workspace> _workspaces;
  String? _activeWorkspaceId;

  @override
  (List<Workspace>, String?) loadWorkspaces() =>
      (List<Workspace>.from(_workspaces), _activeWorkspaceId);

  @override
  Future<void> saveWorkspaces(
      List<Workspace> workspaces, String? currentWorkspaceId) async {
    _workspaces = List<Workspace>.from(workspaces);
    _activeWorkspaceId = currentWorkspaceId;
  }
}
