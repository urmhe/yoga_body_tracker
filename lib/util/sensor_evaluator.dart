import 'package:tuple/tuple.dart';

class SensorEval {
  SensorEval();

  // buffer size of the lists that track the values for the average
  static const bufferLimit = 512;

  final List<double> _heartRateBuffer = [];
  final List<double> _bodyTempBuffer = [];

  double _heartRateSum = 0;
  double _bodyTempSum = 0;

  /// calculates the new average heart rate based on the given new value
  double _getHeartRateAvg(double newValue) {
    if(_heartRateBuffer.length < 512) {
      // buffer length not exceeded
      _heartRateBuffer.add(newValue);
      _heartRateSum += newValue;
    } else {
      // buffer has 512 elements
      _heartRateSum -= _heartRateBuffer.first + newValue;
      _heartRateBuffer.removeAt(0);
      _heartRateBuffer.add(newValue);
    }
    return _heartRateSum / _heartRateBuffer.length;
  }

  /// calculates the new average body temperature based on the given new value
  double _getBodyTemp(double newValue) {
    if(_bodyTempBuffer.length < 512) {
      // buffer length not exceeded
      _bodyTempBuffer.add(newValue);
      _bodyTempSum += newValue;
    } else {
      // buffer has 512 elements
      _bodyTempSum -= _bodyTempBuffer.first + newValue;
      _bodyTempBuffer.removeAt(0);
      _bodyTempBuffer.add(newValue);
    }
    return _bodyTempSum / _bodyTempBuffer.length;
  }


  Tuple2<double, String> getAvgHeartRateAndEvaluation(double currentHeartRate) {

    double avg = _getHeartRateAvg(currentHeartRate);
    String eval = _evaluateBodyTemp(currentHeartRate, avg);

  }

  Tuple2<double, String> getAvgBodyTempAndEvaluation(double currentBodyTemp) {

    double avg = _getBodyTemp(currentBodyTemp);
    String eval = _evaluateBodyTemp(currentBodyTemp, avg);

  }

}