import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/database_provider.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/core/time/clock.dart';
import 'package:freshkeep/features/inventory/application/inventory_controller.dart';
import 'package:freshkeep/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:freshkeep/features/inventory/domain/food_item.dart';
import 'package:freshkeep/features/reminders/application/reminder_controller.dart';
import 'package:freshkeep/features/settings/presentation/data_privacy_screen.dart';
import 'package:freshkeep/features/settings/application/preferences_controller.dart';
import 'package:freshkeep/features/settings/domain/app_preferences.dart';
import 'package:freshkeep/features/statistics/presentation/statistics_screen.dart';
import 'package:freshkeep/features/statistics/application/statistics_provider.dart';
import 'package:freshkeep/l10n/generated/app_localizations.dart';

import 'support/food_fixture.dart';
import 'support/memory_inventory_repository.dart';
import 'support/memory_preferences_repository.dart';
import 'support/memory_reminder_platform.dart';
import 'scanning_widget_test.dart' show host;

Future<void> tap5(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.tap(f);
  await t.pump();
  // Destructive privacy actions now invalidate the larger offline recipe
  // library. Give SQLite/asset work real event-loop time, then advance UI
  // animations with a deterministic budget.
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await t.pump(const Duration(milliseconds: 500));
}

class CancelFailurePlatform extends MemoryReminderPlatform {
  @override
  Future<void> cancel(int id) async => throw StateError('cancel failed');
}

void main() {
  sqfliteFfiInit();
  late Database db;
  late ProviderContainer container;
  late MemoryReminderPlatform platform;
  int cleanups = 0;
  setUp(() async {
    db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    platform = MemoryReminderPlatform();
    cleanups = 0;
  });
  tearDown(() => db.close());
  Future<void> launch(
    WidgetTester t,
    Widget screen, {
    String language = 'en',
    ThemeMode mode = ThemeMode.light,
    double scale = 1,
  }) async {
    addTearDown(() => t.pumpWidget(const SizedBox()));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          todayProvider.overrideWith(TestTodayController.new),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 20, 12)),
          reminderPlatformProvider.overrideWithValue(platform),
          personalFilesCleanupProvider.overrideWithValue(() async {
            cleanups++;
          }),
          preferencesRepositoryProvider.overrideWithValue(
            MemoryPreferencesRepository(
              AppPreferences(languageCode: language, onboardingComplete: true),
            ),
          ),
        ],
        child: host(
          Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: screen,
              );
            },
          ),
          language: language,
          mode: mode,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> used() async {
    final repo = SqliteInventoryRepository(db);
    final food = foodFixture();
    await repo.save(food, isNew: true);
    await repo.changeStatus(food, FoodStatus.used, DateTime(2026, 10, 19, 9));
  }

  testWidgets(
    'real statistics, monthly filtering and inventory restoration update live',
    (t) async {
      await used();
      await launch(t, const Scaffold(body: StatisticsScreen()));
      expect(find.byType(BarChart), findsOneWidget);
      await tap5(t, find.byKey(const Key('trend-monthly')));
      expect(
        t.widget<ChoiceChip>(find.byKey(const Key('trend-monthly'))).selected,
        isTrue,
      );
      final repo = SqliteInventoryRepository(db);
      final f = (await repo.load()).single;
      await container
          .read(inventoryProvider.notifier)
          .changeStatus(f, FoodStatus.available);
      await t.pumpAndSettle();
      expect(find.byType(BarChart), findsNothing);
      expect(
        find.text('Your story starts with your next batch'),
        findsOneWidget,
      );
    },
  );
  for (final language in ['ar', 'en']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        '$language ${mode.name} statistics 320px at 200% text with accessible data',
        (t) async {
          t.view.physicalSize = const Size(320, 700);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await used();
          await launch(
            t,
            const Scaffold(body: StatisticsScreen()),
            language: language,
            mode: mode,
            scale: 2,
          );
          final l = lookupAppLocalizations(Locale(language));
          await t.ensureVisible(find.byKey(const Key('chart-data')));
          await t.pumpAndSettle();
          expect(find.textContaining(l.statsUsed), findsWidgets);
          expect(t.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'export cancel, success and failure use platform bridge with safe JSON',
    (t) async {
      await used();
      var response = 0;
      Map? arguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(dataExportChannel, (call) async {
            expect(call.method, 'exportJson');
            arguments = call.arguments as Map;
            if (response == 2) throw PlatformException(code: 'write_failure');
            return response == 1;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(dataExportChannel, null),
      );
      await launch(t, const DataPrivacyScreen());
      await tap5(t, find.byKey(const Key('export-data')));
      expect(find.text('Export cancelled'), findsOneWidget);
      expect(
        (jsonDecode(arguments!['content'] as String) as Map)['inventory'],
        hasLength(1),
      );
      response = 1;
      await tap5(t, find.byKey(const Key('export-data')));
      expect(find.text('Export saved'), findsOneWidget);
      response = 2;
      await tap5(t, find.byKey(const Key('export-data')));
      expect(find.textContaining('Could not finish'), findsOneWidget);
      expect((await db.query('food_items')).length, 1);
    },
  );
  testWidgets(
    'delete requires acknowledgement, cancel preserves data, confirm clears history and refreshes statistics',
    (t) async {
      await used();
      await launch(t, const DataPrivacyScreen());
      await container.read(statisticsProvider.future);
      await tap5(t, find.byKey(const Key('delete-data')));
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('confirm-delete-data')))
            .onPressed,
        isNull,
      );
      await tap5(t, find.text('Cancel'));
      expect((await db.query('food_items')).length, 1);
      await tap5(t, find.byKey(const Key('delete-data')));
      await tap5(t, find.byKey(const Key('acknowledge-delete')));
      await tap5(t, find.byKey(const Key('confirm-delete-data')));
      expect((await db.query('food_items')), isEmpty);
      expect((await db.query('inventory_events')), isEmpty);
      expect(
        (await container.read(statisticsProvider.future)).outcomes,
        isEmpty,
      );
      expect(cleanups, 1);
      expect(find.text('Personal data deleted'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'privacy actions meet tap target, labeling and text contrast guidelines',
    (t) async {
      final semantics = t.ensureSemantics();

      await launch(t, const DataPrivacyScreen());
      await expectLater(t, meetsGuideline(textContrastGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      semantics.dispose();
    },
  );
  testWidgets(
    'failed alarm cancellation leaves personal records intact for retry',
    (t) async {
      platform = CancelFailurePlatform();
      await used();
      await db.insert('reminder_ids', {'food_id': 'batch-1', 'days': 1});
      await launch(t, const DataPrivacyScreen());
      await tap5(t, find.byKey(const Key('delete-data')));
      await tap5(t, find.byKey(const Key('acknowledge-delete')));
      await tap5(t, find.byKey(const Key('confirm-delete-data')));
      expect(await db.query('food_items'), hasLength(1));
      expect(await db.query('inventory_events'), hasLength(2));
      expect(cleanups, 0);
      expect(find.textContaining('Could not finish'), findsOneWidget);
    },
  );
}
