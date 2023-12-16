

/// Enum containing the sex of a human.
enum Sex {
  male, female
}

extension SexExtension on Sex {
  String get string {
    switch(this) {
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
enum ExerciseFrequency {
  rarely, sometimes, regularly
}

extension ExerciseFrequencyExtension on ExerciseFrequency {
  String get string {
    switch(this) {
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