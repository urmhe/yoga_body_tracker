
import 'package:chillout_hrm/util/enum.dart';

/// This class is used to represent the relevant aspects of a user
class UserData {

  UserData({required this.sex, required this.frequency, required this.age});

  final Sex sex;
  final ExerciseFrequency frequency;
  final int age;
}

class UserDataEvaluator {}