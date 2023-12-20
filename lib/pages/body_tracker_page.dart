import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:chillout_hrm/pages/timer_picker_sheet.dart';
import 'package:chillout_hrm/widgets/double_box_row.dart';
import 'package:chillout_hrm/widgets/yoga_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../global.dart';
import '../util/user_data.dart';
import '../widgets/countdown.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/error_snackbar_content.dart';

/// Page displaying the heart rate and body temperature that is received by the cosinus device sensors
/// as well as a listview of yoga exercises
class TrackerPage extends StatefulWidget {
  // standard constructor which also initializes target and max heart rate
  TrackerPage({super.key, required this.device, required this.userData}) {
    UserLimitEstimator eval = UserLimitEstimator(userData: userData);
    _targetHeartRate = eval.targetHeartRate;
    _maxHeartRate = eval.maxHeartRate;
  }

  // device chosen by user
  final BluetoothDevice device;

  // object containing information about user
  final UserData userData;

  // calculated based on userData
  late final double _targetHeartRate;
  late final double _maxHeartRate;

  // Strings used throughout the page
  final String _title = 'Body Tracker';
  final String _headerTracker = "Tracker";
  final String _bpmString = 'BPM';
  final String _targetHeartRateHeader = 'Target Heart Rate';
  final String _maxHeartRateHeader = 'Max Heart Rate';
  final String _headerRecommendation = "Recommendation";
  final String _connectedString = 'Connected';
  final String _connectingString = 'Connecting...';
  final String _disconnectedString = 'Disconnected';
  final String _dialogContentTargetHeartRate =
      'This is a certain percentage of the maximum heart rate based on how often you exercise.\n\nIf your goal is to lose weight then keeping your heart rate at this level would be ideal.';
  final String _dialogContentMaxHeartRate =
      'This is an estimation of what the maximum heart rate is that your body can handle.\n\nIt\'s calculated based on age, sex and how often you exercise.';

  // Error messages
  final String _failedConnectionAttemptMessage =
      'Failed to connect. Please check whether the earable device is currently active.';
  final String _wrongDeviceMessage =
      'The selected device does not provide the required services. Please choose a different device.';

  // header TextStyle
  final TextStyle _headerTextStyle =
      const TextStyle(color: Colors.white, fontSize: 21);

  // Audioplayer for playing sound when timer runs out
  final AudioPlayer _player = AudioPlayer();

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
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

  bool _ignoreTemp = false;
  bool _ignoreHeartRate = false;

  // timer related attributes
  bool _timerButtonsActive = false;
  Duration _timerDuration = const Duration();

