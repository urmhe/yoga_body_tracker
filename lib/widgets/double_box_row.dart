import 'package:chillout_hrm/global.dart';
import 'package:flutter/material.dart';


/// This widget creates two equally sized rounded containers to display sensor data values
/// the two containers are in a rectangle shape with the background color of the theme and black text inside
class DoubleBoxRow extends StatelessWidget {
  const DoubleBoxRow({
    super.key,
    required double currentValue,
    required double avgValue,
    required String unitString,
  }) : _currentValue = currentValue, _avgValue = avgValue, _unitString = unitString;

  // Variables for storing current values of body temp and the measurement unit
  final double _currentValue;
  final double _avgValue;
  final String _unitString;

  // Predefined styling variables
  static const int _flexVal = 1;
  static const double _numFontSize = 28;

  static const TextStyle _numTextStyle = TextStyle(
    color: Colors.black,
    fontSize: _numFontSize,
    fontWeight: FontWeight.bold,
  );


  // Strings used throughout the widget
  static const String _avgString = 'Avg.';
  static const String _currString = 'Current';


  @override
  Widget build(BuildContext context) {
    // create text style for numbers with current Theme onBackground color

    return Row(
      // Contains two evenly sized rounded containers
        children: [
          Expanded(
            flex: _flexVal,
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(regularBorderRadius)
              ),
              child: Column(
                  children: [
                    const Text(_currString),
                    Text("$_currentValue", style: _numTextStyle),
                    Text(_unitString),
                  ]
              ),
            ),
          ),
          const SizedBox(
            // invisible box for spacing between the two containers
            width: largeSpacing,
          ),
          Expanded(
            flex: _flexVal,
            child: Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(regularBorderRadius)
              ),
              child: Column(
                  children: [
                    const Text(_avgString),
                    Text("$_avgValue", style: _numTextStyle),
                    Text(_unitString),
                  ]
              ),
            ),
          )
        ]
    );
  }
}