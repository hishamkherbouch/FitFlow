import 'package:supabase_flutter/supabase_flutter.dart';

class NutritionRepository {
  NutritionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> addNutritionLog({
    required double calories,
    required double protein,
    double? carbs,
    double? fats,
  }) async {
    final payload = <String, dynamic>{
      'calories': calories,
      'protein': protein,
    };
    if (carbs != null) {
      payload['carbs'] = carbs;
    }
    if (fats != null) {
      payload['fats'] = fats;
    }

    await _client.from('nutrition_logs').insert(payload);
  }
}
