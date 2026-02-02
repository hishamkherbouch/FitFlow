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
      const PageSize(size: 20),
    ];

    final config = ProductSearchQueryConfiguration(
      parametersList: parameters,
      fields: [
        ProductField.NAME,
        ProductField.NUTRIMENTS,
        ProductField.IMAGE_FRONT_URL,
        ProductField.BARCODE,
      ],
      language: _language,
      country: _country,
      version: ProductQueryVersion.v3,
    );

    final result = await OpenFoodAPIClient.searchProducts(
      _buildUser(),
      config,
    );

    return result.products ?? [];
  }

  User _buildUser() => const User(userId: 'fitflow_ai', password: '');

  bool _isBarcode(String query) {
    return RegExp(r'^\d{8,14}$').hasMatch(query);
  }
}
