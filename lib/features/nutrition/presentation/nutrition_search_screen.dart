import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/nutrition_repository.dart';
import '../data/usda_food_service.dart';

class NutritionSearchScreen extends StatefulWidget {
  const NutritionSearchScreen({super.key});

  @override
  State<NutritionSearchScreen> createState() => _NutritionSearchScreenState();
}

class _NutritionSearchScreenState extends State<NutritionSearchScreen> {
  final _queryController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  final _service = UsdaFoodService();
  final _repository = NutritionRepository();

  bool _isLoading = false;
  String? _error;
  List<UsdaFoodItem> _results = [];
  UsdaFoodItem? _selectedProduct;
  double _amountGrams = 100.0;

  @override
  void dispose() {
    _queryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = 'Enter a food name to search.';
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
        if (results.isEmpty) {
          _error = 'No results found. Try a different search term.';
        } else {
          _error = null;
        }
      });
    } catch (error) {
      setState(() {
        _error = 'Search failed: ${error.toString()}';
        _results = [];
      });
      // Print error for debugging
      debugPrint('USDA Search Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logSelected() async {
    final product = _selectedProduct;
    if (product == null) return;

    final amount = _amountGrams;
    final ratio = amount / 100.0;

    final calories = product.calories * ratio;
    final protein = product.protein * ratio;
    final carbs = product.carbs * ratio;
    final fats = product.fats * ratio;

    try {
      await _repository.addNutritionLog(
        foodName: product.description,
        grams: amount,
        servingLabel: amount == 100.0 ? null : '${amount.toStringAsFixed(0)}g',
        source: 'usda',
        calories: calories,
        protein: protein,
        carbs: carbs,
        fats: fats,
      );
      _showSnack('Logged successfully!');
      setState(() {
        _selectedProduct = null;
        _amountController.text = '100';
        _amountGrams = 100.0;
      });
    } catch (error) {
      _showSnack('Log failed: $error');
    }
  }

  void _updateAmount(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        _amountGrams = parsed;
      });
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
                labelText: 'Search foods (e.g., chicken breast, rice, apple)',
                border: OutlineInputBorder(),
                hintText: 'Try: chicken breast, brown rice, banana...',
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
                    return ListTile(
                      leading: Icon(
                        product.isGeneric ? Icons.restaurant : Icons.shopping_bag,
                        color: product.isGeneric 
                            ? Theme.of(context).colorScheme.primary 
                            : null,
                      ),
                      title: Text(product.description),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.brandOwner != null && product.brandOwner!.isNotEmpty)
                            Text(
                              product.brandOwner!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'kcal ${product.calories.toStringAsFixed(0)} '
                            '• P ${product.protein.toStringAsFixed(1)}g '
                            '• C ${product.carbs.toStringAsFixed(1)}g '
                            '• F ${product.fats.toStringAsFixed(1)}g (per 100g)',
                          ),
                        ],
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
                        selected.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (selected.brandOwner != null && selected.brandOwner!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            selected.brandOwner!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const Gap(12),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (grams)',
                          border: OutlineInputBorder(),
                          suffixText: 'g',
                        ),
                        onChanged: _updateAmount,
                      ),
                      const Gap(12),
                      Text(
                        'Per ${_amountGrams.toStringAsFixed(0)}g:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Gap(4),
                      Text(
                        'Calories: ${(selected.calories * _amountGrams / 100).toStringAsFixed(0)}',
                      ),
                      Text(
                        'Protein: ${(selected.protein * _amountGrams / 100).toStringAsFixed(1)} g',
                      ),
                      Text(
                        'Carbs: ${(selected.carbs * _amountGrams / 100).toStringAsFixed(1)} g',
                      ),
                      Text(
                        'Fats: ${(selected.fats * _amountGrams / 100).toStringAsFixed(1)} g',
                      ),
                      const Gap(12),
                      ElevatedButton(
                        onPressed: _logSelected,
                        child: const Text('Log Food'),
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
