import 'package:flutter/material.dart';

/// This is a large rounded button which can be reused. The button is prestyled but offers the ability to define the background color,
/// text color, button text and the function that is executed when pressing the button.
class LargeRoundedButton extends StatelessWidget {
  const LargeRoundedButton({
    super.key,
    required this.backgroundColor,
    required this.buttonText,
    required this.textColor,
    required this.onPressed,
  });

  final Color backgroundColor;
  final String buttonText;
  final Color textColor;
  final VoidCallback onPressed;

  // attributes used for styling
  static const double _fontsize = 21;
  static const double _minHeight = 45.0;
  static const double _paddingSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
            minimumSize: const MaterialStatePropertyAll<Size>(
                Size.fromHeight(_minHeight)),
            backgroundColor: MaterialStatePropertyAll<Color>(backgroundColor),
            padding: const MaterialStatePropertyAll<EdgeInsetsGeometry>(
                EdgeInsets.all(_paddingSize))),
        child: Text(
          buttonText,
          style: TextStyle(color: textColor, fontSize: _fontsize),
        ));
  }
}
