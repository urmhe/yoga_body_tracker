import 'package:flutter/material.dart';

import '../global.dart';

/// This class is a prestyled column to display a number with a subtext below it.
/// If the number is less than 10 a leading 0 is added.
class TimeAndSubtext extends StatelessWidget {
  const TimeAndSubtext({
    super.key,
    required this.numVal,
    required this.subText,
  });

  final int numVal;
  final String subText;

  /// Return a string representation of the input number. If the input is smaller than 10, then a leading
  /// 0 is added to the string.
  String numValToString(int number) {
    if (number >= 0 && number <= 9) return '0$number';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // main column that contains all elements
      children: [
        Text(
          numValToString(numVal),
          style: TextStyle(fontSize: 39, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: smallSpacing),
        Text(subText,
            style: TextStyle(
                fontSize: 21,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold))
      ],
    );
  }
}
