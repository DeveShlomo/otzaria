import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria/settings/settings_exports.dart';
import 'package:otzaria/theme/app_surfaces.dart';
import 'package:otzaria/theme/app_theme_options.dart';

void main() {
  group('AppSurfaces.selectedItem', () {
    late ColorScheme lightScheme;
    late ColorScheme darkScheme;

    setUpAll(() {
      lightScheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      );
      darkScheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      );
    });

    test('מחזיר primaryContainer בשקיפות 30%', () {
      final result = AppSurfaces.selectedItem(lightScheme);
      final expected = lightScheme.primaryContainer.withValues(alpha: 0.3);
      expect(result, expected);
    });

    test('עובד גם עם ערכת צבעים כהה', () {
      final result = AppSurfaces.selectedItem(darkScheme);
      final expected = darkScheme.primaryContainer.withValues(alpha: 0.3);
      expect(result, expected);
    });

    test('צבע שונה מ-primaryContainer המלא', () {
      final selected = AppSurfaces.selectedItem(lightScheme);
      final full = lightScheme.primaryContainer;
      // alpha 30% שונה מ-alpha 100%
      expect(selected.a, isNot(equals(full.a)));
    });

    test('alpha קרוב ל-0.3 (סובלנות לעיגול float)', () {
      final selected = AppSurfaces.selectedItem(lightScheme);
      expect(selected.a, closeTo(0.3, 0.01));
    });
  });

  group('AppSurfaces.readerBackground מגיב לשינוי הגדרות', () {
    testWidgets(
      'הצבע מתעדכן מיד כששינוי המשתמש נפלט מה-SettingsBloc (context.watch)',
      (tester) async {
        final settingsBloc = _FakeSettingsBloc(SettingsState.initial());
        addTearDown(settingsBloc.close);

        Color? capturedColor;

        await tester.pumpWidget(
          BlocProvider<SettingsBloc>.value(
            value: settingsBloc,
            child: MaterialApp(
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              home: Builder(
                builder: (context) {
                  capturedColor = AppSurfaces.readerBackground(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );

        // ברירת המחדל של LightReaderBackground היא surface — לא לבן.
        expect(capturedColor, isNot(equals(Colors.white)));

        settingsBloc.add(
          const UpdateLightReaderBackground(LightReaderBackground.white),
        );
        await tester.pump();

        expect(capturedColor, equals(Colors.white));
      },
    );
  });
}

/// Bloc מדומה למבחן — מיישם את עדכוני הרקע בדיוק כמו [SettingsBloc] האמיתי,
/// בלי תלות ב-repository/אחסון.
class _FakeSettingsBloc extends Bloc<SettingsEvent, SettingsState>
    implements SettingsBloc {
  _FakeSettingsBloc(super.initialState) {
    on<UpdateLightReaderBackground>((event, emit) {
      emit(state.copyWith(lightReaderBackground: event.value));
    });
    on<UpdateDarkReaderBackground>((event, emit) {
      emit(state.copyWith(darkReaderBackground: event.value));
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
