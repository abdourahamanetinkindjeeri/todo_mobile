import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_clean_app/features/recipes/application/usecases/filter_recipes_use_case.dart';
import 'package:recipe_clean_app/features/recipes/domain/entities/recipe.dart';

void main() {
  test('la recherche trouve une recette par ingrédient', () {
    final filterRecipes = FilterRecipesUseCase();
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

    final result = filterRecipes(
      recipes: recipes,
      criteria: const RecipeFilterCriteria(
        query: 'citron',
        category: FilterRecipesUseCase.allCategory,
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.name, 'Yassa Poulet');
  });

  test('le filtre catégorie limite les résultats', () {
    final filterRecipes = FilterRecipesUseCase();
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
      Recipe(
        id: '2',
        name: 'Jus de bissap',
        description: 'Boisson fraîche',
        imageUrl: '',
        category: 'Boisson',
        difficulty: 'Facile',
        cookingTimeMinutes: 15,
        ingredients: ['Bissap', 'Menthe'],
        steps: ['Infuser'],
      ),
    ];

    final result = filterRecipes(
      recipes: recipes,
      criteria: const RecipeFilterCriteria(
        query: '',
        category: 'Boisson',
      ),
    );

    expect(result, hasLength(1));
    expect(result.first.name, 'Jus de bissap');
  });
}
