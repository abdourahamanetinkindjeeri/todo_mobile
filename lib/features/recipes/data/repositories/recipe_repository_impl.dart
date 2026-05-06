import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/recipe_remote_datasource.dart';
import '../models/recipe_model.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final RecipeRemoteDataSource _remoteDataSource;

  RecipeRepositoryImpl({RecipeRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? RecipeRemoteDataSource();

  @override
  Stream<List<Recipe>> watchRecipes() {
    return _remoteDataSource.watchRecipes().handleError(_handleFirestoreError);
  }

  @override
  Stream<Recipe> watchRecipeById(String id) {
    return _remoteDataSource.watchRecipeById(id).handleError(_handleFirestoreError);
  }

  @override
  Stream<List<Recipe>> watchFavoriteRecipes(String userId) {
    return _remoteDataSource.watchRecipes().asyncMap((recipes) async {
      final favorites = await _remoteDataSource.watchFavoriteIds(userId).first;
      return recipes.where((recipe) => favorites.contains(recipe.id)).toList();
    }).handleError(_handleFirestoreError);
  }

  @override
  Future<void> createRecipe({
    required String userId,
    required Recipe recipe,
  }) async {
    try {
      await _remoteDataSource.createRecipe(
        userId: userId,
        recipe: RecipeModel(
          id: recipe.id,
          name: recipe.name,
          description: recipe.description,
          imageUrl: recipe.imageUrl,
          category: recipe.category,
          difficulty: recipe.difficulty,
          cookingTimeMinutes: recipe.cookingTimeMinutes,
          ingredients: recipe.ingredients,
          steps: recipe.steps,
          ownerId: recipe.ownerId,
        ),
      );
    } on FirebaseException catch (e) {
      throw AppException(_firestoreMessage(e));
    }
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _remoteDataSource.addToFavorites(userId: userId, recipeId: recipeId);
    } on FirebaseException catch (e) {
      throw AppException(_firestoreMessage(e));
    }
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _remoteDataSource.removeFromFavorites(userId: userId, recipeId: recipeId);
    } on FirebaseException catch (e) {
      throw AppException(_firestoreMessage(e));
    }
  }

  @override
  Stream<bool> watchIsFavorite({
    required String userId,
    required String recipeId,
  }) {
    return _remoteDataSource
        .watchIsFavorite(userId: userId, recipeId: recipeId)
        .handleError(_handleFirestoreError);
  }

  Never _handleFirestoreError(Object error, StackTrace stackTrace) {
    if (error is FirebaseException) {
      throw AppException(_firestoreMessage(error));
    }
    throw AppException('Erreur Firestore: $error');
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Accès Firestore refusé. Publie les règles fournies dans firestore.rules.';
      case 'unavailable':
        return 'Firestore est indisponible. Vérifie ta connexion.';
      default:
        return '[cloud_firestore/${e.code}] ${e.message ?? 'Erreur Firestore'}';
    }
  }
}
