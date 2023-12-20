import 'dart:async';

import 'package:flutter/material.dart';

/// This class is a simple Countdown widget which on creation starts a countdown from the provided [timerDuration].
/// After the duration is over the [onEnd] Function is called.
class TimerCountDown extends StatefulWidget {
  const TimerCountDown(
      {super.key, required this.onEnd, required this.timerDuration});

  final Function onEnd;
  final Duration timerDuration;

  static const TextStyle separatorTextStyle =
      TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold);

  static const TextStyle numberTextStyle =
      TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

  @override
  State<TimerCountDown> createState() => _TimerCountDownState();
}

class _TimerCountDownState extends State<TimerCountDown> {
  late Timer? timer;
  late Duration _timerDuration;
  String _hours = '00';
  String _minutes = '00';
  String _seconds = '00';

  /// Update the Strings that show the hours, minutes and seconds remaining
  void _formatStrings() {
    _hours = _numToString(_timerDuration.inHours.remainder(24));
    _minutes = _numToString(_timerDuration.inMinutes.remainder(60));
    _seconds = _numToString(_timerDuration.inSeconds.remainder(60));
  }

  /// Provide string representation of the given [number] but add a leading 0 if the number is smaller than 10.
  String _numToString(num number) {
    if (number <= 9) {
      return '0$number';
    }
    return '$number';
  }

  @override
  void initState() {
    // set timer duration and format strings
    _timerDuration = widget.timerDuration;
    _formatStrings();

    // start periodic timer that updates the remaining duration
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerDuration -= const Duration(seconds: 1);
      if (_timerDuration.isNegative) {
        widget.onEnd();
        timer.cancel();
      }
      if (mounted) {
        // if state is still valid then update the text that is displayed to show the new remaining duration.
        setState(() {
          _formatStrings();
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // dispose of active timer and then dispose of widget
    if (timer!.isActive) {
      timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      // simple row which contains the hours, minutes and seconds of the timer separated by ':'
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_hours, style: TimerCountDown.numberTextStyle),
        const Text(
          ' : ',
          style: TimerCountDown.separatorTextStyle,
        ),
        Text(_minutes, style: TimerCountDown.numberTextStyle),
        const Text(
          ' : ',
          style: TimerCountDown.separatorTextStyle,
        ),
        Text(_seconds, style: TimerCountDown.numberTextStyle)
      ],
    );
  }
}
