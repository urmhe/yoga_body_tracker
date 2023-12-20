import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

import '../global.dart';
import '../util/user_data.dart';
import '../widgets/device_list_view.dart';
import '../widgets/error_snackbar_content.dart';
import '../widgets/rounded_button.dart';

/// Scan page - scans for available bluetooth devices and lists them in a listView.
/// User can choose to connect to one of the available devices.
/// [userData] is passed through to the body tracking page.
class ScanPage extends StatefulWidget {
  ScanPage({super.key, required this.userData});

  // data object containing the information that user provided on home screen
  final UserData userData;

  // FlutterBlue instance
  final FlutterBlue _flutterBlue = FlutterBlue.instance;

  // Strings used throughout the page
  final String _title = 'Scan for devices';
  final String _buttonStringStart = 'Start scanning';
  final String _buttonStringStop = 'Stop scanning';

  // Error messages
  final String _scanError = 'A problem occured during the scan.';
  final String _stopError = 'A problem occured while stopping the scan.';
  final String _bluetoothOff =
      'Please keep bluetooth active while using the app.';

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // attributes and streams used for tracking the state of the scan
  bool _scanning = false;
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BluetoothState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();

    // listen to adapterstate and return to home screen if bluetooth is ever turned off
    _adapterStateSubscription = widget._flutterBlue.state.listen((state) {
      if (state == BluetoothState.off) {
        if (!mounted) return;
        showSnackBarError(widget._bluetoothOff);
        Navigator.popUntil(context, ModalRoute.withName(homeRoute));
      }
    });

    // set up subscriptions to scanresults and scanning state
    _scanResultsSubscription =
        widget._flutterBlue.scanResults.listen((results) {
      // update scanResults list based on stream and call setstate to update listview
      if (!mounted) return;
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      showSnackBarError(widget._scanError);
    });

    _isScanningSubscription = widget._flutterBlue.isScanning.listen((state) {
      if (!mounted) return;
      setState(() {
        _scanning = state;
      });
    });
  }

  /// Shows a snackbar error message at the bottom of the screen after checking
  /// that the context is still valid.
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

  /// Stop the bluetooth scan. Shows error if something went wrong.
  Future stopPressed() async {
    try {
      widget._flutterBlue.stopScan();
    } catch (e) {
      showSnackBarError(widget._stopError);
    }
  }

  /// Start scanning and show error message if a problem occurs.
  Future scanPressed() async {
    // request location permission when first using the app
    await Permission.location.request();

    // try starting the scan for device and show error snackbar in case of an error
    try {
      await widget._flutterBlue.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      showSnackBarError(widget._scanError);
      stopPressed();
    }
  }

  /// Provides the button that is used for starting and stopping the scan
  /// depending on whether the scan is currently active or not.
  Widget buildButton(BuildContext context) {
    return LargeRoundedButton(
      backgroundColor: _scanning
          ? Theme.of(context).disabledColor
          : Theme.of(context).colorScheme.secondary,
      buttonText:
          _scanning ? widget._buttonStringStop : widget._buttonStringStart,
      textColor:
          _scanning ? Colors.white : Theme.of(context).colorScheme.onSecondary,
      onPressed: _scanning ? stopPressed : scanPressed,
    );
  }

  @override
  void dispose() {
    // cancel all active scans and subscriptions
    if (_scanning) {
      widget._flutterBlue.stopScan();
    }
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _adapterStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: backgroundColor,
          automaticallyImplyLeading: true,
          centerTitle: true,
          title: Text(
            widget._title,
            style: appBarTextStyle,
          ),
        ),
        body: Column(
            // main column containing all elements of the page
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                // expand listview so that it takes up the rest of the screen
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(smallSpacing),
                  child: DeviceListView(
                    // listview of all scanResults
                    itemList: _scanResults,
                    userData: widget.userData,
                  ),
                ),
              ),
              const SizedBox(
                height: smallSpacing,
              ),
              Container(
                  // contains the scan button
                  padding: const EdgeInsets.all(veryLargeSpacing),
                  child: buildButton(context)),
            ]));
  }
}
