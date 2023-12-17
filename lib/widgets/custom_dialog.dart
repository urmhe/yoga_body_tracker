import 'package:flutter/material.dart';

/// Prestyled AlertDialog widget for displaying information.
class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.titleText,
    required this.contentText,
  });

  final String titleText;
  final String contentText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(titleText),
      content: Text(
        contentText,
        textAlign: TextAlign.center,
      ),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.black),
      icon: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(fontSize: 17)),
        )
      ],
    );
  }
}
