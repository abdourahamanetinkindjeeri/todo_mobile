import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' || location == '/register';
      final isSplashRoute = location == '/';

      // Tant que Firebase Auth n'a pas encore répondu, on reste sur le splash.
      if (authState.isLoading || authState.hasError) {
        return isSplashRoute ? null : '/';
      }

      final user = authState.valueOrNull;

      // Correction importante : après un login réussi ou au redémarrage de l'app,
      // la route '/' ne doit pas rester bloquée sur le spinner du SplashPage.
      if (isSplashRoute) {
        return user == null ? '/login' : '/recipes';
      }

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return '/recipes';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/recipes',
        builder: (context, state) => const RecipeListPage(),
      ),
      GoRoute(
        path: '/recipes/new',
        builder: (context, state) => const RecipeFormPage(),
      ),
      GoRoute(
        path: '/recipes/:id',
        builder: (context, state) => RecipeDetailPage(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
    ],
  );
});
