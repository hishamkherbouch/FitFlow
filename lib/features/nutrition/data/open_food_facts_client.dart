import 'dart:convert';

import 'package:http/http.dart' as http;

class FoodSearchItem {
  const FoodSearchItem({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    this.imageUrl,
  });

  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final String? imageUrl;
}

class OpenFoodFactsClient {
  OpenFoodFactsClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<List<FoodSearchItem>> searchFoods(String query) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/cgi/search.pl',
      <String, String>{
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '20',
      },
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Open Food Facts request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>? ?? [];

    return products
        .map((product) => _parseProduct(product as Map<String, dynamic>))
        .where((item) => item != null)
        .cast<FoodSearchItem>()
        .toList();
  }

  FoodSearchItem? _parseProduct(Map<String, dynamic> product) {
    final name = (product['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }

    final nutriments =
        (product['nutriments'] as Map<String, dynamic>?) ?? const {};
    final calories = _parseDouble(nutriments['energy-kcal_100g']);
    final protein = _parseDouble(nutriments['proteins_100g']);
    if (calories == null || protein == null) {
      return null;
    }

    return FoodSearchItem(
      name: name,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      imageUrl: product['image_url'] as String?,
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
