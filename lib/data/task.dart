import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/model/relative_date_time.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/util.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime reminder;
  final Subject subject;
  final bool completed;

  const Task(
    this.id,
    this.title,
    this.description,
    this.dueDate,
    this.reminder,
    this.subject,
    this.completed,
  );

  static Future<Task> fromDocument(DocumentSnapshot<Map> doc) async {
    var data = doc.data()!;
    return Task(
      doc.id,
      data['title'],
      data['description'],
      DateTime.fromMillisecondsSinceEpoch(data['due_date']),
      DateTime.fromMillisecondsSinceEpoch(data['reminder']),
      await Database.I.querySubjectOnce(data['subject_id']),
      data['completed'],
    );
  }

  String formatRelativeDueDate() {
    var rdt = RelativeDateTime(dateTime: DateTime.now().date, other: dueDate);
    return const RelativeDateFormat(Locale('de')).format(rdt);
  }

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
        return 'Keine';
      case ReminderMode.oneDayBefore:
        return 'Einen Tag vorher';
      case ReminderMode.twoDaysBefore:
        return 'Zwei Tage vorher';
      case ReminderMode.threeDaysBefore:
        return 'Drei Tage vorher';
      case ReminderMode.fourDaysBefore:
        return 'Vier Tage vorher';
      case ReminderMode.oneWeekBefore:
        return 'Eine Woche vorher';
      case ReminderMode.twoWeeksBefore:
        return 'Zwei Wochen vorher';
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
