import 'package:chillout_hrm/widgets/error_snackbar_content.dart';
import 'package:flutter/material.dart';
import '../widgets/rounded_button.dart';
import '../global.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// Landingpage of the App which provides some information about how to use the app and offer navigation to bluetooth devices
/// as well as to the body tracking page
class HomePage extends StatefulWidget {

  const HomePage({super.key});

  static const double _disclaimerFontSize = 20.0;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  //appbar title
  final String _title = 'Welcome';

  // Strings used throughout the page
  final String _disclaimerText = "To use the app, please make sure that you have enabled bluetooth on your phone and your earable device.";
  final String _startButtonText = "Get started";
  final String _errorBluetoothOff = 'Please turn on bluetooth';
  final String _errorBtNotSupported = 'This device does not support bluetooth';

  /// Navigate to the body tracker page
  void _navigateBodyTracking() async {
    // check if device supports bluetooth
    if(await FlutterBlue.instance.isAvailable) {

      // check if bluetooth is on and respond with going to the scanning page or showing error
      // after await check if context is still valid and proceed only if it is
      if (await FlutterBlue.instance.isOn) {
        if(!context.mounted) return;
        Navigator.pushNamed(context, scanRoute);
      } else {
        showSnackBarError(_errorBluetoothOff);
      }

    } else {
      showSnackBarError(_errorBtNotSupported);
    }

  }

  /// Shows a snackbar error message at the bottom of the screen after checking
  /// that the context is still valid
  Future showSnackBarError(String message) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.all(smallSpacing),
        margin: const EdgeInsets.all(largeSpacing),
        showCloseIcon: true,
        closeIconColor: Colors.black,
        duration: const Duration(seconds: 10),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: ErrorSnackbarContent(context: context, message: message,))
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // Appbar containing only a title
        centerTitle: true,
        backgroundColor: backgroundColor,
        title: Text(_title,
          style: appBarTextStyle
        ),
      ),
      body: Center(
          child: Padding(
            // padding for all elements of the home page
            padding: const EdgeInsets.all(veryLargeSpacing),
            child: Column(
              // Main container for all elements of the page
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Image.asset(
                    // Illustration at the top of the page
                    'assets/images/yoga_illustration.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity
                ),
                Text(
                  // Text widget containing the disclaimer
                  _disclaimerText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: HomePage._disclaimerFontSize,
                      color: Colors.grey.shade700),
                    ),
                LargeRoundedButton(
                  // Button to go to the body tracking page
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    textColor: Theme.of(context).colorScheme.onSecondary, buttonText: _startButtonText,
                    onPressed:_navigateBodyTracking
                ),
                const SizedBox(
                  // Add extra space at the bottom so that error snackbar doesn't overlap with button
                  height: veryLargeSpacing * 2,
                )
            ],
        ),
      ),
    ),
    );
  }
}
