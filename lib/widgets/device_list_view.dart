import 'package:chillout_hrm/pages/body_tracker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

/// Listview containing tiles for each bluetooth device that is found by the bluetooth scan
class DeviceListView extends StatelessWidget {
  const DeviceListView({
    super.key,
    required this.itemList
  });

  final List<ScanResult> itemList;
  final double _fontSize = 16;
  final String _buttonString = 'Connect';

  /// Move to tracker page based on the chosen device
  void _onTilePressed (BuildContext context, int index) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => new TrackerPage(device: itemList[index].device)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemBuilder: (context, index) {
          if(itemList[index].device.name == "") return const SizedBox(height: 0); // filter out strange devices without names
          return Card(
            color: Colors.white,
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                // filled circle with bluetooth icon inside
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.bluetooth, color: Colors.white,)) ,
              title: Text(itemList[index].device.name),
              titleTextStyle: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
              trailing: ElevatedButton(
                onPressed: () {_onTilePressed(context, index);},
                child: Text(_buttonString),
              ),
            ),
          );
        },
        itemCount: itemList.length);
  }
}
