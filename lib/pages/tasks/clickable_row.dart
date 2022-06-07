import 'package:flutter/material.dart';

class ClickableRow extends StatelessWidget {
  const ClickableRow({
    Key? key,
    required this.left,
    required this.right,
    this.onTap,
  }) : super(key: key);

  final Widget left;
  final Widget right;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    Widget child = Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          left,
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: right,
            ),
          )
        ],
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            child: child,
          )
        : child;
  }
}
