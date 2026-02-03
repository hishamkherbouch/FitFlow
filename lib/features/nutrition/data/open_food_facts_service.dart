import 'package:openfoodfacts/openfoodfacts.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({
    OpenFoodFactsLanguage? language,
    OpenFoodFactsCountry? country,
  })  : _language = language ?? OpenFoodFactsLanguage.ENGLISH,
        _country = country ?? OpenFoodFactsCountry.USA {
    OpenFoodAPIConfiguration.userAgent ??= UserAgent(
      name: 'fitflow_ai',
      version: '0.1.0',
      system: 'flutter',
    );
  }

  final OpenFoodFactsLanguage _language;
  final OpenFoodFactsCountry _country;

  Future<List<Product>> search(String query) async {
    final parameters = <Parameter>[
      _isBarcode(query)
          ? BarcodeParameter(query)
          : SearchTerms(terms: [query]),
      const PageSize(size: 50), // Get more results to filter/sort
      const SortBy(option: SortOption.POPULARITY), // Sort by popularity first
    ];

    final config = ProductSearchQueryConfiguration(
      parametersList: parameters,
      fields: [
        ProductField.NAME,
        ProductField.NUTRIMENTS,
        ProductField.BARCODE,
        ProductField.BRANDS,
        ProductField.STATES_TAGS,
      ],
      language: _language,
      country: _country,
      version: ProductQueryVersion.v3,
    );

    final result = await OpenFoodAPIClient.searchProducts(
      _buildUser(),
      config,
    );

    final products = result.products ?? [];
    
    // Sort to prioritize generic items (no brand or generic states)
    return _sortForGenericItems(products);
  }

  List<Product> _sortForGenericItems(List<Product> products) {
    // Sort products to prioritize generic items
    products.sort((a, b) {
      final aIsGeneric = _isGenericProduct(a);
      final bIsGeneric = _isGenericProduct(b);
      
      // Generic items first
      if (aIsGeneric && !bIsGeneric) return -1;
      if (!aIsGeneric && bIsGeneric) return 1;
      
      // If both generic or both branded, maintain original order (popularity)
      return 0;
    });
    
    return products;
  }

  bool _isGenericProduct(Product product) {
    // Check if product has no brand (brands is a String, brandsTags is List<String>)
    final hasNoBrand = (product.brands == null || product.brands!.trim().isEmpty) &&
                      (product.brandsTags == null || product.brandsTags!.isEmpty);
    
    // Check for generic states tags
    final states = product.statesTags ?? [];
    final isGenericState = states.any((tag) => 
      tag.toLowerCase().contains('generic') ||
      tag.toLowerCase().contains('en:generic')
    );
    
    // Also check if product name suggests it's generic (no brand name in title)
    final name = product.productName?.toLowerCase() ?? '';
    final brandString = product.brands?.toLowerCase() ?? '';
    final brandTags = product.brandsTags?.map((b) => b.toLowerCase()).toList() ?? [];
    final hasBrandInName = (brandString.isNotEmpty && name.contains(brandString)) ||
                          brandTags.any((brand) => 
                            brand.isNotEmpty && name.contains(brand)
                          );
    
    return (hasNoBrand || isGenericState) && !hasBrandInName;
  }

  User _buildUser() => const User(userId: 'fitflow_ai', password: '');

  bool _isBarcode(String query) {
    return RegExp(r'^\d{8,14}$').hasMatch(query);
  }
}
