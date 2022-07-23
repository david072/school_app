import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/tasks/abstract_task.dart';

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

class ShareDialog extends StatefulWidget {
  const ShareDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  final AbstractTask task;

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  String? link;

  @override
  void initState() {
    Database.I.createLink(widget.task).then((l) => setState(() => link = l));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link'),
      content: link != null
          ? Text(link!)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: const [CircularProgressIndicator()],
            ),
      actions: link != null
          ? [
              TextButton(
                child: const Text('COPY'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                    ),
                  );
                },
              ),
            ]
          : [],
    );
  }
}
