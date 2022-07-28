import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/util/util.dart';

class Task extends AbstractTask {
  static const sharingType = 0;

  @override
  final String id;
  final String title;
  final String description;
  @override
  final DateTime dueDate;
  @override
  final DateTime reminder;
  @override
  final Subject subject;
  final bool completed;

  @override
  final DateTime? deletedAt;

  const Task(this.id,
      this.title,
      this.description,
      this.dueDate,
      this.reminder,
      this.subject,
      this.completed, [
        this.deletedAt,
      ]);

  static Future<Task> fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.id, doc.data()!);
  }

  static Future<Task> fromRow(Map<String, dynamic> row, {String? subjectId}) {
    return _fromMap(row['id'].toString(), row, subjectId: subjectId);
  }

  static Future<Task> _fromMap(String id, Map<String, dynamic> map,
      {String? subjectId}) async {
    bool completed;
    var value = map['completed'];
    if (value is bool) {
      completed = value;
    } else {
      completed = (value as int) == 1;
    }

    var dateTime = DateTime.fromMillisecondsSinceEpoch;

    return Task(
      id,
      map['title'],
      map['description'],
      dateTime(map['due_date']),
      dateTime(map['reminder']),
      subjectId == null
          ? await Database.I.querySubjectOnce(map['subject_id'].toString())
          : Subject(subjectId, '', '', Colors.black, 0, 0),
      completed,
      map.containsKey('deleted_at') ? dateTime(map['deleted_at']) : null,
    );
  }

  @override
  String deleteDialogContent() =>
      (deletedAt != null
          ? 'delete_task_permanently_confirm'
          : 'delete_task_confirm')
          .trParams({'name': title});

  @override
  DataCell getCompletedCell() => DataCell(
    Builder(
      builder: (_) {
        // (HACK) to make the UI element update instantly
        var value = completed;
        return StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              onChanged: deletedAt != null
                  ? null
                  : (b) {
                if (b == null) return;
                setState(() => value = b);
                Database.I.updateTaskStatus(id, b);
              },
              value: value,
            ),
          ),
        );
      },
    ),
  );

  @override
  DataCell getTitleCell(BuildContext context) => DataCell(
    RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          WidgetSpan(
              child: description.isNotEmpty
                  ? const SizedBox(width: 10)
                  : Container()),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: description.isNotEmpty
                ? IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: Icon(Icons.sticky_note_2_outlined,
                  color: Theme.of(context).hintColor),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('description'.tr),
                  content: Text(description),
                ),
              ),
            )
                : Container(),
          )
        ],
      ),
    ),
  );

  @override
  Color? tableRowBackgroundColor() {
    if (!completed) return null;
    if (!Get.isDarkMode) {
      return Colors.grey.shade300;
    } else {
      return Colors.grey.shade800;
    }
  }

  @override
  String notificationTitle() => 'task_notification_title'.trParams({
    'title': title,
    'subjectAbb': subject.abbreviation,
  });

  @override
  String notificationContent() => 'task_notification_content'.trParams({
    'title': title,
    'subjectName': subject.name,
    'relDueDate': formatRelativeDueDate(),
  });

  @override
  bool needsReminder() {
    final now = DateTime.now().date;
    return !completed &&
        (reminder.isBefore(now) || reminder.isAtSameMomentAs(now));
  }

  @override
  void delete() {
    if (deletedAt == null) {
      Database.I.deleteTask(id);
    } else {
      Database.I.permanentlyDeleteTask(id);
    }
  }

  @override
  Map<String, dynamic> data() => {
        'title': title,
        'description': description,
        'due_date': dueDate.millisecondsSinceEpoch,
        'reminder': reminder.millisecondsSinceEpoch,
        'subject_id': subject.id,
        'completed': completed ? 1 : 0,
      };

  @override
  Map<String, dynamic> sharingData() => {
        'type': sharingType,
        'title': title,
        'due_date': dueDate.millisecondsSinceEpoch,
        'reminder': reminder.millisecondsSinceEpoch,
        'description': description,
        'subject': subject.data()..remove('notes'),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
}