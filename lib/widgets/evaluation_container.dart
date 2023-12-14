import 'package:flutter/material.dart';
import 'package:chillout_hrm/global.dart';

/// This class is a prestyled container that is supposed to be used for the evaluation of the current sensor data
/// The container is a rectangle shape with rounded corners, white background and black text
class EvaluationContainer extends StatelessWidget {
  const EvaluationContainer({
    super.key,
    required String evalString,
  }): _evalString = evalString;

  // Text value that is displayed within the container
  final String _evalString;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(smallSpacing),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(smallBorderRadius)
        ),
        child: Text(_evalString, textAlign: TextAlign.center,)
    );
  }
}