import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/auth/auth.dart';
import 'package:school_app/auth/signup_page.dart';

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
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: signIn,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: const Text('LOGIN'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.to(() => const SignUpPage()),
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
