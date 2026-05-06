import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/recipe_providers.dart';

class RecipeDetailPage extends ConsumerWidget {
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeByIdProvider(recipeId));
    final isFavorite = ref.watch(isFavoriteProvider(recipeId)).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton.filledTonal(
            onPressed: () {
              ref.read(favoriteControllerProvider.notifier).toggleFavorite(
                    recipeId: recipeId,
                    isFavorite: isFavorite,
                  );
            },
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: recipeAsync.when(
        data: (recipe) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.orange.shade50,
                    child: const Icon(Icons.restaurant_rounded, size: 70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              recipe.name,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(recipe.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(label: Text(recipe.category), avatar: const Icon(Icons.category_rounded, size: 18)),
                Chip(label: Text('${recipe.cookingTimeMinutes} min'), avatar: const Icon(Icons.timer_rounded, size: 18)),
                Chip(label: Text(recipe.difficulty), avatar: const Icon(Icons.speed_rounded, size: 18)),
              ],
            ),
            const SizedBox(height: 22),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingrédients',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Préparation',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            child: Text('${entry.key + 1}'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
      ),
    );
  }
}
