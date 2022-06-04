import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  String email = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width / 2,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (s) => setState(() => email = s),
                  // validator
                  decoration: _buildInputDecoration('Email'),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (s) => setState(() => password = s),
                  // validator
                  decoration: _buildInputDecoration('Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: () => print("asdf"),
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
