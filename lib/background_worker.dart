import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/database/database_sqlite.dart';
import 'package:school_app/firebase_options.dart';
import 'package:school_app/main.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundWorker {
  static const _workName = 'notification-background-worker';
  static const _notificationIdKey = 'background-worker-notification-id';
  static const _processedTaskIdsKey = 'background-worker-processed-task-ids';

  static const _lastRunHourKey = 'background-worker-last-run-hour';
  static const _runHours = [13, 14, 15, 16, 18];

  static late AndroidNotificationChannel notificationChannel;
  static late FlutterLocalNotificationsPlugin localNotificationsPlugin;

  static SharedPreferences? sharedPreferences;

  static Future<bool> run(int runHour) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await initializeNotifications();

    sharedPreferences = await SharedPreferences.getInstance();
    var notificationId = sharedPreferences!.getInt(_notificationIdKey) ?? 0;

    var noAccount = sharedPreferences!.getBool(noAccountKey);
    if (noAccount ?? false) {
      Database.use(DatabaseSqlite());
    } else {
      // DatabaseFirestore requires a user. If there is no user, we can't query
      if (FirebaseAuth.instance.currentUser == null) return true;
      Database.use(DatabaseFirestore());
    }

    var tasks = await Database.I.queryTasksOnce();
    var now = DateTime.now().date;
    for (final task in tasks) {
      if (await hasProcessedTask(task.id)) continue;

      if (task.dueDate.isBefore(now) || task.dueDate.isAtSameMomentAs(now)) {
        Database.I.deleteTask(task.id);
        continue;
      }

      if (!task.completed &&
          (task.reminder.isBefore(now) ||
              task.reminder.isAtSameMomentAs(now))) {
        sendNotification(
          notificationId++,
          'task_notification_title'.trParams({
            'title': task.title,
            'subjectAbb': task.subject.abbreviation,
          }),
          'task_notification_content'.trParams({
            'title': task.title,
            'subjectName': task.subject.name,
            'relDueDate': task.formatRelativeDueDate(),
          }),
        );
      }

      markTaskProcessed(task.id);
    }

    // Loop around at 200
    if (notificationId > 200) notificationId = 0;
    sharedPreferences!.setInt(_notificationIdKey, notificationId);

    sharedPreferences!.setInt(_lastRunHourKey, runHour);

    // Re-schedule self to have a periodic worker
    schedule();
    return true;
  }

  static Future<bool> hasProcessedTask(String id) async {
    sharedPreferences ??= await SharedPreferences.getInstance();

    var list = sharedPreferences!.getStringList(_processedTaskIdsKey);
    if (list == null) return false;

    return list.contains(id);
  }

  static Future<void> markTaskProcessed(String id) async {
    sharedPreferences ??= await SharedPreferences.getInstance();

    var list = sharedPreferences!.getStringList(_processedTaskIdsKey) ?? [];
    if (!list.contains(id)) list.add(id);
    sharedPreferences!.setStringList(_processedTaskIdsKey, list);
  }

  static Future<void> sendNotification(
      int id, String title, String body) async {
    await localNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationChannel.id,
          notificationChannel.name,
          channelDescription: notificationChannel.description,
        ),
        iOS: const IOSNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  static Future<void> initializeNotifications() async {
    notificationChannel = AndroidNotificationChannel(
      'task_notifications',
      'notification_channel_name'.tr,
      description: 'notification_channel_description'.tr,
      importance: Importance.high,
    );
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettingsMacOS = const MacOSInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
    );
    localNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()!
          .createNotificationChannel(notificationChannel);
    }
  }

  static Future<void> requestNotificationPermissions() async {
    localNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    localNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isIOS) {
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()!
          .requestPermissions(
            alert: true,
            badge: true,
          );
    } else if (Platform.isMacOS) {
      await localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()!
          .requestPermissions(
            alert: true,
            badge: true,
          );
    }
  }

  static Future<int> getNextRunHour() async {
    sharedPreferences ??= await SharedPreferences.getInstance();
    var lastRunHour = sharedPreferences!.getInt(_lastRunHourKey);

    var nextRunHour = 0;
    if (lastRunHour == null) {
      nextRunHour = _runHours[0];
    } else {
      nextRunHour =
          _runHours[(_runHours.indexOf(lastRunHour) + 1) % _runHours.length];
    }

    return nextRunHour;
  }

  static Future<void> resetProcessedTasks() async {
    sharedPreferences ??= await SharedPreferences.getInstance();
    sharedPreferences!.setStringList(_processedTaskIdsKey, []);
  }

  static Future<void> schedule() async {
    var nextRunHour = await getNextRunHour();
    if (nextRunHour == _runHours[0]) resetProcessedTasks();

    var now = DateTime.now();
    var day = now.hour < nextRunHour ? now.day : now.day + 1;
    var nextRunTime = DateTime(now.year, now.month, day, nextRunHour);

    Workmanager().registerOneOffTask(
      _workName,
      _workName,
      initialDelay: nextRunTime.difference(now),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      inputData: {'runHour': nextRunHour},
    );
  }
}
