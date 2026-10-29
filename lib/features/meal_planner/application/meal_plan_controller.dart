import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../data/meal_plan_repository.dart';
import '../domain/meal_plan.dart';

class MealPlanWeekController extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void set(DateTime value) => state = value;
}

final mealPlanWeekProvider = NotifierProvider<MealPlanWeekController, DateTime>(
  MealPlanWeekController.new,
);
final mealPlanRepositoryProvider = FutureProvider(
  (ref) async =>
      MealPlanRepository(await ref.watch(appDatabaseProvider.future)),
);
final mealPlansProvider = FutureProvider<List<MealPlanEntry>>((ref) async {
  final anchor = ref.watch(mealPlanWeekProvider);
  return (await ref.watch(mealPlanRepositoryProvider.future)).load(anchor);
});

Future<void> saveMealPlan(
  WidgetRef ref, {
  MealPlanEntry? existing,
  required DateTime date,
  required MealSlot slot,
  required String recipeId,
  required double servings,
}) async {
  final now = DateTime.now();
  await (await ref.read(mealPlanRepositoryProvider.future)).save(
    MealPlanEntry(
      id: existing?.id ?? const Uuid().v4(),
      date: date,
      slot: slot,
      recipeId: recipeId,
      servings: servings,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    ),
  );
  ref.invalidate(mealPlansProvider);
}

Future<void> removeMealPlan(WidgetRef ref, DateTime date, MealSlot slot) async {
  await (await ref.read(mealPlanRepositoryProvider.future)).remove(date, slot);
  ref.invalidate(mealPlansProvider);
}
