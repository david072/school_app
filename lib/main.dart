import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/background_worker.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/firebase_options.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/home/home_page.dart';
import 'package:school_app/util/app_notifications.dart';
import 'package:school_app/util/translations/app_translations.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const noAccountKey = 'no-account';
const themeModeKey = 'application-theme-mode';
const localeStringKey = 'user-locale-string';

void callbackDispatcher() {
  Workmanager().executeTask(
      (taskName, inputData) => BackgroundWorker.run(inputData!['runHour']));
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppNotifications.initialize();

  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'School App',
    home: const Setup(),
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.light,
    translations: AppTranslations(),
    locale: Get.deviceLocale,
    fallbackLocale: const Locale('de', 'DE'),
  ));
}

class Setup extends StatefulWidget {
  const Setup({Key? key}) : super(key: key);

  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> with AfterLayoutMixin {
  String? error;

  @override
  void afterFirstLayout(BuildContext context) => setup();

  /// Initializes app dependencies and decides whether the user should
  /// continue on the [LoginPage] or on the [HomePage].
  Future<void> setup() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    // Why can I not access the locale from the background worker????
    if (Get.deviceLocale != null) {
      sharedPreferences.setString(
        localeStringKey,
        "${Get.deviceLocale!.languageCode}_${Get.deviceLocale!.countryCode}",
      );
    }

    Get.changeThemeMode(await getThemeMode());

    bool crashlyticsReady = false;
    try {
      await Workmanager().initialize(callbackDispatcher);

      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Disable Crashlytics when in debug mode
      if (kDebugMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      } else {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        crashlyticsReady = true;
      }

      if (!mounted) return;
      await AppNotifications.requestPermissions(context);

      // Schedule BackgroundWorker if necessary
      BackgroundWorker.schedule();

      // Go to HomePage without login if the user does not have an account
      if (sharedPreferences.getBool(noAccountKey) ?? false) {
        Database.use(DatabaseSqlite());
        Get.off(const HomePage(hasAccount: false));
        return;
      }

      // Go to LoginPage / HomePage depending on whether the user is logged in
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.off(() => const LoginPage());
      } else {
        Database.use(DatabaseFirestore());
        Get.off(() => const HomePage());
      }
    } catch (e, stack) {
      setState(() => error = '$e\n\n$stack');

      if (!kDebugMode && !crashlyticsReady) {
        FirebaseCrashlytics.instance.recordError(e, stack);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = [
      error == null
          ? const CircularProgressIndicator()
          : const Icon(Icons.error, color: Colors.red),
      const SizedBox(height: 40),
      Text(
        error == null ? 'starting'.tr : 'error'.tr,
        style: Theme.of(context).textTheme.headline5,
      ),
    ];

    if (error != null) {
      children.add(const SizedBox(height: 20));
      children.add(Text(error!));
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
