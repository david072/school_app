import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/app_state.dart';
import 'package:school_app/data/auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/main.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    Key? key,
    this.migrate = false,
  }) : super(key: key);

  final bool migrate;

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
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setBool(noAccountKey, false);

      if (widget.migrate) await DatabaseSqlite.migrateToFirestore();

      if (!mounted) return;
      Database.use(DatabaseFirestore());
      AppState.init(hasAccount: true);

      if (!widget.migrate) Get.back();
      Get.off(() => const HomePage());
      return;
    }

    if (failState == FailState.authentication) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('signup_failed'.tr)),
      );
    }

    setState(() => enabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('signup_title'.tr),
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
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (s) => setState(() => email = s),
                    validator: InputValidator.validateEmail,
                    decoration: buildInputDecoration('email'.tr),
                  ),
                  const SizedBox(height: 30),
                  PasswordTextFormField(
                    enabled: enabled,
                    onChanged: (s) => setState(() => password = s),
                  ),
                  const SizedBox(height: 30),
                  PasswordTextFormField(
                    labelText: 'confirm_password'.tr,
                    enabled: enabled,
                    onChanged: (s) => setState(() => confirmPassword = s),
                    validator: (s) {
                      if (s == null || s.isEmpty) {
                        return 'password_missing'.tr;
                      }
                      if (s != password) {
                        return 'password_not_matching'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 80),
                  MaterialButton(
                    onPressed: enabled ? signUp : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text('register_caps'.tr)
                        : const CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
