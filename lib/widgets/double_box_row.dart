import 'package:chillout_hrm/global.dart';
import 'package:flutter/material.dart';

/// This widget creates two equally sized rounded containers to display data values
/// the two containers are in a rectangle shape with the background color of the theme and black text inside
class DoubleBoxRow extends StatelessWidget {
  const DoubleBoxRow({
    super.key,
    required this.leftValue,
    required this.rightValue,
    required this.leftValueColor,
    required this.rightValueColor,
    required this.leftBottomText,
    required this.rightBottomText,
    required this.leftTopText,
    required this.rightTopText,
  });

  // strings & numbers inside the two containers
  final double leftValue;
  final double rightValue;
  final String leftBottomText;
  final String rightBottomText;
  final String leftTopText;
  final String rightTopText;

  // Colors for main values
  final Color leftValueColor;
  final Color rightValueColor;

  // Predefined styling attributes
  static const int _flexVal = 1;
  static const double _numFontSize = 27;

  @override
  Widget build(BuildContext context) {
    return Row(
        // Main row - contains two evenly sized rounded containers
        children: [
          Expanded(
            // used to force equal size
            flex: _flexVal,
            child: Container(
              // left container
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(regularBorderRadius)),
              child: Column(children: [
                Text(leftTopText),
                Text("$leftValue",
                    style: TextStyle(
                      color: leftValueColor,
                      fontSize: _numFontSize,
                      fontWeight: FontWeight.bold,
                    )),
                Text(leftBottomText),
              ]),
            ),
          ),
          const SizedBox(
            // invisible box for spacing between the two containers
            width: largeSpacing,
          ),
          Expanded(
            // force equal size
            flex: _flexVal,
            child: Container(
              // right container
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(regularBorderRadius)),
              child: Column(children: [
                Text(rightTopText),
                Text("$rightValue",
                    style: TextStyle(
                      color: rightValueColor,
                      fontSize: _numFontSize,
                      fontWeight: FontWeight.bold,
                    )),
                Text(rightBottomText),
              ]),
            ),
          )
        ]);
  }
}
