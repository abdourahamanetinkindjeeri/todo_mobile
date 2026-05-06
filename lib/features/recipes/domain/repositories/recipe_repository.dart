import '../entities/recipe.dart';

abstract class RecipeRepository {
  Stream<List<Recipe>> watchRecipes();

  Stream<Recipe> watchRecipeById(String id);

  Stream<List<Recipe>> watchFavoriteRecipes(String userId);

  Future<void> createRecipe({
    required String userId,
    required Recipe recipe,
  });

  Future<void> addToFavorites({
    required String userId,
    required String recipeId,
  });

  Future<void> removeFromFavorites({
    required String userId,
    required String recipeId,
  });

  Stream<bool> watchIsFavorite({
    required String userId,
    required String recipeId,
  });
}
