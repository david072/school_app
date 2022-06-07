import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  bool enabled = true;

  String email = "";
  String password = "";
  String confirmPassword = "";

  Future<void> signUp() async {
    setState(() => enabled = false);

    var failState = await Authentication.signUp(
        formKey as GlobalKey<FormState>, email, password);
    if (failState == null) {
      Get.back();
      Get.off(() => const HomePage());
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(height: 30),
                TextFormField(
                  enabled: enabled,
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (s) => setState(() => confirmPassword = s),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return 'Bitte gib ein Passwort an';
                    }
                    if (s != password) {
                      return 'Passwörter stimmen nicht überein';
                    }
                    return null;
                  },
                  decoration: buildInputDecoration('Passwort bestätigen'),
                  obscureText: true,
                ),
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: enabled ? signUp : null,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: enabled
                      ? const Text('REGISTRIEREN')
                      : const CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
