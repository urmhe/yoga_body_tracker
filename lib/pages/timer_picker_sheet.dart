import 'package:chillout_hrm/global.dart';
import 'package:chillout_hrm/widgets/rounded_button.dart';
import 'package:flutter/material.dart';

import '../widgets/time_and_subtext.dart';
import '../widgets/time_selector.dart';

/// This is used as a modalbottomsheet for setting up a timer.
class TimerPickerSheet extends StatefulWidget {
  const TimerPickerSheet({
    super.key,
  });

  @override
  State<TimerPickerSheet> createState() => _TimerPickerSheetState();
}

class _TimerPickerSheetState extends State<TimerPickerSheet> {
  // used to track the user input
  int _seconds = 0;
  int _hours = 0;
  int _minutes = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      // main container which wraps all widgets
      decoration: const BoxDecoration(
        color: backgroundColor,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(largeSpacing),
      child: Column(
        // main column which encompasses all elements of the page
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            // contains the header elements that show what the current timer is separated by ':'
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TimeAndSubtext(
                numVal: _hours,
                subText: 'H',
              ),
              Text(
                ':',
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 38,
                    fontWeight: FontWeight.bold),
              ),
              TimeAndSubtext(
                numVal: _minutes,
                subText: 'M',
              ),
              Text(
                ':',
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 38,
                    fontWeight: FontWeight.bold),
              ),
              TimeAndSubtext(
                numVal: _seconds,
                subText: 'S',
              )
            ],
          ),
          Row(
            // contains the 3 numberpicker elements for choosing hours, minutes and seconds
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TimeSelector(
                value: _hours,
                header: 'Hours',
                maxVal: 23,
                onChanged: (int value) {
                  setState(() {
                    _hours = value;
                  });
                },
              ),
              TimeSelector(
                value: _minutes,
                header: 'Minutes',
                maxVal: 59,
                onChanged: (int value) {
                  setState(() {
                    _minutes = value;
                  });
                },
              ),
              TimeSelector(
                value: _seconds,
                header: 'Seconds',
                maxVal: 59,
                onChanged: (int value) {
                  setState(() {
                    _seconds = value;
                  });
                },
              ),
            ],
          ),
          LargeRoundedButton(
              // button to return to tracking page and provide the created timer as Duration
              backgroundColor: Theme.of(context).cardColor,
              buttonText: 'Start Timer',
              textColor: Theme.of(context).primaryColor,
              onPressed: () => Navigator.pop(
                  context,
                  Duration(
                      hours: _hours, minutes: _minutes, seconds: _seconds)))
        ],
      ),
    );
  }
}
