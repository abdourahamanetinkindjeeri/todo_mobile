abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const recipes = '/recipes';
  static const newRecipe = '/recipes/new';
  static const favorites = '/favorites';

  static String recipeDetail(String recipeId) => '/recipes/$recipeId';
}
