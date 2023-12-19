import 'package:flutter/material.dart';

import '../global.dart';

/// Content of the snackbar for displaying errors. This is a prestyled widget.
class ErrorSnackbarContent extends StatelessWidget {
  const ErrorSnackbarContent({
    super.key,
    required this.context,
    required this.message,
  });

  final BuildContext context;
  final String message;

  // header string
  final String _header = 'Error:';

  @override
  Widget build(BuildContext context) {
    return Column(
      // main colum containing all elements
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          _header,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(
          height: smallSpacing,
        ),
        Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
