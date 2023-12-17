/// Enum containing the sex of a human.
enum Sex { male, female }

/// Provide string getter for Sex enum.
extension SexExtension on Sex {
  String get string {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      default:
        throw Exception('Enum type: $this doesn\'t exist');
    }
  }
}

/// Enum describing the frequency at which the user exercises.
enum ExerciseFrequency { rarely, sometimes, regularly }

/// Provide string getter for ExerciseFrequency enum
extension ExerciseFrequencyExtension on ExerciseFrequency {
  String get string {
    switch (this) {
      case ExerciseFrequency.rarely:
        return 'Rarely';
      case ExerciseFrequency.sometimes:
        return 'Sometimes';
      case ExerciseFrequency.regularly:
        return 'Regularly';
      default:
        throw Exception('Enum type: $this doesn\'t exist.');
    }
  }
}
