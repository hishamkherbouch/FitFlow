import 'package:supabase_flutter/supabase_flutter.dart';

import 'exercise.dart';
import 'workout_template.dart';

class WorkoutTemplateRepository {
  WorkoutTemplateRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<String> _ensureAuthenticated() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      return userId;
    }
    final response = await _client.auth.signInAnonymously();
    final anonId = response.user?.id;
    if (anonId == null) {
      throw StateError('Unable to authenticate user.');
    }
    return anonId;
  }

  Future<void> createTemplate({
    required String title,
    required List<TemplateExercise> exercises,
  }) async {
    final userId = await _ensureAuthenticated();
    final template = await _client
        .from('workout_templates')
        .insert({
          'user_id': userId,
          'title': title,
        })
        .select()
        .single();

    final templateId = template['id'].toString();
    if (exercises.isNotEmpty) {
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < exercises.length; i++) {
        rows.add({
          'template_id': templateId,
          'exercise_id': exercises[i].exercise.id,
          'position': i,
          'sets': exercises[i].sets,
          'rest_seconds': exercises[i].restSeconds,
        });
      }
      await _client.from('workout_template_exercises').insert(rows);
    }
  }

  Future<List<WorkoutTemplate>> getTemplates() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final templates = await _client
        .from('workout_templates')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final templateIds =
        (templates as List).map((row) => row['id']).toList();
    if (templateIds.isEmpty) {
      return [];
    }

    final joinRows = await _client
        .from('workout_template_exercises')
        .select(
          'template_id, position, sets, rest_seconds, exercises ( id, name, equipment, target_muscle, body_part )',
        )
        .inFilter('template_id', templateIds)
        .order('position');

    final exercisesByTemplate = <String, List<TemplateExercise>>{};
    for (final row in (joinRows as List)) {
      final templateId = row['template_id'].toString();
      final exerciseJson = row['exercises'] as Map<String, dynamic>;
      final exercise = Exercise.fromJson(exerciseJson);
      final sets = (row['sets'] as int?) ?? 3;
      final restSeconds = row['rest_seconds'] as int?;
      exercisesByTemplate.putIfAbsent(templateId, () => []).add(
        TemplateExercise(
          exercise: exercise,
          sets: sets,
          restSeconds: restSeconds,
        ),
      );
    }

    return (templates as List)
        .map((row) {
          final id = row['id'].toString();
          return WorkoutTemplate.fromJson(
            row as Map<String, dynamic>,
            exercisesByTemplate[id] ?? [],
          );
        })
        .toList();
  }

  Future<void> updateTemplateTitle({
    required String templateId,
    required String title,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required.');
    }
    await _client
        .from('workout_templates')
        .update({'title': title})
        .eq('id', templateId)
        .eq('user_id', userId);
  }

  Future<void> deleteTemplate(String templateId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required.');
    }
    await _client
        .from('workout_templates')
        .delete()
        .eq('id', templateId)
        .eq('user_id', userId);
  }

  Future<void> replaceTemplateExercises({
    required String templateId,
    required List<TemplateExercise> exercises,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required.');
    }

    await _client
        .from('workout_template_exercises')
        .delete()
        .eq('template_id', templateId);

    if (exercises.isEmpty) {
      return;
    }

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < exercises.length; i++) {
      rows.add({
        'template_id': templateId,
        'exercise_id': exercises[i].exercise.id,
        'position': i,
        'sets': exercises[i].sets,
        'rest_seconds': exercises[i].restSeconds,
      });
    }
    await _client.from('workout_template_exercises').insert(rows);
  }
}
