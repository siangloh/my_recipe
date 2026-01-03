
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_recipe/ingredient.dart';
import 'package:my_recipe/recipe.dart';
import 'package:my_recipe/services/recipe_service.dart';
import 'package:my_recipe/utils/opencv_helper.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

// Defines the color palette for the "Warm Gourmet" theme as per Rules.md
class AppTheme {
  static const Color background = Color(0xFFFBF9F6); // Warm Parchment
  static const Color primary = Color(0xFF5D4037);    // Dark Brown / Espresso
  static const Color accent = Color(0xFFFF9800);      // Orange
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );

    return MaterialApp(
      title: 'Recipe Collection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.background,
        primaryColor: AppTheme.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.accent,
          background: AppTheme.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.primary),
          titleTextStyle: TextStyle(
            color: AppTheme.primary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0, // Disabled to use custom shadow with BoxDecoration
          shape: roundedShape,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: roundedShape,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: AppTheme.primary),
        ),
        useMaterial3: true,
      ),
      home: const RecipeListScreen(),
    );
  }
}

// A reusable shadow container as per Rules.md
class ShadowContainer extends StatelessWidget {
  final Widget child;
  const ShadowContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
  String _searchQuery = '';
  bool _isGridView = false;

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

  void _navigateToDetail(Recipe recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe, onDelete: _deleteRecipe, onUpdate: _updateRecipe),
      ),
    );
    if (result != null && mounted) {
      _updateRecipe(result);
    }
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ShadowContainer(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: recipe.recipeImage != null
                  ? Image.file(recipe.recipeImage!, width: 50, height: 50, fit: BoxFit.cover)
                  : Container(width: 50, height: 50, color: AppTheme.background, child: const Icon(Icons.image, color: AppTheme.primary)),
              ),
              title: Text(recipe.recipeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              onTap: () => _navigateToDetail(recipe),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return ShadowContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _navigateToDetail(recipe),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: recipe.recipeImage != null
                        ? Image.file(recipe.recipeImage!, fit: BoxFit.cover)
                        : Container(color: AppTheme.background, child: const Icon(Icons.image, size: 50, color: AppTheme.primary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(recipe.recipeName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecipes = _recipeService.getRecipes();
    final filteredRecipes = allRecipes
        .where((recipe) =>
            recipe.recipeName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search Recipes',
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
            ),
          ),
          Expanded(
            child: _isGridView
                ? _buildRecipeGrid(filteredRecipes)
                : _buildRecipeList(filteredRecipes),
          ),
        ],
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
        backgroundColor: AppTheme.accent,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
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
              if (updatedRecipe != null && context.mounted) {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.recipeImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(recipe.recipeImage!),
              ),
            const SizedBox(height: 24.0),
            const Text('Ingredients:', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 8.0),
            for (var ingredient in recipe.ingredients)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('• ${ingredient.name}: ${ingredient.quantity} ${ingredient.unit}', style: const TextStyle(fontSize: 16.0, color: AppTheme.primary)),
              ),
            const SizedBox(height: 24.0),
            const Text('Steps:', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 8.0),
            for (var i = 0; i < recipe.cookingSteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('${i + 1}. ${recipe.cookingSteps[i]}', style: const TextStyle(fontSize: 16.0, color: AppTheme.primary)),
              ),
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
  bool _isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  final List<String> _units = ['g', 'kg', 'ml', 'l', 'tsp', 'tbsp', 'cup', 'pcs'];

  @override
  void initState() {
    super.initState();
    _id = widget.recipe?.id ?? const Uuid().v4();
    _recipeName = widget.recipe?.recipeName ?? '';
    _ingredients = widget.recipe?.ingredients.map((i) => Ingredient(name: i.name, quantity: i.quantity, unit: i.unit)).toList() ?? [];
    _cookingSteps = widget.recipe?.cookingSteps ?? [];
    _recipeImage = widget.recipe?.recipeImage;
    if (_ingredients.isEmpty) {
      _ingredients.add(Ingredient(name: '', quantity: 0, unit: _units.first));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() { _isProcessing = true; });
      final imageFile = File(pickedFile.path);
      final imageData = await imageFile.readAsBytes();
      
      // Process the image in an isolate using the new helper and function name
      final processedImageData = await compute(processImageForRecipe, imageData);
      
      await imageFile.writeAsBytes(processedImageData);
      
      setState(() {
        _recipeImage = imageFile;
        _isProcessing = false;
      });
    }
  }
  
  void _addIngredient() {
    setState(() {
      _ingredients.add(Ingredient(name: '', quantity: 0, unit: _units.first));
    });
  }
  
  void _removeIngredient(int index) {
    if (_ingredients.length > 1) {
      setState(() {
        _ingredients.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Add Recipe' : 'Edit Recipe'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 80), // Space for save button
                children: [
                  const Text('Recipe Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _recipeName,
                    validator: (value) => value!.isEmpty ? 'Recipe name is required' : null,
                    onSaved: (value) => _recipeName = value!,
                  ),
                  const SizedBox(height: 24),
                  const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  ..._ingredients.asMap().entries.map((entry) {
                    int index = entry.key;
                    Ingredient ingredient = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ShadowContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(flex: 3, child: TextFormField(initialValue: ingredient.name, decoration: const InputDecoration(labelText: 'Name'), onChanged: (v) => ingredient.name = v)),
                              const SizedBox(width: 8.0),
                              Expanded(flex: 2, child: TextFormField(initialValue: ingredient.quantity.toString(), decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number, onChanged: (v) => ingredient.quantity = double.tryParse(v) ?? 0)),
                              const SizedBox(width: 8.0),
                              Expanded(flex: 2, child: DropdownButtonFormField<String>(value: ingredient.unit, items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(), onChanged: (v) => ingredient.unit = v!, decoration: const InputDecoration(labelText: 'Unit'))),
                              if (_ingredients.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeIngredient(index)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline), 
                    label: const Text('Add Ingredient'),
                    onPressed: _addIngredient,
                  ),
                  const SizedBox(height: 24),
                  const Text('Cooking Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _cookingSteps.join('\n'),
                    decoration: const InputDecoration(hintText: '1. First step...\n2. Second step...'),
                    maxLines: null,
                    onSaved: (value) => _cookingSteps = value!.split('\n').where((s) => s.trim().isNotEmpty).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  ShadowContainer(
                    child: AspectRatio(
                      aspectRatio: 16/9,
                      child: _recipeImage == null
                          ? const Center(child: Text('No image selected.', style: TextStyle(color: AppTheme.primary)))
                          : ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_recipeImage!, fit: BoxFit.cover)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: AppTheme.background.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            final recipe = Recipe(
              id: _id,
              recipeName: _recipeName,
              ingredients: _ingredients.where((i) => i.name.isNotEmpty).toList(),
              cookingSteps: _cookingSteps,
              recipeImage: _recipeImage,
            );
            Navigator.pop(context, recipe);
          }
        },
        label: const Text('Save Recipe'),
        icon: const Icon(Icons.save),
        backgroundColor: AppTheme.accent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
