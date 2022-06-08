import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app/background_worker.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/firebase_options.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const noAccountKey = 'no-account';

void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) => BackgroundWorker.run());
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
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
    await Workmanager().initialize(callbackDispatcher);
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    await BackgroundWorker.requestNotificationPermissions();
    BackgroundWorker.schedule();

    GetIt.I.allowReassignment = true;

    var sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (sharedPreferences.getBool(noAccountKey) ?? false) {
      Database.use(DatabaseSqlite());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
      return;
    }

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      Database.use(DatabaseFirestore());
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
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
