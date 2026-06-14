import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_card.dart';

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(filteredRecipesProvider);
    final categories = ref.watch(recipeCategoriesProvider);
    final selectedCategory = ref.watch(recipeCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes'),
        actions: [
          IconButton(
            tooltip: 'Favoris',
            onPressed: () => context.push(AppRoutes.favorites),
            icon: const Icon(Icons.favorite_rounded),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newRecipe),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: recipesAsync.when(
        data: (recipes) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: _HeroHeader(
                    onSearchChanged: (value) => ref
                        .read(recipeSearchQueryProvider.notifier)
                        .state = value,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ChoiceChip(
                        label: Text(category),
                        selected: category == selectedCategory,
                        onSelected: (_) => ref
                            .read(recipeCategoryProvider.notifier)
                            .state = category,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: categories.length,
                  ),
                ),
              ),
              if (recipes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyRecipesView(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 90),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () => context.push(
                          AppRoutes.recipeDetail(recipe.id),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemCount: recipes.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(recipesProvider),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;

  const _HeroHeader({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFFFB347)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuisine maison',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Découvre, prépare et sauvegarde tes recettes préférées.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher une recette ou un ingrédient',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecipesView extends StatelessWidget {
  const _EmptyRecipesView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 16),
          const Text(
            'Aucune recette trouvée',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajoute une recette avec le bouton + ou vérifie tes données Firestore.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
