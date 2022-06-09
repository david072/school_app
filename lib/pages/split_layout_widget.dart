import 'package:flutter/material.dart';

class SplitLayout extends StatelessWidget {
  const SplitLayout({
    Key? key,
    required this.first,
    required this.second,
  }) : super(key: key);

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    var isHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    var children = [
      first,
      const VerticalDivider(width: 0),
      second,
    ];

    return Center(
        child: !isHorizontal
            ? Column(children: children)
            : Row(children: children));
  }
}
