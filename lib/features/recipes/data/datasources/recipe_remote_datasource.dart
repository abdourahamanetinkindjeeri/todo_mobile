import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_model.dart';

abstract final class FirestoreCollections {
  static const recipes = 'recipes';
  static const favorites = 'favorites';
}

class RecipeRemoteDataSource {
  final FirebaseFirestore _firestore;

  RecipeRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _firestore.collection(FirestoreCollections.recipes);

  Stream<List<RecipeModel>> watchRecipes() {
    return _recipes.snapshots().map(
          (snapshot) => snapshot.docs.map(RecipeModel.fromFirestore).toList()
            ..sort((a, b) => a.name.compareTo(b.name)),
        );
  }

  Stream<RecipeModel> watchRecipeById(String id) {
    return _recipes.doc(id).snapshots().map(RecipeModel.fromFirestore);
  }

  Future<void> createRecipe({
    required String userId,
    required RecipeModel recipe,
  }) {
    return _recipes.add(recipe.toCreateMap(ownerId: userId));
  }

  Stream<List<String>> watchFavoriteIds(String userId) {
    return _firestore
        .collection(FirestoreCollections.favorites)
        .doc(userId)
        .collection(FirestoreCollections.recipes)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> addToFavorites({
    required String userId,
    required String recipeId,
  }) {
    return _firestore
        .collection(FirestoreCollections.favorites)
        .doc(userId)
        .collection(FirestoreCollections.recipes)
        .doc(recipeId)
        .set({
      'recipeId': recipeId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromFavorites({
    required String userId,
    required String recipeId,
  }) {
    return _firestore
        .collection(FirestoreCollections.favorites)
        .doc(userId)
        .collection(FirestoreCollections.recipes)
        .doc(recipeId)
        .delete();
  }

  Stream<bool> watchIsFavorite({
    required String userId,
    required String recipeId,
  }) {
    return _firestore
        .collection(FirestoreCollections.favorites)
        .doc(userId)
        .collection(FirestoreCollections.recipes)
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
