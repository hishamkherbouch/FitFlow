class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.equipment,
    required this.targetMuscle,
    this.bodyPart,
  });

  final String id;
  final String name;
  final String equipment;
  final String targetMuscle;
  final String? bodyPart;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      equipment: (json['equipment'] as String?) ?? '',
      targetMuscle: (json['target_muscle'] as String?) ?? '',
      bodyPart: json['body_part'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'equipment': equipment,
      'target_muscle': targetMuscle,
      if (bodyPart != null) 'body_part': bodyPart,
    };
  }
}
