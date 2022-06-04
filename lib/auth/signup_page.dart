import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_page.dart';
import 'auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";
  String confirmPassword = "";

  Future<void> signUp() async {
    var failState = await Authentication.signUp(
        formKey as GlobalKey<FormState>, email, password);
    if (failState == null) {
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
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (s) => setState(() => email = s),
                  validator: InputValidator.validateEmail,
                  decoration: buildInputDecoration('Email'),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (s) => setState(() => password = s),
                  validator: InputValidator.validatePassword,
                  decoration: buildInputDecoration('Passwort'),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                TextFormField(
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
                  onPressed: signUp,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: const Text('REGISTRIEREN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
