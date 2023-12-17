import 'package:chillout_hrm/util/enum.dart';

/// This class is used to represent the relevant aspects of a user.
class UserData {
  UserData({required this.sex, required this.frequency, required this.age});

  final Sex sex;
  final ExerciseFrequency frequency;
  final int age;
}

/// This class is used to estimate the target heart rate and max heart rate based on the information that was provided
/// in the [userData] object. Formulas are from here: https://www.verywellfit.com/maximum-heart-rate-1231221
class UserLimitEstimator {
  UserData userData;

  UserLimitEstimator({required this.userData});

  /// Provides an estimation of the target heart rate based on the information about the user in userData object.
  double get targetHeartRate {
    double result;
    if (userData.frequency == ExerciseFrequency.rarely) {
      // rare exercise => 64% to 74% of MHR according to source
      // for our purpose we take median
      result = maxHeartRate * 0.69;
    } else if (userData.frequency == ExerciseFrequency.sometimes) {
      // sporadic exercise => 74% to 84% of MHR
      result = maxHeartRate * 0.79;
    } else {
      // regular exercise => 80% to 91% of MHR
      result = maxHeartRate * 0.85;
    }
    // rounded result
    return double.parse(result.toStringAsFixed(1));
  }

  /// Provides an estimation of the maximum heart rate based on the information about the user in userData object.
  double get maxHeartRate {
    double result;
    if (userData.frequency == ExerciseFrequency.regularly) {
      // HUNT formula for regular exercise
      result = 211 - (0.64 * userData.age);
    } else if (userData.age >= 40) {
      // Tanaka formula
      result = 208 - (0.7 * userData.age);
    } else if (userData.sex == Sex.female) {
      // Gulati formula
      result = 206 - (0.88 * userData.age);
    } else {
      // Fox formula
      result = (220 - userData.age) * 1.0;
    }
    // rounded result
    return double.parse(result.toStringAsFixed(1));
  }
}
