import 'exercise.dart';

class TemplateExercise {
  TemplateExercise({
    required this.exercise,
    required this.sets,
    this.restSeconds,
  });

  final Exercise exercise;
  final int sets;
  final int? restSeconds;
}

class WorkoutTemplate {
  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.exercises,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final List<TemplateExercise> exercises;

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json,
    List<TemplateExercise> exercises,
  ) {
    return WorkoutTemplate(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: (json['title'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      exercises: exercises,
    );
  }
}
