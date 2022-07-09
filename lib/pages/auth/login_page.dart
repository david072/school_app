import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/main.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey formKey = GlobalKey<FormState>();
  final GlobalKey emailFieldKey = GlobalKey<FormFieldState>();

  bool showContinueWithoutAccountButton = false;

  bool enabled = true;
  bool isContinuingWithoutAccount = false;

  String email = "";
  String password = "";

  Future<void> signIn() async {
    setState(() => enabled = false);

    var failState = await Authentication.signIn(
        formKey as GlobalKey<FormState>, email, password);
    if (failState == null) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setBool(noAccountKey, false);

      if (!mounted) return;
      Database.use(DatabaseFirestore());
      Get.off(() => const HomePage());
      return;
    }

    if (failState == FailState.authentication) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('login_failed'.tr),
        ),
      );
    }

    setState(() => enabled = true);
  }

  Future<void> resetPassword() async {
    var emailFieldState = emailFieldKey.currentState as FormFieldState?;
    if (emailFieldState == null || !emailFieldState.validate()) return;

    showDialog(
      context: context,
      builder: (_) => _PasswordResetDialog(email: email),
    );
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then(
      (i) => setState(() =>
          showContinueWithoutAccountButton = !i.containsKey(noAccountKey)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('login_title'.tr),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: formWidth(context),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    key: emailFieldKey,
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (s) => setState(() => email = s),
                    validator: InputValidator.validateEmail,
                    decoration: buildInputDecoration('email'.tr),
                  ),
                  const SizedBox(height: 30),
                  PasswordTextFormField(
                    enabled: enabled,
                    onChanged: (s) => password = s,
                  ),
                  const SizedBox(height: 80),
                  MaterialButton(
                    onPressed: enabled ? signIn : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled || isContinuingWithoutAccount
                        ? Text('submit_button'.tr)
                        : const CircularProgressIndicator(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: resetPassword,
                            child: Text('forgot_password_button'.tr),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed:
                        enabled ? () => Get.to(() => const SignUpPage()) : null,
                    child: Text('register_caps'.tr),
                  ),
                  showContinueWithoutAccountButton
                      ? TextButton(
                          onPressed: enabled
                              ? () async {
                                  setState(() {
                                    enabled = false;
                                    isContinuingWithoutAccount = true;
                                  });

                                  var sharedPreferences =
                                      await SharedPreferences.getInstance();
                                  sharedPreferences.setBool(noAccountKey, true);

                                  if (!mounted) return;
                                  Database.use(DatabaseSqlite());
                                  Get.off(
                                      () => const HomePage(hasAccount: false));
                                }
                              : null,
                          child: !isContinuingWithoutAccount
                              ? Text('continue_without_account'.tr)
                              : const CircularProgressIndicator(),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({
    Key? key,
    required this.email,
  }) : super(key: key);

  final String email;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  bool hasSentEmail = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Authentication.sendPasswordReset(widget.email).then((e) {
      if (e != null) {
        error = e;
      } else {
        hasSentEmail = true;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('password_reset_title'.tr),
      content: error != null
          ? Text('error_occured'.trParams({'error': error!}))
          : hasSentEmail
              ? SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'password_reset_success_start'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              ?.copyWith(color: Colors.black),
                        ),
                        TextSpan(
                          text: widget.email,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        TextSpan(
                          text: 'password_reset_success_end'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1
                              ?.copyWith(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [CircularProgressIndicator()],
                ),
      actions: [
        error != null || hasSentEmail
            ? TextButton(
                onPressed: () => Get.back(),
                child: Text('confirm'.tr),
              )
            : Container(),
      ],
    );
  }
}
