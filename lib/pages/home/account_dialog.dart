import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountDialog extends StatelessWidget {
  const AccountDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            left: 'Email',
            right: FirebaseAuth.instance.currentUser!.email!,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    Key? key,
    required this.left,
    required this.right,
  }) : super(key: key);

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$left:'),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(right, style: Theme.of(context).textTheme.bodyText1),
          ),
        )
      ],
    );
  }
}
