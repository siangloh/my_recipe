
import './recipe.dart';

class RecipeService {
  final List<Recipe> _recipes = [];

  List<Recipe> getRecipes() => _recipes;

  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
  }

  void updateRecipe(Recipe recipe) {
    final index = _recipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _recipes[index] = recipe;
    }
  }

  void deleteRecipe(String id) {
    _recipes.removeWhere((r) => r.id == id);
  }
}
