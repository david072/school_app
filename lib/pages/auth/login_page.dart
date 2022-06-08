import 'package:flutter/material.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/main.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

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
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (s) => setState(() => email = s),
                  validator: InputValidator.validateEmail,
                  decoration: buildInputDecoration('Email'),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  enabled: enabled,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (s) => setState(() => password = s),
                  validator: InputValidator.validatePassword,
                  decoration: buildInputDecoration('Passwort'),
                  obscureText: true,
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
                const SizedBox(height: 20),
                TextButton(
                  onPressed: enabled
                      ? () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()))
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
                                        builder: (_) => const HomePage()));
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
    );
  }
}
