import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/home/footer.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/pages/tasks/view_task_page.dart';
import 'package:school_app/util.dart';

class SoonTasksWidget extends StatefulWidget {
  const SoonTasksWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<SoonTasksWidget> createState() => _SoonTasksWidgetState();
}

class _SoonTasksWidgetState extends State<SoonTasksWidget> {
  List<Task> tasks = [];
  late StreamSubscription subscription;

  late Offset longPressPosition;

  @override
  void initState() {
    super.initState();
    subscription = Database.queryTasks(
      maxDueDate: DateTime.now().date.add(const Duration(days: 7)),
    ).listen((data) => setState(() => tasks = data));
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
                              () => Get.to(
                                  () => CreateTaskPage(taskToEdit: task)),
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
                          () => Get.to(() => ViewTaskPage(taskId: task.id)),
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
            onAdd: () => Get.to(() => const CreateTaskPage()),
          ),
        ],
      ),
    );
  }
}

DataRow _taskRow(BuildContext context, Task task, void Function() onLongPress,
    void Function() onSelectChanged) {
  return DataRow(
    cells: [
      DataCell(Text(task.formatRelativeDueDate(),
          style: Theme.of(context).textTheme.bodyLarge)),
      DataCell(Text(task.title, style: Theme.of(context).textTheme.bodyLarge)),
      DataCell(RichText(
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
      )),
    ],
    onLongPress: onLongPress,
    onSelectChanged: (_) => onSelectChanged(),
  );
}
