import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../application/usecases/filter_recipes_use_case.dart';
import '../../data/repositories/recipe_repository_impl.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepositoryImpl();
});

final recipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).watchRecipes();
});

final filterRecipesUseCaseProvider = Provider<FilterRecipesUseCase>((ref) {
  return FilterRecipesUseCase();
});

final recipeSearchQueryProvider = StateProvider<String>((ref) => '');
final recipeCategoryProvider = StateProvider<String>(
  (ref) => FilterRecipesUseCase.allCategory,
);

final filteredRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final recipesAsync = ref.watch(recipesProvider);
  final filterRecipes = ref.watch(filterRecipesUseCaseProvider);
  final criteria = RecipeFilterCriteria(
    query: ref.watch(recipeSearchQueryProvider),
    category: ref.watch(recipeCategoryProvider),
  );

  return recipesAsync.whenData((recipes) {
    return filterRecipes(recipes: recipes, criteria: criteria);
  });
});

final recipeCategoriesProvider = Provider<List<String>>((ref) {
  final recipes = ref.watch(recipesProvider).valueOrNull ?? const <Recipe>[];
  final categories = recipes.map((recipe) => recipe.category).toSet().toList()
    ..sort();
  return [FilterRecipesUseCase.allCategory, ...categories];
});

final recipeByIdProvider = StreamProvider.family<Recipe, String>((ref, id) {
  return ref.watch(recipeRepositoryProvider).watchRecipeById(id);
});

final favoriteRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(<Recipe>[]);
  return ref.watch(recipeRepositoryProvider).watchFavoriteRecipes(user.id);
});

final isFavoriteProvider = StreamProvider.family<bool, String>((ref, recipeId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(false);
  return ref.watch(recipeRepositoryProvider).watchIsFavorite(
        userId: user.id,
        recipeId: recipeId,
      );
});

final favoriteControllerProvider =
    StateNotifierProvider<FavoriteController, AsyncValue<void>>((ref) {
  return FavoriteController(ref);
});

class FavoriteController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FavoriteController(this._ref) : super(const AsyncData(null));

  Future<void> toggleFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError(
        const AppException('Connecte-toi pour gérer les favoris.'),
        StackTrace.current,
      );
      return;
    }

    final repository = _ref.read(recipeRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      if (isFavorite) {
        return repository.removeFromFavorites(
          userId: user.id,
          recipeId: recipeId,
        );
      }
      return repository.addToFavorites(userId: user.id, recipeId: recipeId);
    });
  }
}

final createRecipeControllerProvider =
    StateNotifierProvider<CreateRecipeController, AsyncValue<void>>((ref) {
  return CreateRecipeController(ref);
});

class CreateRecipeController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  CreateRecipeController(this._ref) : super(const AsyncData(null));

  Future<bool> createRecipe(Recipe recipe) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError(
          const AppException('Utilisateur non connecté.'), StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() {
      return _ref.read(recipeRepositoryProvider).createRecipe(
            userId: user.id,
            recipe: recipe,
          );
    });
    state = result;
    return !result.hasError;
  }
}
