import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';

class Task extends AbstractTask {
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

  @override
  String deleteDialogContent() => (deletedAt != null
          ? 'delete_task_permanently_confirm'
          : 'delete_task_confirm')
      .trParams({'name': title});

  @override
  DataCell getCompletedCell(TasksListMode mode) => DataCell(
        Builder(
          builder: (_) {
            // (HACK) to make the UI element update instantly
            var value = completed;
            return StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  onChanged: mode != TasksListMode.normal
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
  void delete() {
    if (deletedAt == null) {
      Database.I.deleteTask(id);
    } else {
      Database.I.permanentlyDeleteTask(id);
    }
  }
}
