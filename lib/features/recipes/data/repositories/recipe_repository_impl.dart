import 'dart:async';

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
    return _remoteDataSource
        .watchRecipeById(id)
        .handleError(_handleFirestoreError);
  }

  @override
  Stream<List<Recipe>> watchFavoriteRecipes(String userId) {
    return _watchFavoriteRecipes(userId).handleError(_handleFirestoreError);
  }

  @override
  Future<void> createRecipe({
    required String userId,
    required Recipe recipe,
  }) async {
    try {
      await _remoteDataSource.createRecipe(
        userId: userId,
        recipe: _toModel(recipe),
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
      await _remoteDataSource.addToFavorites(
        userId: userId,
        recipeId: recipeId,
      );
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
      await _remoteDataSource.removeFromFavorites(
        userId: userId,
        recipeId: recipeId,
      );
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

  Stream<List<Recipe>> _watchFavoriteRecipes(String userId) {
    StreamSubscription<List<RecipeModel>>? recipesSubscription;
    StreamSubscription<List<String>>? favoritesSubscription;

    List<RecipeModel>? recipes;
    Set<String>? favoriteIds;

    late final StreamController<List<Recipe>> controller;

    void emitFavorites() {
      final currentRecipes = recipes;
      final currentFavoriteIds = favoriteIds;

      if (currentRecipes == null || currentFavoriteIds == null) return;
      if (controller.isClosed) return;

      controller.add(
        currentRecipes
            .where((recipe) => currentFavoriteIds.contains(recipe.id))
            .toList(),
      );
    }

    controller = StreamController<List<Recipe>>(
      onListen: () {
        recipesSubscription = _remoteDataSource.watchRecipes().listen(
          (value) {
            recipes = value;
            emitFavorites();
          },
          onError: controller.addError,
        );

        favoritesSubscription =
            _remoteDataSource.watchFavoriteIds(userId).listen(
          (value) {
            favoriteIds = value.toSet();
            emitFavorites();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await recipesSubscription?.cancel();
        await favoritesSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  RecipeModel _toModel(Recipe recipe) {
    return RecipeModel(
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
    );
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Accès Firestore refusé. Déploie les règles du fichier firestore.rules sur le projet Firebase.';
      case 'unavailable':
        return 'Firestore est indisponible. Vérifie ta connexion.';
      default:
        return '[cloud_firestore/${e.code}] ${e.message ?? 'Erreur Firestore'}';
    }
  }
}
