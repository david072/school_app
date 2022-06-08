import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/tasks/clickable_row.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/util.dart';

class ViewTaskPage extends StatefulWidget {
  const ViewTaskPage({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  final String taskId;

  @override
  State<ViewTaskPage> createState() => _ViewTaskPageState();
}

class _ViewTaskPageState extends State<ViewTaskPage> {
  late StreamSubscription<Task> subscription;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  Task? task;
  String reminderString = "";
  bool completed = false;

  @override
  void initState() {
    super.initState();
    subscription = Database.I.queryTask(widget.taskId).listen((t) {
      task = t;
      titleController.text = task!.title;
      descriptionController.text = task!.description;
      completed = task!.completed;

      var reminderMode = reminderModeFromOffset(task!.reminderOffset());
      if (reminderMode == ReminderMode.custom) {
        reminderString = formatDate(task!.reminder);
      } else {
        reminderString = reminderMode.string;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return task != null
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Aufgabe'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateTaskPage(taskToEdit: task))),
                ),
                IconButton(
                  onPressed: () => showConfirmationDialog(
                      context: context,
                      title: 'Löschen',
                      content:
                          'Möchtest du die Aufgabe \'${task!.title}\' wirklich löschen?',
                      cancelText: 'Abbrechen',
                      confirmText: 'Löschen',
                      onConfirm: () {
                        Database.I.deleteTask(task!.id);
                        Navigator.pop(context);
                      }),
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                setState(() => completed = !completed);
                Database.I.updateTaskStatus(task!.id, completed);
              },
              label: Text(!completed ? 'Abschließen' : 'Wieder öffnen'),
              icon: Icon(!completed ? Icons.done : Icons.close),
            ),
            body: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: titleController,
                        enabled: false,
                        decoration: buildInputDecoration('Titel'),
                        validator: InputValidator.validateNotEmpty,
                      ),
                      const SizedBox(height: 40),
                      ClickableRow(
                        left: const Text('Fälligkeitsdatum:'),
                        right: Text(
                          '${formatDate(task!.dueDate)} (${task!.formatRelativeDueDate()})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: const Text('Erinnerung:'),
                        right: Text(
                          reminderString,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: const Text('Fach:'),
                        right: Text(
                          task!.subject.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: descriptionController,
                        enabled: false,
                        decoration: const InputDecoration(
                          alignLabelWithHint: true,
                          labelText: 'Beschreibung',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}
