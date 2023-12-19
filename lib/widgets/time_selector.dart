import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

import '../global.dart';

/// Consists of a column with a header text and a vertically scrollable list of numbers.
class TimeSelector extends StatelessWidget {
  const TimeSelector({
    super.key,
    required this.value,
    required this.header,
    required this.maxVal,
    required this.onChanged,
  });

  final int value;
  final String header;
  final int maxVal;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      // main column containing all elements
      children: [
        Text(header,
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,)),
        const SizedBox(
          height: smallSpacing,
        ),
        NumberPicker(
            itemCount: 3,
            textStyle: const TextStyle(color: Colors.black, fontSize: 21),
            selectedTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary, fontSize: 33),
            axis: Axis.vertical,
            step: 1,
            minValue: 0,
            maxValue: maxVal,
            value: value,
            onChanged: onChanged)
      ],
    );
  }
}
