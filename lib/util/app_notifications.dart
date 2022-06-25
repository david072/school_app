import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/background_worker.dart';

class AppNotifications {
  static const _markTaskCompletedActionKey = 'mark-task-completed-action';
  static const _taskIdPayloadKey = 'taskId';

  static const _taskNotificationsChannelGroupKey =
      'task_notifications_channel_group';
  static const _taskNotificationsChannelKey = 'task_notifications';

  static void initialize() {
    final taskNotificationsChannelGroupName = 'notification_channel_name'.tr;
    final taskNotificationsChannelName = 'notification_channel_name'.tr;
    final taskNotificationsChannelDescription =
        'notification_channel_description'.tr;

    AwesomeNotifications().actionStream.listen((event) {
      if (event.payload == null) return;
      if (event.payload![_taskIdPayloadKey] == null) return;

      BackgroundWorker.markTaskCompleted(event.payload![_taskIdPayloadKey]!);
      AwesomeNotifications().dismiss(event.id!);
    });

    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: _taskNotificationsChannelGroupKey,
          channelKey: _taskNotificationsChannelKey,
          channelName: taskNotificationsChannelName,
          channelDescription: taskNotificationsChannelDescription,
          importance: NotificationImportance.High,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupkey: _taskNotificationsChannelGroupKey,
          channelGroupName: taskNotificationsChannelGroupName,
        ),
      ],
    );
  }

  static Future<void> createTaskNotification(
      String taskId, String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _getNotificationId(),
        channelKey: _taskNotificationsChannelKey,
        title: title,
        body: body,
        payload: {_taskIdPayloadKey: taskId},
      ),
      actionButtons: [
        NotificationActionButton(
          key: _markTaskCompletedActionKey,
          label: 'notification_action_mark_completed'.tr,
        ),
      ],
    );
  }

  static int _getNotificationId() {
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  static Future<void> requestPermissions(BuildContext context) async {
    var isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('notification_permissions_request_title'.tr),
          content: Text('notification_permissions_request_content'.tr),
          actions: [
            TextButton(
              child: Text('dont_allow_caps'.tr),
              onPressed: () => Get.back(),
            ),
            TextButton(
              child: Text('allow_caps'.tr),
              onPressed: () async {
                await AwesomeNotifications()
                    .requestPermissionToSendNotifications();
                Get.back();
              },
            ),
          ],
        ),
      );
    }
  }
}
