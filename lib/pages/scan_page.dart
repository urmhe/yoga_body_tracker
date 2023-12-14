import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/device_list_view.dart';
import '../widgets/error_snackbar_content.dart';
import '../widgets/rounded_button.dart';
import '../global.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Scan page scans for available bluetooth devices and lists them in a listView
/// User can choose to connect to one of the available devices
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {

  // Strings used throughout the page
  final String _title = 'Scan for devices';
  final String _buttonStringStart = 'Start scanning';
  final String _buttonStringStop = 'Stop scanning';

  // Error messages
  final String _scanError = 'A problem occured during the scan';
  final String _stopError = 'A problem occured while stopping the scan';
  final String _bluetoothOff = 'Please do not turn off bluetooth';

  // Variables and streams used for tracking the state of the scan
  bool _scanning = false;
  List<ScanResult> _scanResults = [];
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;

  @override
  void initState() {
    super.initState();

    // listen to adapterstate and return to home screen is bluetooth is ever turned off
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen(
        (state) {
          if(state == BluetoothAdapterState.off) {
            if(!context.mounted) return;
            showSnackBarError(_bluetoothOff);
            Navigator.popUntil(context, ModalRoute.withName(homeRoute));
          }
        }
    );


    // set up subscriptions to scanresults and scanning state
    _scanResultsSubscription = FlutterBluePlus.onScanResults.listen((results) {
      // update scanResults list based on stream and call setstate to update listview
      setState(() {_scanResults = results;});
    }, onError: (e) {
      showSnackBarError(_scanError);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen(
        (state) {
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
      FlutterBluePlus.stopScan();
    } catch (e) {
      showSnackBarError(_stopError);
    }
  }

  /// Start scanning and show error message if a problem occurs
  Future scanPressed() async {

    // try starting the scan for device and show error snackbar in case of an error
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15));
    } catch (e) {
      showSnackBarError(_scanError);
      stopPressed();
      }
    setState(() {});
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
    // cancel all active scan and subscriptions
    if(_scanning) {
      FlutterBluePlus.stopScan();
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




