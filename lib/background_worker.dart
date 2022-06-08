import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/firebase_options.dart';
import 'package:school_app/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundWorker {
  static const _workName = 'notification-background-worker';
  static const _notificationIdKey = 'background-worker-notification-id';

  static late AndroidNotificationChannel notificationChannel;
  static late FlutterLocalNotificationsPlugin localNotificationsPlugin;

  static Future<bool> run() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await initializeNotifications();

    var sharedPreferences = await SharedPreferences.getInstance();
    var notificationId = sharedPreferences.getInt(_notificationIdKey) ?? 0;

    var tasks = await Database.I.queryTasksOnce();
    var now = DateTime.now().date;
    for (final task in tasks) {
      if (task.dueDate.isBefore(now) || task.dueDate.isAtSameMomentAs(now)) {
        Database.I.deleteTask(task.id);
        continue;
      }

      if (!task.completed &&
          (task.reminder.isBefore(now) ||
              task.reminder.isAtSameMomentAs(now))) {
        sendNotification(
          notificationId++,
          '${task.title} bald fällig (${task.subject.abbreviation})',
          'Die Aufgabe \'${task.title}\' (${task.subject.name}) ist ${task.formatRelativeDueDate()} fällig.',
        );
      }
    }

    // Loop around at 200
    if (notificationId > 200) notificationId = 0;
    sharedPreferences.setInt(_notificationIdKey, notificationId);

    // Re-schedule self to have a periodic worker
    schedule();
    return true;
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
    notificationChannel = const AndroidNotificationChannel(
      'task_notifications',
      'Aufgaben erinnerungen',
      description:
          'Die App sendet Erinnerungen für nicht abgeschlossene Aufgaben über diesen Kanal.',
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

  static void schedule() {
    var now = DateTime.now();
    DateTime nextRunTime;
    if (now.hour == 12) {
      nextRunTime = now;
    } else {
      nextRunTime = DateTime(now.year, now.month, now.day + 1, 12);
    }

    Workmanager().registerOneOffTask(
      _workName,
      _workName,
      initialDelay: nextRunTime.difference(now),
    );
  }
}
