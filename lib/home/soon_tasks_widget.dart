import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/data/tasks/create_task_page.dart';

import '../data/tasks/task.dart';
import 'footer.dart';

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

  @override
  void initState() {
    super.initState();
    subscription =
        Database.queryTasks().listen((data) => setState(() => tasks = data));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> tableRows = [];
    for (int i = 0; i < tasks.length; i++) {
      tableRows.add(_taskRow(context, tasks[i]));
      if (i != tasks.length - 1) tableRows.add(_spacer());
    }

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Table(
              children: [
                TableRow(
                  children: [
                    Text('Fälligkeitsdatum',
                        style: Theme.of(context).textTheme.headline6),
                    Text('Titel', style: Theme.of(context).textTheme.headline6),
                    Text('Fach', style: Theme.of(context).textTheme.headline6),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Table(
                  children: tableRows,
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

TableRow _taskRow(BuildContext context, Task task) {
  return TableRow(
    children: [
      Text(task.formatDueDate(), style: Theme.of(context).textTheme.bodyLarge),
      Text(task.title, style: Theme.of(context).textTheme.bodyLarge),
      Align(
        alignment: Alignment.centerLeft,
        child: RichText(
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
  );
}

TableRow _spacer() {
  const double height = 20;
  return const TableRow(
    children: [
      SizedBox(height: height),
      SizedBox(height: height),
      SizedBox(height: height),
    ],
  );
}
