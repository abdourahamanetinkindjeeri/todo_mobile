import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/recipes/presentation/pages/favorites_page.dart';
import '../features/recipes/presentation/pages/recipe_detail_page.dart';
import '../features/recipes/presentation/pages/recipe_list_page.dart';
import '../features/recipes/presentation/pages/recipe_form_page.dart';
import '../features/splash/splash_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isSplashRoute = location == AppRoutes.splash;

      if (authState.isLoading || authState.hasError) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      final user = authState.valueOrNull;

      if (isSplashRoute) {
        return user == null ? AppRoutes.login : AppRoutes.recipes;
      }

      if (user == null && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (user != null && isAuthRoute) {
        return AppRoutes.recipes;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.recipes,
        builder: (context, state) => const RecipeListPage(),
      ),
      GoRoute(
        path: AppRoutes.newRecipe,
        builder: (context, state) => const RecipeFormPage(),
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (context, state) => RecipeDetailPage(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
    ],
  );
});
