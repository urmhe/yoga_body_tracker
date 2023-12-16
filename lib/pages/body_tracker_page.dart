import 'dart:async';
import 'dart:typed_data';

import 'package:chillout_hrm/widgets/double_box_row.dart';
import 'package:chillout_hrm/widgets/yoga_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:synchronized/synchronized.dart';

import '../global.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/error_snackbar_content.dart';

/// Page displaying the heart rate and body temperature that is received by the cosinus device sensors
/// as well as a listview of yoga exercises
class TrackerPage extends StatefulWidget {
  final BluetoothDevice device;

  const TrackerPage({super.key, required this.device});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  // Strings used throughout the page
  final String _title = 'Body Tracker';
  final String _headerTracker = "Tracker";
  final String _bpmString = 'BPM';
  final String _targetHeartRate = 'Target Heart Rate';
  final String _maxHeartRate = 'Max Heart Rate';
  final String _headerRecommendation = "Recommendation";
  final String _connectedString = 'Connected';
  final String _connectingString = 'Connecting...';
  final String _disconnectedString = 'Disconnected';
  final String _dialogContentTargetHeartRate =
      'This is a certain percentage of the maximum heart rate based on how often you exercise.\n\nIf your goal is to lose weight then keeping your heart rate at this level would be ideal.';
  final String _dialogContentMaxHeartRate =
      'This is an estimation of what the maximum heart rate is that your body can handle.\n\nIt\'s calculated based on age, gender and how often you exercise.';

  // Error messages
  final String _failedConnectionAttemptMessage =
      'Failed to connect. Please check whether the earable device is currently active.';
  final String _wrongDeviceMessage =
      'The selected device does not provide the required services. Please choose a different device.';

  // header TextStyle
  final TextStyle _headerTextStyle =
      const TextStyle(color: Colors.white, fontSize: 20);

  // current heart rate and body temp
  double _heartRate = 0;
  double _bodyTemp = 0;

  //Streamsubscriptions & BLE related attribute
  final int _maxAttempts = 2;
  int _connectionAttempts = 0;
  bool _keepReconnecting = true;
  BluetoothDeviceState _connectionState = BluetoothDeviceState.disconnected;

  late StreamSubscription<BluetoothDeviceState> _connectionStateSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<List<int>>? _bodyTempSubscription;

