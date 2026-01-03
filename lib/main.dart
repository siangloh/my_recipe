
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_recipe/ingredient.dart';
import 'package:my_recipe/recipe.dart';
import 'package:my_recipe/recipe_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Collection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecipeListScreen(),
    );
  }
}

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final RecipeService _recipeService = RecipeService();

  void _addRecipe(Recipe recipe) {
    setState(() {
      _recipeService.addRecipe(recipe);
    });
  }

  void _updateRecipe(Recipe recipe) {
    setState(() {
      _recipeService.updateRecipe(recipe);
    });
  }

  void _deleteRecipe(String id) {
    setState(() {
      _recipeService.deleteRecipe(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _recipeService.getRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
      ),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return ListTile(
            leading: recipe.recipeImage != null
                ? Image.file(recipe.recipeImage!, width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image),
            title: Text(recipe.recipeName),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: recipe, onDelete: _deleteRecipe, onUpdate: _updateRecipe),
                ),
              );
              if (result != null) {
                _updateRecipe(result);
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newRecipe = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditRecipeScreen()),
          );
          if (newRecipe != null) {
            _addRecipe(newRecipe);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final Function(String) onDelete;
  final Function(Recipe) onUpdate;

  const RecipeDetailScreen({super.key, required this.recipe, required this.onDelete, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.recipeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedRecipe = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditRecipeScreen(recipe: recipe),
                ),
              );
              if (updatedRecipe != null) {
                onUpdate(updatedRecipe);
                Navigator.pop(context, updatedRecipe);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete(recipe.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.recipeImage != null)
              Image.file(recipe.recipeImage!),
            const SizedBox(height: 16.0),
            const Text('Ingredients:', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            for (var ingredient in recipe.ingredients)
              Text('- ${ingredient.name}: ${ingredient.quantity}', style: const TextStyle(fontSize: 16.0)),
            const SizedBox(height: 16.0),
            const Text('Steps:', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            for (var step in recipe.cookingSteps)
              Text('- $step', style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}

class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddEditRecipeScreen({super.key, this.recipe});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _recipeName;
  late List<Ingredient> _ingredients;
  late List<String> _cookingSteps;
  File? _recipeImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _id = widget.recipe?.id ?? const Uuid().v4();
    _recipeName = widget.recipe?.recipeName ?? '';
    _ingredients = widget.recipe?.ingredients.map((i) => Ingredient(name: i.name, quantity: i.quantity)).toList() ?? [];
    _cookingSteps = widget.recipe?.cookingSteps ?? [];
    _recipeImage = widget.recipe?.recipeImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _recipeImage = File(pickedFile.path);
      });
    }
  }
  
  void _addIngredient() {
    setState(() {
      _ingredients.add(Ingredient(name: '', quantity: ''));
    });
  }
  
  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Add Recipe' : 'Edit Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _recipeName,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
                validator: (value) => value!.isEmpty ? 'Recipe name is required' : null,
                onSaved: (value) => _recipeName = value!,
              ),
              const SizedBox(height: 16.0),
              const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ..._ingredients.asMap().entries.map((entry) {
                int index = entry.key;
                Ingredient ingredient = entry.value;
                return Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: ingredient.name,
                        decoration: const InputDecoration(labelText: 'Ingredient Name'),
                        onChanged: (value) => ingredient.name = value,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        initialValue: ingredient.quantity,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        onChanged: (value) => ingredient.quantity = value,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: () => _removeIngredient(index),
                    )
                  ],
                );
              }).toList(),
              TextButton.icon(
                icon: const Icon(Icons.add), 
                label: const Text('Add Ingredient'),
                onPressed: _addIngredient,
              ),
              TextFormField(
                initialValue: _cookingSteps.join('\n'),
                decoration: const InputDecoration(labelText: 'Cooking Steps (one per line)'),
                maxLines: null,
                onSaved: (value) => _cookingSteps = value!.split('\n').map((e) => e.trim()).toList(),
              ),
              const SizedBox(height: 20),
              _recipeImage == null
                  ? const Text('No image selected.')
                  : Image.file(_recipeImage!),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final recipe = Recipe(
                      id: _id,
                      recipeName: _recipeName,
                      ingredients: _ingredients,
                      cookingSteps: _cookingSteps,
                      recipeImage: _recipeImage,
                    );
                    Navigator.pop(context, recipe);
                  }
                },
                child: const Text('Save Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
