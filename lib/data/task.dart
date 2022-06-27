import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/model/relative_date_time.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/util/util.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime reminder;
  final Subject subject;
  final bool completed;

  final DateTime? deletedAt;

  const Task(
    this.id,
    this.title,
    this.description,
    this.dueDate,
    this.reminder,
    this.subject,
    this.completed, [
    this.deletedAt,
  ]);

  static Future<Task> fromDocument(DocumentSnapshot<Map<String, dynamic>> doc,
      {bool isDeleted = false}) {
    return _fromMap(doc.id, doc.data()!, hasBool: true, isDeleted: isDeleted);
  }

  static Future<Task> fromRow(Map<String, dynamic> row,
      {bool isDeleted = false}) {
    return _fromMap(
      row['id'].toString(),
      row,
      hasBool: false,
      isDeleted: isDeleted,
    );
  }

  static Future<Task> _fromMap(String id, Map<String, dynamic> map,
      {bool hasBool = true, bool isDeleted = false}) async {
    bool completed;
    if (hasBool) {
      completed = map['completed'];
    } else {
      completed = map['completed'] as int == 1 ? true : false;
    }

    var dateTime = DateTime.fromMillisecondsSinceEpoch;

    return Task(
      id,
      map['title'],
      map['description'],
      dateTime(map['due_date']),
      dateTime(map['reminder']),
      await Database.I.querySubjectOnce(map['subject_id'].toString()),
      completed,
      !isDeleted ? null : dateTime(map['deleted_at']),
    );
  }

  String formatRelativeDueDate() {
    return _formatRelativeDate(
      RelativeDateTime(dateTime: DateTime.now().date, other: dueDate),
    );
  }

  String formatRelativeDeletedAtDate() {
    assert(deletedAt != null);
    return _formatRelativeDate(
      RelativeDateTime(dateTime: deletedAt!, other: DateTime.now().date),
    );
  }

  String _formatRelativeDate(RelativeDateTime rdt) =>
      RelativeDateFormat(Get.locale ?? const Locale('de')).format(rdt);

  Duration reminderOffset() => dueDate.difference(reminder);
}

enum ReminderMode {
  none,
  oneDayBefore,
  twoDaysBefore,
  threeDaysBefore,
  fourDaysBefore,
  oneWeekBefore,
  twoWeeksBefore,
  custom,
}

extension E on ReminderMode {
  String get string {
    switch (this) {
      case ReminderMode.none:
        return 'no_reminder'.tr;
      case ReminderMode.oneDayBefore:
        return 'reminder_one_day'.tr;
      case ReminderMode.twoDaysBefore:
        return 'reminder_two_days'.tr;
      case ReminderMode.threeDaysBefore:
        return 'reminder_three_days'.tr;
      case ReminderMode.fourDaysBefore:
        return 'reminder_four_days'.tr;
      case ReminderMode.oneWeekBefore:
        return 'reminder_one_week'.tr;
      case ReminderMode.twoWeeksBefore:
        return 'reminder_two_weeks'.tr;
      case ReminderMode.custom:
        return '';
    }
  }

  Duration get offset {
    switch (this) {
      case ReminderMode.none:
        return Duration.zero;
      case ReminderMode.oneDayBefore:
        return const Duration(days: 1);
      case ReminderMode.twoDaysBefore:
        return const Duration(days: 2);
      case ReminderMode.threeDaysBefore:
        return const Duration(days: 3);
      case ReminderMode.fourDaysBefore:
        return const Duration(days: 4);
      case ReminderMode.oneWeekBefore:
        return const Duration(days: 7);
      case ReminderMode.twoWeeksBefore:
        return const Duration(days: 14);
      case ReminderMode.custom:
        return Duration.zero; // Handled elsewhere
    }
  }
}

ReminderMode reminderModeFromOffset(Duration duration) {
  switch (duration.inDays) {
    case 0:
      return ReminderMode.none;
    case 1:
      return ReminderMode.oneDayBefore;
    case 2:
      return ReminderMode.twoDaysBefore;
    case 3:
      return ReminderMode.threeDaysBefore;
    case 4:
      return ReminderMode.fourDaysBefore;
    case 14:
      return ReminderMode.oneWeekBefore;
    case 28:
      return ReminderMode.twoWeeksBefore;
    default:
      return ReminderMode.custom;
  }
}
