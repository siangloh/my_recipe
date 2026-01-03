
import 'dart:io';
import 'package:my_recipe/ingredient.dart';

class Recipe {
  String id;
  String recipeName;
  List<Ingredient> ingredients;
  List<String> cookingSteps;
  File? recipeImage;

  Recipe({
    required this.id,
    required this.recipeName,
    required this.ingredients,
    required this.cookingSteps,
    this.recipeImage,
  });
}
