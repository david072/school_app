import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/util.dart';

class AccountDialog extends StatefulWidget {
  const AccountDialog({Key? key}) : super(key: key);

  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: const Text('PASSWORT ÄNDERN'),
              onPressed: () async {
                bool result = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const _ChangePasswordDialog(),
                );

                if (result) {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pop(context);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginPage()));
                }
              },
            ),
          )
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
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(right, style: Theme.of(context).textTheme.subtitle2),
          ),
        ),
      ],
    );
  }
}

enum _ChangePasswordState { waiting, working, done, error }

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final GlobalKey formKey = GlobalKey<FormState>();

  String password = "";
  String oldPassword = "";

  var state = _ChangePasswordState.waiting;
  String? error;

  Future<void> changePassword() async {
    var formState = formKey.currentState! as FormState;
    if (!formState.validate()) return;

    setState(() => state = _ChangePasswordState.working);

    var result = await Authentication.updatePassword(oldPassword, password);
    if (result != null) {
      state = _ChangePasswordState.error;
      error = result;
      setState(() {});
      return;
    }

    setState(() => state = _ChangePasswordState.done);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Passwort ändern'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: state == _ChangePasswordState.waiting
              ? [
                  PasswordTextFormField(
                    labelText: 'Altes Passwort',
                    onChanged: (s) => oldPassword = s,
                  ),
                  PasswordTextFormField(
                    onChanged: (s) => password = s,
                  ),
                  PasswordTextFormField(
                    labelText: 'Passwort bestätigen',
                    onChanged: (_) {},
                    validator: (s) {
                      if (s == null || s.isEmpty) {
                        return 'Bitte gib ein Passwort an';
                      }
                      if (s != password) {
                        return 'Passwörter stimmen nicht überein';
                      }
                      return null;
                    },
                  )
                ]
              : state == _ChangePasswordState.working
                  ? [const CircularProgressIndicator()]
                  : state == _ChangePasswordState.done
                      ? [
                          const Text(
                              'Dein Passwort wurde erfolgreich geändert.')
                        ]
                      : [Text('Ein Fehler ist aufgetreten.\n\nFehler: $error')],
        ),
      ),
      actions: state == _ChangePasswordState.waiting
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ABBRECHEN'),
              ),
              TextButton(
                onPressed: changePassword,
                child: const Text('ÄNDERN'),
              ),
            ]
          : state == _ChangePasswordState.done ||
                  state == _ChangePasswordState.error
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context, state == _ChangePasswordState.done),
                    child: const Text('FERTIG'),
                  )
                ]
              : [],
    );
  }
}
