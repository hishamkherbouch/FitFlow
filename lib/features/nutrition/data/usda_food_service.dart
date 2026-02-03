import 'dart:convert';
import 'package:http/http.dart' as http;

/// Represents a food item from USDA FoodData Central
class UsdaFoodItem {
  const UsdaFoodItem({
    required this.fdcId,
    required this.description,
    required this.brandOwner,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.servingSize,
    this.servingSizeUnit,
  });

  final int fdcId;
  final String description;
  final String? brandOwner;
  final double calories; // per 100g
  final double protein; // per 100g
  final double carbs; // per 100g
  final double fats; // per 100g
  final double? servingSize;
  final String? servingSizeUnit;

  String get displayName {
    if (brandOwner != null && brandOwner!.isNotEmpty) {
      return '$description ($brandOwner)';
    }
    return description;
  }

  bool get isGeneric => brandOwner == null || brandOwner!.isEmpty;
}

class UsdaFoodService {
  UsdaFoodService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  // Get free API key from: https://fdc.nal.usda.gov/api-guide.html
  // For now using DEMO_KEY which has limited requests
  static const String _apiKey = 'fsm5UjFNQP6h3306BThpDZuZkMjQfCVGPoM4XX2s';

  /// Search for foods in USDA FoodData Central
  /// Returns foods with nutrition data per 100g
  /// Note: Get a free API key from https://fdc.nal.usda.gov/api-guide.html for production use
  Future<List<UsdaFoodItem>> search(String query) async {
    // USDA API uses POST for search with JSON body
    final uri = Uri.parse('$_baseUrl/foods/search?api_key=$_apiKey');
    
    final requestBody = jsonEncode({
      'query': query,
      'dataType': ['Foundation', 'SR Legacy', 'Branded'], // Include Branded to get more results
      'pageSize': 50,
      'pageNumber': 1,
    });

    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    
    if (response.statusCode != 200) {
      final errorBody = response.body.length > 200 
          ? '${response.body.substring(0, 200)}...' 
          : response.body;
      throw Exception('USDA API request failed: ${response.statusCode}\n$errorBody');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final foods = data['foods'] as List<dynamic>? ?? [];
    final totalHits = data['totalHits'] as int? ?? 0;

    // Debug: Print what we got
    print('USDA API Response: totalHits=$totalHits, foods count=${foods.length}');

    if (foods.isEmpty) {
      print('No foods in response. Full response keys: ${data.keys.toList()}');
      return [];
    }
    
    // Debug: Print the first food to see its structure
    if (foods.isNotEmpty) {
      print('First food JSON: ${jsonEncode(foods.first)}');
    }

    final results = <UsdaFoodItem>[];

    for (int i = 0; i < foods.length; i++) {
      final food = foods[i];
      try {
        // Debug the first item
        final item = _parseFood(food as Map<String, dynamic>, debug: i == 0);
        if (item != null) {
          results.add(item);
        } else {
          if (i == 0) print('Failed to parse first food: ${food['description'] ?? 'unknown'}');
        }
      } catch (e) {
        // Skip foods that can't be parsed, but continue processing others
        if (i == 0) print('Error parsing first food: $e');
        continue;
      }
    }
    
    print('Successfully parsed ${results.length} foods from ${foods.length} total');

    // Sort: generic foods (no brand) first, then by relevance to query
    results.sort((a, b) {
      // 1. Generic items first
      if (a.isGeneric && !b.isGeneric) return -1;
      if (!a.isGeneric && b.isGeneric) return 1;
      
      final queryLower = query.toLowerCase();
      final queryWords = queryLower.split(' ').where((w) => w.isNotEmpty).toList();
      final aName = a.description.toLowerCase();
      final bName = b.description.toLowerCase();
      
      // 2. Exact matches (case insensitive)
      if (aName == queryLower && bName != queryLower) return -1;
      if (aName != queryLower && bName == queryLower) return 1;
      
      // 3. Starts with query (e.g. "Chicken" starts with "chicken")
      final aStarts = aName.startsWith(queryLower);
      final bStarts = bName.startsWith(queryLower);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      
      // 4. Starts with first word of query (e.g. "Chicken..." matches "chicken breast")
      if (queryWords.isNotEmpty) {
        final firstWord = queryWords.first;
        final aStartsFirst = aName.startsWith(firstWord);
        final bStartsFirst = bName.startsWith(firstWord);
        if (aStartsFirst && !bStartsFirst) return -1;
        if (!aStartsFirst && bStartsFirst) return 1;
      }
      
      // 5. Contains all query words
      final aAllWords = queryWords.every((w) => aName.contains(w));
      final bAllWords = queryWords.every((w) => bName.contains(w));
      if (aAllWords && !bAllWords) return -1;
      if (!aAllWords && bAllWords) return 1;
      
      // 6. Shorter names are usually more generic/better
      return a.description.length.compareTo(b.description.length);
    });

    return results;
  }

  UsdaFoodItem? _parseFood(Map<String, dynamic> food, {bool debug = false}) {
    final fdcId = food['fdcId'] as int?;
    final description = food['description'] as String?;
    final brandOwner = food['brandOwner'] as String?;

    if (fdcId == null || description == null || description.isEmpty) {
      return null;
    }

    // Extract nutrients from foodNutrients array
    final foodNutrients = food['foodNutrients'] as List<dynamic>? ?? [];
    
    if (foodNutrients.isEmpty) {
      print('No foodNutrients for $description');
      return null;
    }
    
    double? calories;
    double? protein;
    double? carbs;
    double? fats;

    // Get the serving size to convert nutrients to per 100g if needed
    final servingSize = food['servingSize'] as num?;
    final servingSizeUnit = food['servingSizeUnit'] as String?;
    final servingSizeGrams = servingSize?.toDouble() ?? 100.0; // Default to 100g if not specified
    final conversionFactor = 100.0 / servingSizeGrams;

    for (final nutrient in foodNutrients) {
      final nutrientMap = nutrient as Map<String, dynamic>;
      final nutrientObj = nutrientMap['nutrient'] as Map<String, dynamic>?;
      
      // Nutrients can be nested in 'nutrient' object (Foundation foods) 
      // or at the root (Branded foods)
      final nutrientId = (nutrientObj?['id'] as int?) ?? (nutrientMap['nutrientId'] as int?);
      final nutrientNumber = (nutrientObj?['number'] as String?) ?? (nutrientMap['nutrientNumber'] as String?);
      final nutrientName = (nutrientObj?['name'] as String?) ?? (nutrientMap['nutrientName'] as String?);
      
      // Try both 'value' and 'amount' fields
      final value = nutrientMap['value'] as num?;
      final amount = nutrientMap['amount'] as num?;
      final nutrientValue = value ?? amount;
      
      if (nutrientValue == null) continue;

      // Convert to per 100g if needed (if serving size is not 100g)
      final valuePer100g = nutrientValue.toDouble() * conversionFactor;

      // Debug: Print nutrients for the item to see structure
      if (debug) {
        print('Debug nutrients for ${description} (ID: $fdcId):');
        print(' - $nutrientName (ID: $nutrientId, Num: $nutrientNumber): $nutrientValue (per 100g: $valuePer100g)');
      }

      // USDA nutrient IDs:
      // 1008 = Energy (kcal) 
      // 1003 = Protein
      // 1005 = Carbohydrate, by difference
      // 1004 = Total lipid (fat)
      if (nutrientId == 1008 || nutrientNumber == '208' || 
          (nutrientName?.toLowerCase().contains('energy') ?? false)) {
        calories = valuePer100g;
      } else if (nutrientId == 1003 || nutrientNumber == '203' || 
                 (nutrientName?.toLowerCase() == 'protein')) {
        protein = valuePer100g;
      } else if (nutrientId == 1005 || nutrientNumber == '205' || 
                 (nutrientName?.toLowerCase().contains('carbohydrate') ?? false)) {
        carbs = valuePer100g;
      } else if (nutrientId == 1004 || nutrientNumber == '204' || 
                 (nutrientName?.toLowerCase().contains('total lipid') ?? false)) {
        fats = valuePer100g;
      }
    }

    // Relaxed check: Return item even if some macros are missing
    return UsdaFoodItem(
      fdcId: fdcId,
      description: description,
      brandOwner: brandOwner,
      calories: calories ?? 0.0,
      protein: protein ?? 0.0,
      carbs: carbs ?? 0.0,
      fats: fats ?? 0.0,
      servingSize: servingSize?.toDouble(),
      servingSizeUnit: servingSizeUnit,
    );
  }
}
