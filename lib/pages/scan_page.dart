import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/device_list_view.dart';
import '../widgets/error_snackbar_content.dart';
import '../widgets/rounded_button.dart';
import '../global.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// Scan page scans for available bluetooth devices and lists them in a listView
/// User can choose to connect to one of the available devices
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  // FlutterBlue instance
  FlutterBlue flutterBlue = FlutterBlue.instance;

  // Strings used throughout the page
  final String _title = 'Scan for devices';
  final String _buttonStringStart = 'Start scanning';
  final String _buttonStringStop = 'Stop scanning';

  // Error messages
  final String _scanError = 'A problem occured during the scan.';
  final String _stopError = 'A problem occured while stopping the scan.';
  final String _bluetoothOff = 'Please keep bluetooth active while using the app.';

  // Variables and streams used for tracking the state of the scan
  bool _scanning = false;
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BluetoothState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();

    // listen to adapterstate and return to home screen is bluetooth is ever turned off
    _adapterStateSubscription = flutterBlue.state.listen(
        (state) {
          if(state == BluetoothState.off) {
            if(!context.mounted) return;
            showSnackBarError(_bluetoothOff);
            Navigator.popUntil(context, ModalRoute.withName(homeRoute));
          }
        }
    );


    // set up subscriptions to scanresults and scanning state
    _scanResultsSubscription = flutterBlue.scanResults.listen((results) {
      // update scanResults list based on stream and call setstate to update listview
      if(!context.mounted) return;
      setState(() {_scanResults = results;});
    }, onError: (e) {
      showSnackBarError(_scanError);
    });

    _isScanningSubscription = flutterBlue.isScanning.listen(
        (state) {
          if(!context.mounted) return;
          setState(() {_scanning = state;});
        }
    );
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

  /// Stop the bluetooth scan. Shows error if something went wrong.
  Future stopPressed() async {
    try {
      flutterBlue.stopScan();
    } catch (e) {
      showSnackBarError(_stopError);
    }
  }

  /// Start scanning and show error message if a problem occurs
  Future scanPressed() async {
    await Permission.location.request();

    // try starting the scan for device and show error snackbar in case of an error
    try {
      await flutterBlue.startScan(
        timeout: const Duration(seconds: 15));
    } catch (e) {
      showSnackBarError(_scanError);
      stopPressed();
      }
  }

  /// Provides the button that is used for starting and stopping the scan depending on the current _scanning value
  Widget buildButton(BuildContext context) {
    return LargeRoundedButton(backgroundColor: _scanning ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.secondary,
      buttonText: _scanning ? _buttonStringStop : _buttonStringStart,
      textColor: _scanning ? Colors.white : Theme.of(context).colorScheme.onSecondary,
      onPressed: _scanning ? stopPressed : scanPressed,
    );
  }

  @override
  void dispose() {
    // cancel all active scans and subscriptions
    if(_scanning) {
      flutterBlue.stopScan();
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
        title: Text(_title, style: appBarTextStyle,),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              padding: const EdgeInsets.all(veryLargeSpacing),
              child: buildButton(context)
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(smallSpacing),
              child: DeviceListView(itemList: _scanResults,),
            ),
          ),
        ]
      )
    );
  }
}




