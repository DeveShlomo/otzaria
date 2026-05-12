import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/core/storage/hive_data_provider.dart';
import '../test_helpers/memory_cache_provider.dart';
import 'package:otzaria/file_sync/bloc/file_sync_bloc.dart';
import 'package:otzaria/file_sync/bloc/file_sync_event.dart';
import 'package:otzaria/file_sync/repository/file_sync_repository.dart';
import 'package:otzaria/file_sync/bloc/file_sync_state.dart';
import 'package:otzaria/settings/engine/settings_repository.dart';
import 'package:otzaria/work_status/work_status_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setUpInMemorySettings();
    await Settings.setValue<bool>(SettingsRepository.keyOfflineMode, false);
    await Settings.setValue<bool>(
      SettingsRepository.keySoftwareAndBookUpdatesEnabled,
      true,
    );
  });

  group('FileSyncBloc', () {
    test('StartSync בזמן syncing מתעלם מהאירוע השני', () async {
      final fetchStarted = Completer<void>();
      final fetchRelease = Completer<void>();
      final repo = _SlowRepository(
        onFetchStarted: fetchStarted,
        fetchRelease: fetchRelease,
      );
      final workCubit = WorkStatusCubit();
      final bloc = FileSyncBloc(repository: repo, workStatusCubit: workCubit);

      final states = <FileSyncState>[];
      final sub = bloc.stream.listen(states.add);

      // ריצה ראשונה — מתחילה ותיתקע על getCurrentLibraryVersion
      bloc.add(const StartSync());
      await fetchStarted.future;

      expect(bloc.state.status, FileSyncStatus.syncing,
          reason: 'הריצה הראשונה אמורה להיות בסטטוס syncing');

      final stateCountBeforeSecond = states.length;

      // ריצה שניה — אמורה להתעלם כי כבר syncing
      bloc.add(const StartSync());
      await Future.delayed(Duration.zero);

      expect(states.length, stateCountBeforeSecond,
          reason: 'StartSync נוסף בזמן syncing לא צריך לפלוט state חדש');
      expect(bloc.state.status, FileSyncStatus.syncing);

      // שחרור הריצה הראשונה
      fetchRelease.complete();
      await Future.delayed(const Duration(milliseconds: 30));

      await sub.cancel();
      await bloc.close();
      workCubit.close();
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SlowRepository extends FileSyncRepository {
  final Completer<void> onFetchStarted;
  final Completer<void> fetchRelease;

  _SlowRepository({
    required this.onFetchStarted,
    required this.fetchRelease,
  }) : super(githubOwner: 'test', repositoryName: 'test');

  @override
  Future<int> getCurrentLibraryVersion() async {
    onFetchStarted.complete();
    await fetchRelease.future;
    return 133;
  }

  @override
  Future<List<DiffReleaseAsset>> fetchAvailableDiffAssets() async => [];
}
