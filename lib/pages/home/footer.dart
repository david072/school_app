import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({
    Key? key,
    this.reverse = false,
    required this.displayName,
    required this.count,
    required this.onAdd,
  }) : super(key: key);

  final bool reverse;
  final String displayName;
  final int count;
  final void Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          !reverse
              ? Text(
                  '$displayName: $count',
                  style: Theme.of(context).textTheme.caption,
                )
              : Container(),
          Expanded(
            child: Align(
              alignment:
                  !reverse ? Alignment.centerRight : Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(5),
                ),
              ),
            ),
          ),
          !reverse
              ? Container()
              : Text(
                  '$displayName: $count',
                  style: Theme.of(context).textTheme.caption,
                ),
        ],
      ),
    );
  }
}