  List<BluetoothService> _services = [];

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.state.listen((state) async {
      if (context.mounted) {
        setState(() {
          _connectionState = state;
        });
      }

      // if device is not connected and bluetooth is on, then we try to establish a connection
      if (state == BluetoothDeviceState.disconnected &&
          _connectionAttempts < _maxAttempts &&
          _keepReconnecting) {
        debugPrint('::: call _connectDevice :::');
        _connectDevice();
      }
    });
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// Most of the code was taken from the link above with some error handling added to it.
  /// connect to the chosen device via BLE and subscribe to sensor data characteristics.
  void _connectDevice() async {
    // service always have to be rediscovered on every connection attempt
    _services = [];

    // update state to connecting since this state is not emitted by the stream but we want to show it on the screen
    if (context.mounted) {
      setState(() {
        _connectionState = BluetoothDeviceState.connecting;
      });
    }

    // connect & handle timeout error
    debugPrint('::: connect called :::');
    await widget.device
        .connect(autoConnect: false)
        .timeout(const Duration(seconds: 15), onTimeout: () {
      debugPrint(
          '::: onTimeout: connect call timed out -> Device is most likely not available :::');
      if (context.mounted) {
        setState(() {
          _connectionState = BluetoothDeviceState.disconnected;
        });
      }
      showSnackBarError(_failedConnectionAttemptMessage);
      return;
    });
    debugPrint(':::::::: done connecting :::::::::::');

    // find services
    try {
      _services = await widget.device.discoverServices();
    } catch (e) {
      // if services cannot be discovered, then we disconnect from device which will trigger a reconnect.
      // This counts as a failed attempt at connecting for the purpose of the app
      _connectionAttempts++;
      if (!(_connectionAttempts < _maxAttempts)) {
        showSnackBarError(_failedConnectionAttemptMessage);
      }
      await widget.device.disconnect();
      return;
    }

    // subscribe to the necessary characteristics for reading the sensor data
    await subscribeToCharacteristics(_services);

    // check if necessary characteristics were found. If not then probably the wrong device was chosen so there is no point in reconnecting
    if (_bodyTempSubscription == null && _heartRateSubscription == null) {
      _keepReconnecting = false;
      showSnackBarError(_wrongDeviceMessage);
      await widget.device.disconnect();
    }
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// code was taken from link above
  /// subscribes to the characteristics that provide heart rate and body temperature
  Future<void> subscribeToCharacteristics(
      List<BluetoothService> services) async {
    // lock to sequentially call setNotifyValue(true) which prevents a bug in FlutterBlue which can cause a PlattformException
    var lock = Lock();

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        switch (c.uuid.toString()) {
          case "00002a37-0000-1000-8000-00805f9b34fb":
            await lock.synchronized(() async {
              await c.setNotifyValue(true);
              await Future.delayed(const Duration(milliseconds: 300));
              _heartRateSubscription =
                  c.value.listen((sensorData) => updateHeartRate(sensorData));
              debugPrint('::: subscribed to heart rate :::');
            });
            break;

          case "00002a1c-0000-1000-8000-00805f9b34fb":
            await lock.synchronized(() async {
              await c.setNotifyValue(true);
              await Future.delayed(const Duration(milliseconds: 300));
              _bodyTempSubscription = c.value.listen(
                (sensorData) => updateBodyTemperature(sensorData),
              );
              debugPrint('::: subscribed to body temperature :::');
            });
            break;

          default:
            break;
        }
      }
    }
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// code was taken from link above
  int twosComplimentOfNegativeMantissa(int mantissa) {
    if ((4194304 & mantissa) != 0) {
      return (((mantissa ^ -1) & 16777215) + 1) * -1;
    }
    return mantissa;
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// Most of the code was taken from the file above.
  /// Additional functionality was added so that the average body temp and the evaluation are calculated.
  /// [sensorData] is the raw data that is received from the earable.
  void updateBodyTemperature(sensorData) {
    var flag;
    try {
      flag = sensorData[0];
    } on RangeError catch (e) {
      return;
    }

    // based on GATT standard
    double temperature = twosComplimentOfNegativeMantissa(
            ((sensorData[3] << 16) | (sensorData[2] << 8) | sensorData[1]) &
                16777215) /
        100.0;
    if ((flag & 1) != 0) {
      temperature = ((98.6 * temperature) - 32.0) *
          (5.0 / 9.0); // convert Fahrenheit to Celsius
    }
    if (mounted) {
      setState(() {
        _bodyTemp =
            temperature; //TODO add functionality to calc evaluation and average
      });
    }
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// Most of the code was taken from the file above.
  /// Additional functionality was added so that the average body temp and the evaluation are calculated
  /// [sensorData] is the raw data that is received from the earable.
  void updateHeartRate(sensorData) {
    Uint8List bytes = Uint8List.fromList(sensorData);

    if (bytes.isEmpty) return;

    // based on GATT standard
    var bpm;
    try {
      bpm = bytes[1];
    } on RangeError catch (e) {
      return;
    }

    if (!((bytes[0] & 0x01) == 0)) {
      bpm = (((bpm >> 8) & 0xFF) | ((bpm << 8) & 0xFF00));
    }

    if (mounted) {
      setState(() {
        _heartRate = bpm.toDouble(); //adding a cast here
      });
    }
  }

  /// Async method for showing an error snackbar at the bottom of the screen.
  /// [message] is the Text that is displayed in the snackbar.
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
        content: ErrorSnackbarContent(
          context: context,
          message: message,
        )));
  }

  /// Build the text widget which displays the current state of the connection.
  Widget buildStateText(BuildContext context) {
    Color textColor;
    String displayText;

    switch (_connectionState) {
      case BluetoothDeviceState.disconnected:
        textColor = Theme.of(context).colorScheme.error;
        displayText = _disconnectedString;
        break;

      case BluetoothDeviceState.connecting:
        textColor = Theme.of(context).colorScheme.tertiary;
        displayText = _connectingString;
        break;

      case BluetoothDeviceState.connected:
        textColor = Theme.of(context).colorScheme.secondary;
        displayText = _connectedString;
        break;

      default:
        textColor = Colors.black;
        displayText = 'Unknown state';
    }
    return Text(displayText,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: textColor));
  }

  @override
  void dispose() {
    // cancel all subscriptions before leaving this page
    _connectionStateSubscription.cancel();
    _heartRateSubscription?.cancel();
    _bodyTempSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          // Appbar containing only a title
          automaticallyImplyLeading: true,
          centerTitle: true,
          backgroundColor: backgroundColor,
          title: Text(_title, style: appBarTextStyle),
        ),
        body: Center(
            child: Column(
                // column containing the listview and the main container with all the tracking elements
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              Expanded(
                  // contains the scrollable listView showing various yoga poses
                  flex: 4,
                  child: Padding(
                      padding: const EdgeInsets.only(
                          left: smallSpacing,
                          top: largeSpacing,
                          bottom: largeSpacing,
                          right: smallSpacing),
                      child: YogaListView())),
              const SizedBox(
                // Invisible box to add slightly more space between the top and bottom container
                height: largeSpacing,
              ),
              Expanded(
                // container with 60% of screen height containing the body tracking information
                flex: 6,
                child: Container(
                    // container wrapping all tracking elements for styling purposes
                    padding: const EdgeInsets.all(largeSpacing),
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(veryLargeBorderRadius),
                            topRight: Radius.circular(veryLargeBorderRadius))),
                    child: Column(
                      // main column of the tracking elements
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Padding(
                          // padding of status bar
                          padding: const EdgeInsets.only(
                              left: 2 * veryLargeSpacing,
                              right: 2 * veryLargeSpacing),
                          child: Container(
                            // status bar for current connection status
                            padding: const EdgeInsets.all(largeSpacing),
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius:
                                    BorderRadius.circular(regularBorderRadius)),
                            child: buildStateText(context),
                          ),
                        ),
                        Column(
                          // contains tracking elements for current heart rate and body temp + section header
                          children: [
                            Text(
                              _headerTracker,
                              style: _headerTextStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              height: smallSpacing,
                            ),
                            DoubleBoxRow(
                              leftTopText: 'Heart Rate',
                              leftValue: _heartRate,
                              leftBottomText: _bpmString,
                              rightTopText: 'Body Temperature',
                              rightValue: _bodyTemp,
                              rightBottomText: 'Celsius',
                            ),
                          ],
                        ),
                        Column(
                          // contains the section header, the display elements for target and max heart rate and the row for the info buttons
                          children: [
                            Text(
                              _headerRecommendation,
                              style: _headerTextStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: smallSpacing),
                            DoubleBoxRow(
                              leftValue: 0,
                              rightValue: 0,
                              leftBottomText: _bpmString,
                              leftTopText: _targetHeartRate,
                              rightTopText: _maxHeartRate,
                              rightBottomText: _bpmString,
                            ),
                            const SizedBox(
                              height: largeSpacing,
                            ),
                            Row(
                              // contains the two information buttons
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  // expanded to force equal size
                                  flex: 1,
                                  child: ElevatedButton(
                                      // button which when pressed shows a dialog that explains the target heart rate
                                      onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => CustomDialog(
                                              titleText: _targetHeartRate,
                                              contentText:
                                                  _dialogContentTargetHeartRate)),
                                      child: const Icon(Icons.info_outline)),
                                ),
                                const SizedBox(
                                  width: largeSpacing,
                                ),
                                Expanded(
                                  // expanded to force equal size
                                  flex: 1,
                                  child: ElevatedButton(
                                      // button which when pressed shows a dialog explaining the max heart rate
                                      onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => CustomDialog(
                                              titleText: _maxHeartRate,
                                              contentText:
                                                  _dialogContentMaxHeartRate)),
                                      child: const Icon(Icons.info_outline)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    )),
              )
            ])));
  }
}
