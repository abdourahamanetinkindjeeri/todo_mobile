import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/recipe.dart';
import '../providers/recipe_providers.dart';

class RecipeFormPage extends ConsumerStatefulWidget {
  const RecipeFormPage({super.key});

  @override
  ConsumerState<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends ConsumerState<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Plat');
  final _difficultyController = TextEditingController(text: 'Facile');
  final _timeController = TextEditingController(text: '30');
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _difficultyController.dispose();
    _timeController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRecipeControllerProvider);

    ref.listen(createRecipeControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle recette')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Ajoute une recette complète',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les ingrédients et les étapes doivent être saisis ligne par ligne.',
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: 'Nom de la recette',
                icon: Icons.restaurant_menu_rounded,
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_rounded,
                validator: Validators.required,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _imageUrlController,
                label: 'URL de l’image',
                icon: Icons.image_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _categoryController,
                      label: 'Catégorie',
                      icon: Icons.category_rounded,
                      validator: Validators.required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _difficultyController,
                      label: 'Difficulté',
                      icon: Icons.speed_rounded,
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _timeController,
                label: 'Temps de cuisson en minutes',
                icon: Icons.timer_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Saisis un nombre supérieur à 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _MultilineField(
                controller: _ingredientsController,
                label: 'Ingrédients, un par ligne',
                icon: Icons.shopping_basket_rounded,
              ),
              const SizedBox(height: 14),
              _MultilineField(
                controller: _stepsController,
                label: 'Étapes, une par ligne',
                icon: Icons.format_list_numbered_rounded,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Enregistrer la recette',
                icon: Icons.cloud_upload_rounded,
                isLoading: state.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final steps = _stepsController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (ingredients.isEmpty || steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins un ingrédient et une étape.')),
      );
      return;
    }

    final recipe = Recipe(
      id: '',
      name: _nameController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text.isEmpty
          ? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'
          : _imageUrlController.text,
      category: _categoryController.text,
      difficulty: _difficultyController.text,
      cookingTimeMinutes: int.parse(_timeController.text),
      ingredients: ingredients,
      steps: steps,
    );

    final success = await ref
        .read(createRecipeControllerProvider.notifier)
        .createRecipe(recipe);

    if (success && mounted) {
      context.go('/recipes');
    }
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _MultilineField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      validator: Validators.required,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 72),
          child: Icon(icon),
        ),
      ),
    );
  }
}
