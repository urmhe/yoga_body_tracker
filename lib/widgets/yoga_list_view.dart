import 'package:chillout_hrm/global.dart';
import 'package:flutter/material.dart';

/// Listview which contains yoga illustrations with a horizontal scoll behaviour
class YogaListView extends StatelessWidget {
  YogaListView({
    super.key,
  });

  final ScrollController _controller = ScrollController();

  /// Build List containing the image paths which will be used by the listView
  List<String> buildPicturePathList() {
    List<String> output = <String>[];
    for (int i = 1; i <= 12; i++) {
      output.add('assets/images/yoga-pose$i.jpg');
    }
    return output;
  }

  @override
  Widget build(BuildContext context) {
    List<String> pictures = buildPicturePathList();
    return Scrollbar(
      // show scrollbar below listview
      interactive: true,
      thumbVisibility: true,
      controller: _controller,
      trackVisibility: true,
      child: ListView.builder(
          controller: _controller,
          physics: const PageScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: pictures.length,
          itemBuilder: (context, index) {
            return Container(
              // container for each image
              width: MediaQuery.of(context).size.width - 2 * smallSpacing,
              // picture should fill entire screen minus padding on both sides
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(regularBorderRadius),
                  image: DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage(pictures.elementAt(index)))),
            );
          }),
    );
  }
}
