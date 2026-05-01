class Exercise {
  const Exercise({
    required this.id,
    required this.workoutId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
  });

  final String id;
  final String workoutId;
  final String name;
  final int sets;
  final int reps;

  /// Weight in kilograms. Null if bodyweight.
  final double? weight;

  Exercise copyWith({
    String? id,
    String? workoutId,
    String? name,
    int? sets,
    int? reps,
    double? weight,
  }) {
    return Exercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }

  @override
  String toString() => 'Exercise($name, ${sets}x$reps, weight: $weight)';
}
