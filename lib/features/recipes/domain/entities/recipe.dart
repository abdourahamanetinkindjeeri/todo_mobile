import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String difficulty;
  final int cookingTimeMinutes;
  final List<String> ingredients;
  final List<String> steps;
  final String? ownerId;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.difficulty,
    required this.cookingTimeMinutes,
    required this.ingredients,
    required this.steps,
    this.ownerId,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        category,
        difficulty,
        cookingTimeMinutes,
        ingredients,
        steps,
        ownerId,
      ];
}
