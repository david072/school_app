import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lit_relative_date_time/model/relative_date_time.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';
import 'package:school_app/util/util.dart';

abstract class AbstractTask {
  const AbstractTask();

  String get id;

  DateTime get dueDate;

  DateTime get reminder;

  Subject get subject;

  DateTime? get deletedAt;

  Color? tableRowBackgroundColor();

  DataCell getCompletedCell(TasksListMode mode);

  DataCell getTitleCell(BuildContext context);

  String deleteDialogTitle() =>
      (deletedAt == null ? 'delete' : 'delete_permanently').tr;

  String deleteDialogContent();

  String notificationTitle();

  String notificationContent();

  bool isOver() {
    final now = DateTime.now().date;
    return dueDate.isBefore(now) || dueDate.isAtSameMomentAs(now);
  }

  bool needsReminder();

  void delete();

  String formatRelativeDueDate() => formatRelativeDate(
        RelativeDateTime(dateTime: DateTime.now().date, other: dueDate),
      );

  String formatRelativeDeletedAtDate() {
    assert(deletedAt != null);
    return formatRelativeDate(
      RelativeDateTime(dateTime: deletedAt!, other: DateTime.now().date),
    );
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
