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
      ingredients: _readStringList(data['ingredients']),
      steps: _readStringList(data['steps']),
      ownerId: (data['ownerId'] ?? data['createdBy'])?.toString(),
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
      'ingredients': _cleanLines(ingredients),
      'steps': _cleanLines(steps),
      'ownerId': ownerId,
      'createdBy': ownerId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<String> _readStringList(Object? value) {
    if (value is! Iterable) return const [];

    return value.map((item) => item.toString()).toList();
  }

  static List<String> _cleanLines(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