  @override
  void initState() {
    super.initState();

    // subscribe to device state
    _connectionStateSubscription = widget.device.state.listen((state) async {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }

      // if device is not connected and bluetooth is on, then we try to establish a connection
      if (state == BluetoothDeviceState.disconnected &&
          _connectionAttempts < _maxAttempts &&
          _keepReconnecting) {
        _connectDevice();
      }
    });
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// Most of the code was taken from the link above with some error handling added to it.
  /// connect to the chosen device via BLE and subscribe to sensor data characteristics.
  void _connectDevice() async {
    // services always have to be rediscovered on every connection attempt
    _services = [];

    // update state to connecting since this state is not emitted by the stream but we want to show it on the screen
    if (mounted) {
      setState(() {
        _connectionState = BluetoothDeviceState.connecting;
      });
    }

    // connect & handle timeout error
    // timeout must be handled specifically to avoid FlutterBlue bug which triggers an unhandled TimeoutException
    // despite having a try catch block
    try {
      await widget.device
          .connect(autoConnect: false)
          .timeout(const Duration(seconds: 15), onTimeout: () {
        if (mounted) {
          setState(() {
            _connectionState = BluetoothDeviceState.disconnected;
          });
        }
        showSnackBarError(widget._failedConnectionAttemptMessage);
        return;
      });
    } catch (e) {
      // if connection goes wrong then then we show error showing that connection failed
      if (mounted) {
        setState(() {
          _connectionState = BluetoothDeviceState.disconnected;
        });
      }
      showSnackBarError(widget._failedConnectionAttemptMessage);
      return;
    }

    // find services
    try {
      _services = await widget.device.discoverServices();
    } catch (e) {
      // if services cannot be discovered, then we disconnect from device which will trigger a reconnect.
      // This counts as a failed attempt at connecting for the purpose of the app
      _connectionAttempts++;
      if (!(_connectionAttempts < _maxAttempts)) {
        showSnackBarError(widget._failedConnectionAttemptMessage);
      }
      await widget.device.disconnect();
      return;
    }

    // subscribe to the necessary characteristics for reading the sensor data
    await subscribeToCharacteristics(_services);

    // check if necessary characteristics were found. If not then probably the wrong device was chosen so there is no point in reconnecting
    if (_bodyTempSubscription == null && _heartRateSubscription == null) {
      _keepReconnecting = false;
      showSnackBarError(widget._wrongDeviceMessage);
      await widget.device.disconnect();
    }
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// code was taken from link above
  /// subscribes to the characteristics that provide heart rate and body temperature
  Future<void> subscribeToCharacteristics(
      List<BluetoothService> services) async {
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        switch (c.uuid.toString()) {
          case "00002a37-0000-1000-8000-00805f9b34fb":
            await c.setNotifyValue(true);
            await Future.delayed(const Duration(milliseconds: 300));
            _heartRateSubscription = c.value.listen((sensorData) {
              updateHeartRate(sensorData);
            });
            break;

          case "00002a1c-0000-1000-8000-00805f9b34fb":
            await c.setNotifyValue(true);
            await Future.delayed(const Duration(milliseconds: 300));
            _bodyTempSubscription = c.value.listen(
              (sensorData) {
                updateBodyTemperature(sensorData);
              },
            );
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
  /// Error handling was added to the original code.
  /// [sensorData] is the raw data that is received from the earable.
  void updateBodyTemperature(sensorData) {
    // update only twice per second
    if (_ignoreTemp) return;
    Timer(const Duration(milliseconds: 500), () {
      _ignoreTemp = false;
    });
    _ignoreTemp = true;

    var flag;
    try {
      flag = sensorData[0];
    } on RangeError catch (e) {
      return; // skip when there is no valid data
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
        _bodyTemp = temperature;
      });
    }
  }

  /// credits to https://github.com/teco-kit/cosinuss-flutter-new/blob/main/lib/main.dart
  /// Most of the code was taken from the file above.
  /// Error handling was added to the original code.
  /// [sensorData] is the raw data that is received from the earable.
  void updateHeartRate(sensorData) {
    // update only twice per second
    if (_ignoreHeartRate) return;
    Timer(const Duration(milliseconds: 500), () {
      _ignoreHeartRate = false;
    });
    _ignoreHeartRate = true;

    Uint8List bytes = Uint8List.fromList(sensorData);

    if (bytes.isEmpty)
      return; // if empty then do nothing and return immediately

    // based on GATT standard
    var bpm;
    try {
      bpm = bytes[1];
    } on RangeError catch (e) {
      return; // skip if data is not valid
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

  /// Build a button that resets the timer when timer is active.
  /// When no timer is active then the button does nothing.
  ElevatedButton buildResetButton() {
    return ElevatedButton(
        onPressed: _timerButtonsActive
            ? () {
                setState(() {
                  _timerButtonsActive = false;
                });
              }
            : () {},
        child: Icon(Icons.timer_off,
            color: _timerButtonsActive
                ? Theme.of(context).primaryColor
                : Colors.grey));
  }

  /// Build the text widget which displays the current state of the connection.
  Widget buildStateText(BuildContext context) {
    Color textColor;
    String displayText;

    switch (_connectionState) {
      case BluetoothDeviceState.disconnected:
        textColor = Theme.of(context).colorScheme.error;
        displayText = widget._disconnectedString;
        break;

      case BluetoothDeviceState.connecting:
        textColor = Theme.of(context).colorScheme.tertiary;
        displayText = widget._connectingString;
        break;

      case BluetoothDeviceState.connected:
        textColor = Theme.of(context).colorScheme.secondary;
        displayText = widget._connectedString;
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
    if (_connectionState != BluetoothDeviceState.disconnected) {
      widget.device.disconnect();
    }
    _connectionStateSubscription.cancel();
    _heartRateSubscription?.cancel();
    _bodyTempSubscription?.cancel();
    widget._player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          // Appbar containing only a title
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: true,
          centerTitle: true,
          backgroundColor: backgroundColor,
          title: Text(widget._title, style: appBarTextStyle),
        ),
        body: Center(
          child: Column(
              // column containing the listview and the main container with all the tracking elements
              children: [
                Expanded(
                    // contains the scrollable listView showing various yoga poses
                    flex: 1,
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
                  flex: 2,
                  child: Container(
                      // container wrapping all tracking elements for styling purposes
                      padding: const EdgeInsets.all(largeSpacing),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(largeBorderRadius),
                              topRight: Radius.circular(largeBorderRadius))),
                      child: LayoutBuilder(
                        // LayoutBuilder to make the tracking elements scrollable on smaller screens so that there is no overflow
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            // makes content scrollable if there is an overflow
                            child: ConstrainedBox(
                              // constraints based on layoutbuilder
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                // main column of the tracking elements
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    // padding of status bar
                                    padding: const EdgeInsets.only(
                                        left: 2 * veryLargeSpacing,
                                        right: 2 * veryLargeSpacing),
                                    child: Container(
                                      // status bar for current connection status
                                      padding:
                                          const EdgeInsets.all(smallSpacing),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: backgroundColor,
                                          borderRadius: BorderRadius.circular(
                                              smallBorderRadius)),
                                      child: buildStateText(context),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: largeSpacing,
                                  ),
                                  Row(
                                    // contains all the timer elements
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        // expand to make timer button take up remaining space
                                        flex: 2,
                                        child: ElevatedButton(
                                          // wrap timer with button so that we can open timer picker sheet
                                          onPressed: () async {
                                            setState(() {
                                              _timerButtonsActive = false;
                                            });
                                            Duration timer =
                                                await showModalBottomSheet(
                                                        isScrollControlled:
                                                            true,
                                                        context: context,
                                                        builder: (BuildContext
                                                                context) =>
                                                            TimerPickerSheet()) ??
                                                    const Duration();
                                            // if we have a timer > 0 and context is still valid then we update the timer
                                            if (timer > const Duration()) {
                                              if (mounted) {
                                                setState(() {
                                                  _timerButtonsActive = true;
                                                  _timerDuration = timer;
                                                });
                                              }
                                            }
                                          },
                                          child: _timerButtonsActive
                                              ? TimerCountDown(
                                                  onEnd: () async {
                                                    setState(() {
                                                      _timerButtonsActive =
                                                          false;
                                                    });
                                                    await widget._player.play(
                                                      AssetSource(
                                                          'sounds/simple-notification.mp3'),
                                                    );
                                                    if (mounted) {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              const CustomDialog(
                                                                  titleText:
                                                                      'Finished!',
                                                                  contentText:
                                                                      'Your timer has hit 0.'));
                                                    }
                                                  },
                                                  timerDuration: _timerDuration,
                                                )
                                              : Text('Set Timer',
                                                  style: TextStyle(
                                                      fontSize: 19,
                                                      color: Theme.of(context)
                                                          .primaryColor)),
                                        ),
                                      ),
                                      const SizedBox(width: largeSpacing),
                                      Expanded(
                                          flex: 1, child: buildResetButton())
                                    ],
                                  ),
                                  const SizedBox(
                                    height: smallSpacing,
                                  ),
                                  Column(
                                    // contains tracking elements for current heart rate and body temp + section header
                                    children: [
                                      Text(
                                        widget._headerTracker,
                                        style: widget._headerTextStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: smallSpacing,
                                      ),
                                      DoubleBoxRow(
                                        leftTopText: 'Heart Rate',
                                        leftValue: _heartRate,
                                        leftBottomText: widget._bpmString,
                                        rightTopText: 'Body Temperature',
                                        rightValue: _bodyTemp,
                                        rightBottomText: 'Celsius',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: largeSpacing,
                                  ),
                                  Column(
                                    // contains the section header, the display elements for target and max heart rate and the row for the info buttons
                                    children: [
                                      Text(
                                        widget._headerRecommendation,
                                        style: widget._headerTextStyle,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: smallSpacing),
                                      DoubleBoxRow(
                                        leftValue: widget._targetHeartRate,
                                        rightValue: widget._maxHeartRate,
                                        leftBottomText: widget._bpmString,
                                        leftTopText:
                                            widget._targetHeartRateHeader,
                                        rightTopText:
                                            widget._maxHeartRateHeader,
                                        rightBottomText: widget._bpmString,
                                      ),
                                      const SizedBox(
                                        height: largeSpacing,
                                      ),
                                      Row(
                                        // contains the two information buttons
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Expanded(
                                            // expanded to force equal size
                                            flex: 1,
                                            child: ElevatedButton(
                                                // button which when pressed shows a dialog that explains the target heart rate
                                                onPressed: () => showDialog(
                                                    context: context,
                                                    builder: (context) => CustomDialog(
                                                        titleText: widget
                                                            ._targetHeartRateHeader,
                                                        contentText: widget
                                                            ._dialogContentTargetHeartRate)),
                                                child: const Icon(Icons.info)),
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
                                                        titleText: widget
                                                            ._maxHeartRateHeader,
                                                        contentText: widget
                                                            ._dialogContentMaxHeartRate)),
                                                child: const Icon(Icons.info)),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                )
              ]),
        ));
  }
}
