import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

final recipeRepositoryProvider = FutureProvider<RecipeRepository>(
  (ref) async => RecipeRepository(await ref.watch(appDatabaseProvider.future)),
);
final recipesProvider = AsyncNotifierProvider<RecipeController, List<Recipe>>(
  RecipeController.new,
);

class RecipeController extends AsyncNotifier<List<Recipe>> {
  Future<void> _queue = Future.value();
  Future<void> get idle => _queue;
  @override
  Future<List<Recipe>> build() async =>
      (await ref.watch(recipeRepositoryProvider.future)).load();
  Future<void> favorite(Recipe recipe) {
    final task = _queue.then((_) async {
      final repo = await ref.read(recipeRepositoryProvider.future);
      await repo.favorite(recipe.id, !recipe.favorite);
      try {
        final list = await repo.load();
        if (ref.mounted) state = AsyncData(list);
      } catch (e, s) {
        if (ref.mounted) state = AsyncError(e, s);
      }
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<void> saveCustom(
    Map<String, dynamic> content, {
    required bool isNew,
  }) => _mutate((r) => r.saveCustom(content, isNew: isNew));
  Future<String?> deleteCustom(String id) async {
    String? path;
    await _mutate((r) async => path = await r.deleteCustom(id));
    return path;
  }

  Future<void> _mutate(Future<void> Function(RecipeRepository) action) {
    final task = _queue.then((_) async {
      final repo = await ref.read(recipeRepositoryProvider.future);
      await action(repo);
      if (ref.mounted) state = AsyncData(await repo.load());
    });
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }
}
