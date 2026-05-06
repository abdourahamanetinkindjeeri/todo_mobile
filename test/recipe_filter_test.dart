import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_clean_app/features/recipes/domain/entities/recipe.dart';

List<Recipe> filterRecipes(List<Recipe> recipes, String query) {
  final normalized = query.trim().toLowerCase();
  return recipes.where((recipe) {
    return normalized.isEmpty ||
        recipe.name.toLowerCase().contains(normalized) ||
        recipe.ingredients.any((item) => item.toLowerCase().contains(normalized));
  }).toList();
}

void main() {
  test('la recherche trouve une recette par ingrédient', () {
    const recipes = [
      Recipe(
        id: '1',
        name: 'Yassa Poulet',
        description: 'Plat sénégalais',
        imageUrl: '',
        category: 'Plat',
        difficulty: 'Moyen',
        cookingTimeMinutes: 55,
        ingredients: ['Poulet', 'Citron'],
        steps: ['Préparer'],
      ),
    ];

    final result = filterRecipes(recipes, 'citron');

    expect(result, hasLength(1));
    expect(result.first.name, 'Yassa Poulet');
  });
}
