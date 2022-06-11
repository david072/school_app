import 'package:flutter/material.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/main.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/sizes.dart';
import 'package:school_app/util.dart';
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }

    if (failState == FailState.authentication) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Login fehlgeschlagen. Bitte versuche es später nochmal."),
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
        title: const Text('Login'),
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
                    decoration: buildInputDecoration('Email'),
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
                        ? const Text('LOGIN')
                        : const CircularProgressIndicator(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: resetPassword,
                            child: const Text('PASSWORT VERGESSEN'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: enabled
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpPage()))
                        : null,
                    child: const Text('REGISTRIEREN'),
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
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const HomePage(
                                              hasAccount: false)));
                                }
                              : null,
                          child: !isContinuingWithoutAccount
                              ? const Text('OHNE ACCOUNT FORTFAHREN')
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
      title: const Text('Passwort zurücksetzen'),
      content: error != null
          ? Text(
              'Ein Fehler ist aufgetreten. Bitte versuche es später nochmal.\nFehler: $error')
          : hasSentEmail
              ? SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Es wurde eine Email an ',
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
                          text: ' gesendet, mit welcher du '
                              'dein Passwort zurücksetzen kannst. Dann kannst du dich hier mit '
                              'deinem neuen Passwort anmelden.\n\n'
                              'Bitte schaue auch in deinen Spam-Ordner.',
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
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            : Container(),
      ],
    );
  }
}
