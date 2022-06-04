import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/firebase_options.dart';

import 'auth/login_page.dart';
import 'home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'School App',
    home: Setup(),
  ));
}

class Setup extends StatefulWidget {
  const Setup({Key? key}) : super(key: key);

  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  @override
  void initState() {
    super.initState();
    setup();
  }

  Future<void> setup() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.off(() => const LoginPage());
    } else {
      Get.off(() => const HomePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 40),
            Text(
              'Starte...',
              style: Theme.of(context).textTheme.headline5,
            ),
          ],
        ),
      ),
    );
  }
}
