import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:freshkeep/core/database/local_database.dart';
import 'package:freshkeep/features/cooking_timers/data/cooking_timer_repository.dart';
import 'package:freshkeep/features/cooking_timers/domain/cooking_timer.dart';
import 'package:freshkeep/features/meal_planner/data/meal_plan_repository.dart';
import 'package:freshkeep/features/meal_planner/domain/meal_plan.dart';
import 'package:freshkeep/features/recipes/data/recipe_repository.dart';
import 'package:freshkeep/features/settings/data/personal_data_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkeep/core/database/database_provider.dart';
import 'package:freshkeep/features/cooking_timers/application/cooking_timer_controller.dart';
import 'package:freshkeep/features/reminders/application/reminder_controller.dart';

import 'support/memory_reminder_platform.dart';

Map<String, dynamic> custom(String id, {String name = 'Soup', String? image}) =>
    {
      'id': id,
      'ar': name,
      'en': name,
      'description': 'Mine',
      'category': 'lunch',
      'prepMinutes': 5,
      'cookMinutes': 20,
      'minutes': 25,
      'servings': 2,
      'art': 'custom',
      'imagePath': image,
      'personal': true,
      'ingredients': [
        {
          'key': 'carrot',
          'ar': 'جزر',
          'en': 'Carrot',
          'aliases': ['carrot', 'جزر'],
          'amount': 100.0,
          'unit': 'g',
        },
      ],
      'stepsAr': ['اغسل', 'اطبخ'],
      'stepsEn': ['Wash', 'Cook'],
    };
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Database db;
  setUp(
    () async => db = await LocalDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    ),
  );
  tearDown(() => db.close());
  test(
    'v6 adds custom recipes and timers without touching original recipe ids',
    () async {
      expect(await db.getVersion(), 7);
      final repo = RecipeRepository(db);
      final originals = await repo.load();
      expect(
        originals.where((r) => !r.personal && !r.isFitness),
        hasLength(12),
      );
      expect(originals.map((r) => r.id).toSet(), contains('banana-oats'));
    },
  );
  test('custom recipe create edit favorite reload and delete', () async {
    final repo = RecipeRepository(db);
    await repo.load();
    await repo.saveCustom(custom('user:one'), isNew: true);
    var r = (await repo.load()).singleWhere((r) => r.id == 'user:one');
    expect(r.personal, isTrue);
    expect(r.stepsEn, ['Wash', 'Cook']);
    await repo.favorite(r.id, true);
    await repo.saveCustom(custom('user:one', name: 'Edited'), isNew: false);
    r = (await RecipeRepository(
      db,
    ).load()).singleWhere((r) => r.id == 'user:one');
    expect(r.en, 'Edited');
    expect(r.favorite, isTrue);
    expect(await repo.deleteCustom(r.id), isNull);
    expect((await repo.load()).where((x) => x.id == r.id), isEmpty);
  });
  test(
    'deleting planned custom recipe leaves safe unavailable reference',
    () async {
      final recipes = RecipeRepository(db);
      await recipes.load();
      await recipes.saveCustom(custom('user:planned'), isNew: true);
      final now = DateTime(2026, 10, 21);
      await MealPlanRepository(db).save(
        MealPlanEntry(
          id: 'plan',
          date: now,
          slot: MealSlot.dinner,
          recipeId: 'user:planned',
          servings: 2,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await recipes.deleteCustom('user:planned');
      final plan = (await MealPlanRepository(db).load(DateTime(2026, 10, 20)))
          .single;
      expect(plan.recipeId, 'user:planned');
      expect(
        (await recipes.load()).where((r) => r.id == plan.recipeId),
        isEmpty,
      );
    },
  );
  test(
    'multiple timers persist independently and end time survives reload',
    () async {
      final repo = CookingTimerRepository(db);
      final now = DateTime(2026, 10, 21, 12);
      final a = await repo.create('a', 'Oven', 60, now);
      await repo.create('b', 'Eggs', 300, now);
      await repo.update(
        CookingTimer(
          notificationId: a.notificationId,
          id: a.id,
          name: a.name,
          durationSeconds: a.durationSeconds,
          remainingSeconds: 60,
          endAt: now.add(const Duration(seconds: 60)),
          state: CookingTimerState.running,
          createdAt: a.createdAt,
          updatedAt: now,
        ),
      );
      final rows = await repo.load(now.add(const Duration(seconds: 20)));
      expect(rows, hasLength(2));
      expect(
        rows
            .singleWhere((x) => x.id == 'a')
            .remainingAt(now.add(const Duration(seconds: 20))),
        40,
      );
      expect(rows.singleWhere((x) => x.id == 'b').remainingSeconds, 300);
    },
  );
  test('pause reset and finish calculations use saved end time', () {
    final now = DateTime(2026, 10, 21, 12);
    final t = CookingTimer(
      notificationId: 100001,
      id: 'x',
      name: 'Timer',
      durationSeconds: 90,
      remainingSeconds: 90,
      endAt: now.add(const Duration(seconds: 90)),
      state: CookingTimerState.running,
      createdAt: now,
      updatedAt: now,
    );
    expect(t.remainingAt(now.add(const Duration(seconds: 30))), 60);
    expect(t.remainingAt(now.add(const Duration(seconds: 100))), 0);
    expect(t.progressAt(now.add(const Duration(seconds: 45))), 0.5);
  });
  test('export and delete include custom recipes and timers while excluding image paths', () async {
    final recipes = RecipeRepository(db);
    await recipes.load();
    await recipes.saveCustom(
      custom('user:export', image: 'C:/private/photo.jpg'),
      isNew: true,
    );
    await CookingTimerRepository(db)
        .create('timer', 'Oven', 30, DateTime(2026, 10, 21));
    final output = await PersonalDataStore(db).export(DateTime(2026, 10, 21));
    final json = jsonDecode(output) as Map<String, dynamic>;
    expect(json['custom_recipes'], hasLength(1));
    expect(output, isNot(contains('C:/private/photo.jpg')));
    expect(json['cooking_timers'], hasLength(1));
    await PersonalDataStore(db).deleteRecords();
    expect(await db.query('custom_recipes'), isEmpty);
    expect(await db.query('cooking_timers'), isEmpty);
  });
  test(
    'timer schedules once, refresh does not duplicate, and pause cancels',
    () async {
      final platform = MemoryReminderPlatform();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) async => db),
          reminderPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);
      await container.read(cookingTimersProvider.future);
      await container.read(cookingTimersProvider.notifier).create('Oven', 120);
      expect(platform.jobs, hasLength(1));
      expect(platform.jobs.keys.single, greaterThanOrEqualTo(100000));
      final schedules = platform.schedules;
      await container.read(cookingTimersProvider.notifier).refresh();
      expect(platform.jobs, hasLength(1));
      expect(platform.schedules, schedules);
      final timer = container.read(cookingTimersProvider).requireValue.single;
      await container.read(cookingTimersProvider.notifier).pause(timer);
      expect(platform.jobs, isEmpty);
    },
  );
}
