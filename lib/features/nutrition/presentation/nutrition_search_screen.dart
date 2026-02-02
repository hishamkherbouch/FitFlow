import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../data/nutrition_repository.dart';
import '../data/open_food_facts_service.dart';

class NutritionSearchScreen extends StatefulWidget {
  const NutritionSearchScreen({super.key});

  @override
  State<NutritionSearchScreen> createState() => _NutritionSearchScreenState();
}

class _NutritionSearchScreenState extends State<NutritionSearchScreen> {
  final _queryController = TextEditingController();
  final _service = OpenFoodFactsService();
  final _repository = NutritionRepository();

  bool _isLoading = false;
  String? _error;
  List<Product> _results = [];
  Product? _selectedProduct;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = 'Enter a product name or barcode.';
        _results = [];
        _selectedProduct = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _selectedProduct = null;
    });

    try {
      final results = await _service.search(query);
      setState(() {
        _results = results;
        _error = results.isEmpty ? 'No results found.' : null;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _results = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double? _calories(Product product) => product.nutriments
      ?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams);
  double? _protein(Product product) =>
      product.nutriments?.getValue(Nutrient.proteins, PerSize.oneHundredGrams);
  double? _carbs(Product product) => product.nutriments
      ?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams);
  double? _fats(Product product) =>
      product.nutriments?.getValue(Nutrient.fat, PerSize.oneHundredGrams);

  bool _hasAllMacros(Product product) {
    return _calories(product) != null &&
        _protein(product) != null &&
        _carbs(product) != null &&
        _fats(product) != null;
  }

  Future<void> _logSelected() async {
    final product = _selectedProduct;
    if (product == null) return;

    final calories = _calories(product);
    final protein = _protein(product);
    final carbs = _carbs(product);
    final fats = _fats(product);

    if (calories == null || protein == null || carbs == null || fats == null) {
      _showSnack('Missing macro data for this item.');
      return;
    }

    try {
      await _repository.addNutritionLog(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
      );
      _showSnack('Logged to Supabase.');
    } catch (error) {
      _showSnack('Log failed: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                labelText: 'Product name or barcode',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(12),
            ElevatedButton(
              onPressed: _isLoading ? null : _search,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search'),
            ),
            const Gap(12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = _results[index];
                    final name = product.productName?.trim();
                    return ListTile(
                      leading: product.imageFrontUrl == null
                          ? const Icon(Icons.restaurant)
                          : Image.network(
                              product.imageFrontUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.restaurant),
                            ),
                      title: Text(name == null || name.isEmpty
                          ? 'Unknown food'
                          : name),
                      subtitle: Text(
                        _hasAllMacros(product)
                            ? 'kcal ${_calories(product)!.toStringAsFixed(0)} '
                                '• P ${_protein(product)!.toStringAsFixed(1)}g '
                                '• C ${_carbs(product)!.toStringAsFixed(1)}g '
                                '• F ${_fats(product)!.toStringAsFixed(1)}g'
                            : 'Macro data not available',
                      ),
                      onTap: () {
                        setState(() {
                          _selectedProduct = product;
                        });
                      },
                    );
                  },
                ),
              ),
            if (selected != null) ...[
              const Gap(12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        selected.productName ?? 'Selected item',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(8),
                      Text('Calories: ${_formatMacro(_calories(selected))}'),
                      Text('Protein: ${_formatMacro(_protein(selected))} g'),
                      Text('Carbs: ${_formatMacro(_carbs(selected))} g'),
                      Text('Fats: ${_formatMacro(_fats(selected))} g'),
                      const Gap(12),
                      ElevatedButton(
                        onPressed:
                            _hasAllMacros(selected) ? _logSelected : null,
                        child: const Text('Log to Supabase'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatMacro(double? value) {
    if (value == null) return 'N/A';
    return value.toStringAsFixed(1);
  }
}
