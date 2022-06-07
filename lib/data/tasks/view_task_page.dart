import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/data/tasks/create_task_page.dart';

import '../../util.dart';
import '../database.dart';
import 'task.dart';

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

  @override
  void initState() {
    super.initState();
    subscription = Database.queryTask(widget.taskId).listen((t) {
      task = t;
      titleController.text = task!.title;
      descriptionController.text = task!.description;

      var reminderMode = reminderModeFromOffset(task!.reminderOffset());
      if (reminderMode == ReminderMode.custom) {
        reminderString = DateFormat('dd.MM.yyyy').format(task!.reminder);
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
                  onPressed: () =>
                      Get.to(() => CreateTaskPage(taskToEdit: task)),
                ),
                IconButton(
                  onPressed: () => showConfirmationDialog(
                      context: context,
                      title: 'Löschen',
                      content:
                          'Möchtest du die Aufgabe \'${task!.title}\' wirklich löschen?',
                      cancelText: 'Abbrechen',
                      confirmText: 'Löschen',
                      onConfirm: () async {
                        await Database.deleteTask(task!.id);
                        Get.back();
                      }),
                  icon: const Icon(Icons.delete),
                ),
              ],
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
                      _Row(
                        left: const Text('Fälligkeitsdatum:'),
                        right: Text(
                          '${DateFormat('dd.MM.yyyy').format(task!.dueDate)} (${task!.formatDueDate()})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Row(
                        left: const Text('Erinnerung:'),
                        right: Text(
                          reminderString,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Row(
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

class _Row extends StatelessWidget {
  const _Row({
    Key? key,
    required this.left,
    required this.right,
  }) : super(key: key);

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          left,
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: right,
            ),
          )
        ],
      ),
    );
  }
}
