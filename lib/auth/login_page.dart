import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/auth/auth.dart';

import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";

  Future<void> signIn() async {
    var failState = await Authentication.signIn(
        formKey as GlobalKey<FormState>, email, password);
    if (failState == null) {
      Get.off(() => const HomePage());
      return;
    }

    if (failState == FailState.login) {
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
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (s) => setState(() => email = s),
                  validator: (s) {
                    if (s == null || !EmailValidator.validate(s)) {
                      return 'Bitte gib eine gültige Email-Adresse an';
                    }
                    return null;
                  },
                  decoration: _buildInputDecoration('Email'),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (s) => setState(() => password = s),
                  validator: (s) {
                    if (s == null || s.isEmpty) {
                      return 'Bitte gib ein Passwort an';
                    } else if (s.length < 6) {
                      return 'Das Passwort muss mindestens 6 Zeichen lang sein';
                    }

                    return null;
                  },
                  decoration: _buildInputDecoration('Passwort'),
                  obscureText: true,
                ),
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: signIn,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: const Text('LOGIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _buildInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    alignLabelWithHint: true,
  );
}
