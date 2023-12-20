import 'package:chillout_hrm/pages/scan_page.dart';
import 'package:chillout_hrm/util/enum.dart';
import 'package:chillout_hrm/widgets/error_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:numberpicker/numberpicker.dart';

import '../global.dart';
import '../util/user_data.dart';
import '../widgets/rounded_button.dart';

/// Landingpage of the App with which requests some input from user before proceeding to the bluetooth scan page
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  //appbar title
  final String _title = 'Welcome';

  final String _startButtonText = "Get started";
  final String _sexDropDownHint = 'What is your sex?';
  final String _exerciseFrequencyDropDownHint = 'How often do you exercise?';
  final String _agePickerHint = 'What is your age?';

  // error messages
  final String _errorBluetoothOff = 'Please turn on bluetooth.';
  final String _errorBtNotSupported = 'This device does not support bluetooth.';
  final String _dataMissing = 'Please fill out all fields.';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // user input
  Sex? _sex;
  ExerciseFrequency? _frequency;
  int _userAge = 50;

  /// Navigate to the body tracker page
  void _navigateBodyTracking() async {
    UserData user;
    // if the user hasn't filled out some of the fields, then we show error and return
    if (_sex != null && _frequency != null) {
      user = UserData(
          sex: _sex as Sex,
          frequency: _frequency as ExerciseFrequency,
          age: _userAge);
    } else {
      showSnackBarError(widget._dataMissing);
      return;
    }

    // check if device supports bluetooth
    if (await FlutterBlue.instance.isAvailable) {
      // check if bluetooth is on and respond with going to the scanning page or showing error
      // after await check if context is still valid and proceed only if it is
      if (await FlutterBlue.instance.isOn) {
        if (!context.mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ScanPage(userData: user)));
      } else {
        showSnackBarError(widget._errorBluetoothOff);
      }
    } else {
      showSnackBarError(widget._errorBtNotSupported);
    }
  }

  /// Shows a snackbar error message at the bottom of the screen after checking
  /// that the buildcontext is still valid
  /// [message] is the Text that is displayed in the snackbar.
  Future showSnackBarError(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.all(smallSpacing),
        margin: const EdgeInsets.all(largeSpacing),
        showCloseIcon: true,
        closeIconColor: Colors.black,
        duration: snackBarDuration,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: ErrorSnackbarContent(
          context: context,
          message: message,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // home page scaffold
      backgroundColor: backgroundColor,
      appBar: AppBar(
        // Appbar containing only a title
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: backgroundColor,
        title: Text(widget._title, style: appBarTextStyle),
      ),
      body: LayoutBuilder(
        // Layout builder to make screen scrollable if there is an overflow
        builder: (BuildContext context, BoxConstraints viewPortConstraints) {
          return SingleChildScrollView(
            // enable content to be scrolled if it doesn't fit on the screen
            child: ConstrainedBox(
              // keep content constrained to max height of viewport
              constraints:
                  BoxConstraints(minHeight: viewPortConstraints.maxHeight),
              child: Padding(
                // padding for all elements of the home page
                padding: const EdgeInsets.all(veryLargeSpacing),
                child: Column(
                  // Main container for all elements of the page
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Image.asset(
                        // Illustration at the top of the page
                        'assets/images/yoga_illustration.png',
                        fit: BoxFit.fitWidth,
                        width: viewPortConstraints.maxWidth - 60),
                    const SizedBox(
                      height: smallSpacing,
                    ),
                    DropdownButtonFormField(
                        // dropdown for choosing sex
                        hint: Text(widget._sexDropDownHint),
                        value: _sex,
                        icon: const Icon(
                          Icons.arrow_drop_down_circle,
                        ),
                        decoration: const InputDecoration(
                          label: Text('Sex'),
                        ),
                        isExpanded: true,
                        items: Sex.values
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.string),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _sex = val;
                          });
                        }),
                    DropdownButtonFormField(
                        // dropdown for choosing exercise frequency.
                        hint: Text(widget._exerciseFrequencyDropDownHint),
                        value: _frequency,
                        icon: const Icon(
                          Icons.arrow_drop_down_circle,
                        ),
                        decoration: const InputDecoration(
                          label: Text('Exercise Frequency'),
                        ),
                        isExpanded: true,
                        items: ExerciseFrequency.values
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.string),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _frequency = val;
                          });
                        }),
                    const SizedBox(
                      height: smallSpacing,
                    ),
                    Column(
                      // column which contains the age picker and its subtext
                      children: [
                        NumberPicker(
                          selectedTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 25),
                          axis: Axis.horizontal,
                          step: 1,
                          minValue: 10,
                          maxValue: 100,
                          value: _userAge,
                          onChanged: (int value) {
                            setState(() {
                              _userAge = value;
                            });
                          },
                        ),
                        Text(widget._agePickerHint,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500))
                      ],
                    ),
                    const SizedBox(height: largeSpacing),
                    LargeRoundedButton(
                        // Button to go to the body tracking page
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        textColor: Theme.of(context).colorScheme.onSecondary,
                        buttonText: widget._startButtonText,
                        onPressed: _navigateBodyTracking),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
