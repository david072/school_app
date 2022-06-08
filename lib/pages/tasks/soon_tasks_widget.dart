import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/home/footer.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/pages/tasks/view_task_page.dart';
import 'package:school_app/util.dart';

class TaskListWidget extends StatefulWidget {
  const TaskListWidget({
    Key? key,
    this.maxDateTime,
    this.subjectFilter,
  }) : super(key: key);

  final DateTime? maxDateTime;
  final Subject? subjectFilter;

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  List<Task> tasks = [];
  late StreamSubscription subscription;

  late Offset longPressPosition;

  @override
  void initState() {
    super.initState();
    subscription = Database.queryTasks(
      maxDueDate: widget.maxDateTime,
    ).listen((data) => setState(() {
          tasks = data.where((task) {
            if (widget.subjectFilter == null) return true;
            return task.subject.id == widget.subjectFilter!.id;
          }).toList();
        }));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: GestureDetector(
                onTapDown: (details) =>
                    longPressPosition = details.globalPosition,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Fertig')),
                    DataColumn(label: Text('Fälligkeitsdatum')),
                    DataColumn(label: Text('Titel')),
                    DataColumn(label: Text('Fach')),
                  ],
                  rows: tasks
                      .map(
                        (task) => _taskRow(
                          context,
                          task,
                          () => showPopupMenu(
                            context: context,
                            items: const [
                              PopupMenuItem(
                                value: 0,
                                child: Text('Bearbeiten'),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: Text('Löschen'),
                              ),
                            ],
                            longPressPosition: longPressPosition,
                            functions: [
                              () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CreateTaskPage(taskToEdit: task),
                                    ),
                                  ),
                              () => showConfirmationDialog(
                                    context: context,
                                    title: 'Löschen',
                                    content:
                                        'Möchtest du die Aufgabe \'${task.title}\' wirklich löschen?',
                                    cancelText: 'Abbrechen',
                                    confirmText: 'Löschen',
                                    onConfirm: () =>
                                        Database.deleteTask(task.id),
                                  ),
                            ],
                          ),
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ViewTaskPage(taskId: task.id))),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          Footer(
            reverse: true,
            displayName: 'Aufgaben',
            count: tasks.length,
            onAdd: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        CreateTaskPage(initialSubject: widget.subjectFilter))),
          ),
        ],
      ),
    );
  }
}

DataRow _taskRow(BuildContext context, Task task, void Function() onLongPress,
    void Function() onSelectChanged) {
  return DataRow(
    color: MaterialStateProperty.resolveWith((states) {
      if (task.completed) return Colors.grey.shade300;
      return null;
    }),
    cells: [
      DataCell(
        Builder(
          builder: (_) {
            // (HACK) to make the UI element update instantly
            var value = task.completed;
            return StatefulBuilder(builder: (context, setState) {
              return SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  onChanged: (b) {
                    if (b == null) return;
                    setState(() => value = b);
                    Database.updateTaskStatus(task.id, b);
                  },
                  value: value,
                ),
              );
            });
          },
        ),
      ),
      DataCell(Text(task.formatRelativeDueDate(),
          style: Theme.of(context).textTheme.bodyLarge)),
      DataCell(Text(task.title, style: Theme.of(context).textTheme.bodyLarge)),
      DataCell(
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.book_outlined, color: task.subject.color),
              ),
              const WidgetSpan(child: SizedBox(width: 10)),
              TextSpan(
                text: task.subject.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: task.subject.color,
                    ),
              ),
            ],
          ),
        ),
      ),
    ],
    onLongPress: onLongPress,
    onSelectChanged: (_) => onSelectChanged(),
  );
}
