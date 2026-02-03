import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'nutrition_log.dart';

class NutritionRepository {
  NutritionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // Shared broadcast stream for all instances to notify listeners of changes
  static final _updateController = StreamController<void>.broadcast();
  Stream<void> get onLogChanged => _updateController.stream;

  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<String> _ensureAuthenticated() async {
    var userId = _currentUserId;
    if (userId != null) {
      return userId;
    }

    // Try to sign in anonymously
    try {
      final response = await _client.auth.signInAnonymously();
      userId = response.user?.id;
      if (userId != null) {
        return userId;
      }
    } catch (e) {
      // Fall through to throw error
    }

    throw StateError(
      'Authentication required. Please enable Anonymous authentication '
      'in your Supabase dashboard: Authentication > Providers > Anonymous',
    );
  }

  Future<void> addNutritionLog({
    required String foodName,
    required double grams,
    String? servingLabel,
    String? source,
    required double calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    final userId = await _ensureAuthenticated();

    final payload = <String, dynamic>{
      'user_id': userId,
      'logged_at': DateTime.now().toIso8601String(),
      'food_name': foodName,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };

    if (servingLabel != null) {
      payload['serving_label'] = servingLabel;
    }
    if (source != null) {
      payload['source'] = source;
    }

    await _client.from('nutrition_logs').insert(payload);
    _updateController.add(null);
  }

  Future<List<NutritionLog>> getLogsForDay(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('nutrition_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', startOfDay.toIso8601String())
        .lt('logged_at', endOfDay.toIso8601String())
        .order('logged_at', ascending: false);

    return (response as List)
        .map((json) => NutritionLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<NutritionLog>> getLogsForLastDays(int days) async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final response = await _client
        .from('nutrition_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', cutoffDate.toIso8601String())
        .order('logged_at', ascending: false);

    return (response as List)
        .map((json) => NutritionLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateNutritionLog({
    required String id,
    double? grams,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
  }) async {
    final userId = await _ensureAuthenticated();

    final payload = <String, dynamic>{};
    if (grams != null) payload['grams'] = grams;
    if (calories != null) payload['calories'] = calories;
    if (protein != null) payload['protein'] = protein;
    if (carbs != null) payload['carbs'] = carbs;
    if (fats != null) payload['fats'] = fats;

    await _client
        .from('nutrition_logs')
        .update(payload)
        .eq('id', id)
        .eq('user_id', userId);
    _updateController.add(null);
  }

  Future<void> deleteNutritionLog(String id) async {
    final userId = await _ensureAuthenticated();

    await _client
        .from('nutrition_logs')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
    _updateController.add(null);
  }
}
