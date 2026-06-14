import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_clean_app/features/recipes/data/models/recipe_model.dart';

void main() {
  group('RecipeModel', () {
    test('fromMap convertit correctement les données Firestore', () {
      final recipe = RecipeModel.fromMap('abc', const {
        'name': 'Yassa Poulet',
        'description': 'Poulet mariné au citron',
        'imageUrl': 'https://example.com/yassa.jpg',
        'category': 'Plat',
        'difficulty': 'Moyen',
        'cookingTimeMinutes': 55,
        'ingredients': ['Poulet', 'Citron'],
        'steps': ['Mariner', 'Cuire'],
        'ownerId': 'user-1',
      });

      expect(recipe.id, 'abc');
      expect(recipe.name, 'Yassa Poulet');
      expect(recipe.ingredients.length, 2);
      expect(recipe.cookingTimeMinutes, 55);
      expect(recipe.ownerId, 'user-1');
    });

    test('fromMap applique des valeurs par défaut si certains champs manquent',
        () {
      final recipe = RecipeModel.fromMap('abc', const {
        'name': 'Recette simple',
        'description': 'Description',
        'ingredients': <String>[],
        'steps': <String>[],
      });

      expect(recipe.category, 'Plat');
      expect(recipe.difficulty, 'Facile');
      expect(recipe.cookingTimeMinutes, 30);
    });

    test('fromMap utilise createdBy comme propriétaire si ownerId manque', () {
      final recipe = RecipeModel.fromMap('abc', const {
        'name': 'Recette simple',
        'description': 'Description',
        'ingredients': <String>[],
        'steps': <String>[],
        'createdBy': 'user-1',
      });

      expect(recipe.ownerId, 'user-1');
    });
  });
}
