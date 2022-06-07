import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  bool enabled = true;

  String email = "";
  String password = "";

  Future<void> signIn() async {
    setState(() => enabled = false);

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

    setState(() => enabled = true);
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
                  child: enabled
                      ? const Text('LOGIN')
                      : const CircularProgressIndicator(),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed:
                      enabled ? () => Get.to(() => const SignUpPage()) : null,
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
