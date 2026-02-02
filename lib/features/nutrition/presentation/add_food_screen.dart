import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../data/nutrition_repository.dart';
import '../data/open_food_facts_client.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _queryController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _client = OpenFoodFactsClient();
  final _repository = NutritionRepository();

  bool _isLoading = false;
  String? _error;
  List<FoodSearchItem> _results = [];

  @override
  void dispose() {
    _queryController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = 'Enter a food to search.';
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _client.searchFoods(query);
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

  double? _parseGrams() {
    final text = _gramsController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _saveFood(FoodSearchItem item) async {
    final grams = _parseGrams();
    if (grams == null || grams <= 0) {
      _showSnack('Enter a valid grams amount.');
      return;
    }

    final calories = item.caloriesPer100g * grams / 100;
    final protein = item.proteinPer100g * grams / 100;

    try {
      await _repository.addNutritionLog(
        calories: calories,
        protein: protein,
      );
      _showSnack('Saved ${item.name}.');
    } catch (error) {
      _showSnack('Save failed: $error');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
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
                labelText: 'Search food',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(12),
            TextField(
              controller: _gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Grams (default 100g)',
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
            const Gap(16),
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
                    final item = _results[index];
                    return ListTile(
                      leading: item.imageUrl == null
                          ? const Icon(Icons.restaurant)
                          : Image.network(
                              item.imageUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.restaurant),
                            ),
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.caloriesPer100g.toStringAsFixed(0)} kcal / '
                        '${item.proteinPer100g.toStringAsFixed(1)} g protein '
                        'per 100g',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _saveFood(item),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
