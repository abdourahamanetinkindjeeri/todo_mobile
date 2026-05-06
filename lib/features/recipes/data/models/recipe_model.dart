import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recipe.dart';

class RecipeModel extends Recipe {
  const RecipeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.imageUrl,
    required super.category,
    required super.difficulty,
    required super.cookingTimeMinutes,
    required super.ingredients,
    required super.steps,
    super.ownerId,
  });

  factory RecipeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Recette introuvable: ${doc.id}');
    }
    return RecipeModel.fromMap(doc.id, data);
  }

  factory RecipeModel.fromMap(String id, Map<String, dynamic> data) {
    return RecipeModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      category: (data['category'] ?? 'Plat').toString(),
      difficulty: (data['difficulty'] ?? 'Facile').toString(),
      cookingTimeMinutes: (data['cookingTimeMinutes'] as num?)?.toInt() ?? 30,
      ingredients: List<String>.from(data['ingredients'] ?? const []),
      steps: List<String>.from(data['steps'] ?? const []),
      ownerId: data['ownerId']?.toString(),
    );
  }

  Map<String, dynamic> toCreateMap({required String ownerId}) {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'imageUrl': imageUrl.trim(),
      'category': category.trim(),
      'difficulty': difficulty.trim(),
      'cookingTimeMinutes': cookingTimeMinutes,
      'ingredients': ingredients.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'steps': steps.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'ownerId': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
