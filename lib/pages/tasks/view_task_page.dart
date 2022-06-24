import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/tasks/clickable_row.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

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
              title: Text('task'.tr),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      Get.to(() => CreateTaskPage(taskToEdit: task)),
                ),
                IconButton(
                  onPressed: () => showConfirmationDialog(
                      context: context,
                      title: 'delete'.tr,
                      content:
                          'delete_task_confirm'.trParams({'name': task!.title}),
                      cancelText: 'cancel_caps'.tr,
                      confirmText: 'delete_caps'.tr,
                      onConfirm: () {
                        Database.I.deleteTask(task!.id);
                        Get.back();
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
              label: Text(!completed
                  ? 'mark_task_completed'.tr
                  : 'mark_task_uncompleted'.tr),
              icon: Icon(!completed ? Icons.done : Icons.close),
            ),
            body: Center(
              child: SizedBox(
                width: formWidth(context),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextFormField(
                        controller: titleController,
                        enabled: false,
                        decoration: buildInputDecoration('title'.tr),
                        validator: InputValidator.validateNotEmpty,
                      ),
                      const SizedBox(height: 40),
                      ClickableRow(
                        left: Text('due_date_colon'.tr),
                        right: Text(
                          '${formatDate(task!.dueDate)} (${task!.formatRelativeDueDate()})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: Text('reminder_colon'.tr),
                        right: Text(
                          reminderString,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: Text('subject_colon'.tr),
                        right: Text(
                          task!.subject.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: descriptionController,
                        enabled: false,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: 'description'.tr,
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
