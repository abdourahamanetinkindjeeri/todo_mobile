import '../../domain/entities/recipe.dart';

class RecipeFilterCriteria {
  final String query;
  final String category;

  const RecipeFilterCriteria({
    required this.query,
    required this.category,
  });

  String get normalizedQuery => query.trim().toLowerCase();

  bool get hasSelectedCategory => category != FilterRecipesUseCase.allCategory;
}

class FilterRecipesUseCase {
  static const allCategory = 'Toutes';

  List<Recipe> call({
    required List<Recipe> recipes,
    required RecipeFilterCriteria criteria,
  }) {
    return recipes.where((recipe) {
      return _matchesQuery(recipe, criteria.normalizedQuery) &&
          _matchesCategory(recipe, criteria);
    }).toList();
  }

  bool _matchesQuery(Recipe recipe, String query) {
    if (query.isEmpty) return true;

    return recipe.name.toLowerCase().contains(query) ||
        recipe.description.toLowerCase().contains(query) ||
        recipe.ingredients.any((item) => item.toLowerCase().contains(query));
  }

  bool _matchesCategory(Recipe recipe, RecipeFilterCriteria criteria) {
    return !criteria.hasSelectedCategory ||
        recipe.category == criteria.category;
  }
}
