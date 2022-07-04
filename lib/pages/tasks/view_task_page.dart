import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
                      title:
                          (!isTaskDeleted ? 'delete' : 'delete_permanently').tr,
                      content: (!isTaskDeleted
                              ? 'delete_task_confirm'
                              : 'delete_task_permanently_confirm')
                          .trParams({'name': task!.title}),
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
            floatingActionButton: !isTaskDeleted
                ? FloatingActionButton.extended(
                    onPressed: () {
                      setState(() => completed = !completed);
                      Database.I.updateTaskStatus(task!.id, completed);
                    },
                    label: Text(!completed
                        ? 'mark_task_completed'.tr
                        : 'mark_task_uncompleted'.tr),
                    icon: Icon(!completed ? Icons.done : Icons.close),
                  )
                : null,
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
