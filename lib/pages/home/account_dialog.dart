import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/main.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
              child: Text('change_password_caps'.tr),
              onPressed: () async {
                bool result = await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const _ChangePasswordDialog(),
                );

                if (!result) return;
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Get.back();
                Get.off(() => const LoginPage());
              },
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            child: Text('delete_account_caps'.tr),
            onPressed: () async {
              bool result = await showDialog(
                context: context,
                builder: (_) => const _DeleteAccountDialog(),
              );

              if (!result) return;
              if (!mounted) return;
              Get.back();
              Get.off(() => const LoginPage());
            },
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

enum _SensitiveUserActionState { waiting, working, done, error }

class _SensitiveUserActionDialog extends StatefulWidget {
  const _SensitiveUserActionDialog({
    Key? key,
    required this.children,
    required this.confirmText,
    required this.title,
    required this.successText,
    required this.doAction,
  }) : super(key: key);

  final List<Widget> children;
  final String confirmText;
  final String title;
  final String successText;
  final Future<String?> Function() doAction;

  @override
  State<_SensitiveUserActionDialog> createState() =>
      _SensitiveUserActionDialogState();
}

class _SensitiveUserActionDialogState
    extends State<_SensitiveUserActionDialog> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var state = _SensitiveUserActionState.waiting;
  String? error;

  Future<void> changePassword() async {
    var formState = formKey.currentState! as FormState;
    if (!formState.validate()) return;

    setState(() => state = _SensitiveUserActionState.working);

    var result = await widget.doAction();
    if (result != null) {
      state = _SensitiveUserActionState.error;
      error = result;
      setState(() {});
      return;
    }

    setState(() => state = _SensitiveUserActionState.done);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: state == _SensitiveUserActionState.waiting
              ? widget.children
              : state == _SensitiveUserActionState.working
                  ? [const CircularProgressIndicator()]
                  : state == _SensitiveUserActionState.done
                      ? [Text(widget.successText)]
                      : [
                          Text('error_occured'.trParams({'error': error!}))
                        ],
        ),
      ),
      actions: state == _SensitiveUserActionState.waiting
          ? [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('cancel_caps'.tr),
              ),
              TextButton(
                onPressed: changePassword,
                child: Text(widget.confirmText),
              ),
            ]
          : state == _SensitiveUserActionState.done ||
                  state == _SensitiveUserActionState.error
              ? [
                  TextButton(
                    onPressed: () => Get.back(
                        result: state == _SensitiveUserActionState.done),
                    child: Text('done_caps'.tr),
                  )
                ]
              : [],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  String oldPassword = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return _SensitiveUserActionDialog(
      title: 'change_password'.tr,
      confirmText: 'change_caps'.tr,
      successText: 'cp_success_text'.tr,
      doAction: () => Authentication.updatePassword(oldPassword, password),
      children: [
        PasswordTextFormField(
          labelText: 'cp_old_password'.tr,
          onChanged: (s) => oldPassword = s,
        ),
        PasswordTextFormField(
          onChanged: (s) => password = s,
        ),
        PasswordTextFormField(
          labelText: 'confirm_password'.tr,
          onChanged: (_) {},
          validator: (s) {
            if (s == null || s.isEmpty) {
              return 'password_missing'.tr;
            }
            if (s != password) {
              return 'passwords_not_matching'.tr;
            }
            return null;
          },
        )
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({Key? key}) : super(key: key);

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  String password = "";

  @override
  Widget build(BuildContext context) {
    return _SensitiveUserActionDialog(
      title: 'delete_account'.tr,
      confirmText: 'delete_caps'.tr,
      successText: 'da_success_text'.tr,
      doAction: () async {
        // Re-authenticate first
        var reauthenticateResult =
            await Authentication.reauthenticate(password);
        if (reauthenticateResult != null) return reauthenticateResult;

        Database.I.deleteAllData();
        var sharedPreferences = await SharedPreferences.getInstance();
        sharedPreferences.remove(noAccountKey);

        return Authentication.deleteUser();
      },
      children: [
        PasswordTextFormField(
          onChanged: (s) => password = s,
        ),
      ],
    );
  }
}
