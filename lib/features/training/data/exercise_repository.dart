import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise.dart';

class ExerciseRepository {
  ExerciseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Exercise>> searchExercises(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    final response = await _client
        .from('exercises')
        .select()
        .ilike('name', '%$trimmed%')
        .order('name')
        .limit(50);

    return (response as List)
        .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Exercise> createExercise({
    required String name,
    required String equipment,
    required String targetMuscle,
  }) async {
    final payload = {
      'name': name,
      'equipment': equipment,
      'target_muscle': targetMuscle,
    };

    final response = await _client
        .from('exercises')
        .insert(payload)
        .select()
        .single();

    return Exercise.fromJson(response as Map<String, dynamic>);
  }
}
