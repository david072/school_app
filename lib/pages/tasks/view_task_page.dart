import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class ViewTaskPage extends StatefulWidget {
  const ViewTaskPage({
    Key? key,
    required this.taskId,
    this.isTaskDeleted = false,
  }) : super(key: key);

  final String taskId;
  final bool isTaskDeleted;

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

  bool get isTaskDeleted => widget.isTaskDeleted;

  @override
  void initState() {
    super.initState();
    if (!isTaskDeleted) {
      subscription = Database.I.queryTask(widget.taskId).listen(listen);
    } else {
      subscription = Database.I.queryDeletedTask(widget.taskId).listen(listen);
    }
  }

  void listen(Task t) {
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
                  icon: const Icon(Icons.share),
                  onPressed: () => showDialog(
                      context: context,
                      builder: (context) => _ShareDialog(task: task!)),
                ),
                !isTaskDeleted
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            Get.to(() => CreateTaskPage(taskToEdit: task)),
                      )
                    : Container(),
                IconButton(
                  onPressed: () => showConfirmationDialog(
                      context: context,
                      title: task!.deleteDialogTitle(),
                      content: task!.deleteDialogContent(),
                      cancelText: 'cancel_caps'.tr,
                      confirmText: 'delete_caps'.tr,
                      onConfirm: () {
                        if (!isTaskDeleted) {
                          Database.I.deleteTask(task!.id);
                        } else {
                          Database.I.permanentlyDeleteTask(task!.id);
                        }
                        Get.back();
                      }),
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: !isTaskDeleted
                  ? () {
                      setState(() => completed = !completed);
                      Database.I.updateTaskStatus(task!.id, completed);
                    }
                  : null,
              label: Text(
                // When the task is deleted, show the completion status.
                // Otherwise, show what the button will do
                !completed
                    ? !isTaskDeleted
                        ? 'mark_task_completed'.tr
                        : 'not_completed'.tr
                    : !isTaskDeleted
                        ? 'mark_task_uncompleted'.tr
                        : 'completed'.tr,
              ),
              icon: Icon(
                // Same as above ^
                !completed
                    ? !isTaskDeleted
                        ? Icons.done
                        : Icons.close
                    : !isTaskDeleted
                        ? Icons.close
                        : Icons.done,
              ),
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
                        readOnly: true,
                        decoration: buildInputDecoration('title'.tr),
                        validator: InputValidator.validateNotEmpty,
                      ),
                      const SizedBox(height: 40),
                      ClickableRow(
                        left: Text('due_date_colon'.tr),
                        right: Text(
                          '${DateFormat('EEE').format(task!.dueDate)}, '
                          '${formatDate(task!.dueDate)} '
                          '(${task!.formatRelativeDueDate()})',
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
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: task!.subject.color),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: descriptionController,
                        enabled: descriptionController.text.isNotEmpty,
                        readOnly: true,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: 'description'.tr,
                          border: const OutlineInputBorder(),
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

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  final Task task;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  String? link;

  @override
  void initState() {
    Database.I
        .createTaskLink(widget.task)
        .then((l) => setState(() => link = l));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link'),
      content: link != null
          ? Text(link!)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: const [CircularProgressIndicator()],
            ),
      actions: link != null
          ? [
              TextButton(
                child: const Text('COPY'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: link));

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                    ),
                  );
                },
              ),
            ]
          : [],
    );
  }
}
