import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/pages/tasks/create_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({
    Key? key,
    this.taskToEdit,
    this.initialSubject,
  }) : super(key: key);

  final Task? taskToEdit;
  final Subject? initialSubject;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true;

  late String title;
  late String description;
  late DateTime dueDate;
  late Subject? subject;

  late ReminderMode reminderMode;
  late Duration reminderOffset;

  @override
  void initState() {
    super.initState();

    title = widget.taskToEdit?.title ?? "";
    description = widget.taskToEdit?.description ?? "";
    dueDate = widget.taskToEdit?.dueDate ?? DateTime.now().date;
    subject = widget.taskToEdit?.subject ?? widget.initialSubject;
    reminderOffset = widget.taskToEdit != null
        ? widget.taskToEdit!.reminderOffset()
        : Duration.zero;
    reminderMode = widget.taskToEdit != null
        ? reminderModeFromOffset(reminderOffset)
        : ReminderMode.none;
  }

  void createTask() {
    setState(() => enabled = false);

    bool isValid = true;
    if (subject == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('select_subject_error'.tr)));
      isValid = false;
    }
    if (!validateForm(formKey)) {
      isValid = false;
    }

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    if (widget.taskToEdit == null) {
      Database.I.createTask(Task(
        '',
        title,
        description,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!,
        false,
      ));
    } else {
      Database.I.editTask(Task(
        widget.taskToEdit!.id,
        title,
        description,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!,
        widget.taskToEdit!.completed,
      ));
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null
            ? 'create_task_title'.tr
            : 'edit_task_title'.tr),
      ),
      body: Center(
        child: SizedBox(
          width: formWidth(context),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: widget.taskToEdit?.title,
                    enabled: enabled,
                    decoration: buildInputDecoration('title'.tr),
                    onChanged: (s) => title = s,
                    validator: InputValidator.validateNotEmpty,
                  ),
                  const SizedBox(height: 40),
                  DatePicker(
                    enabled: enabled,
                    prefix: 'due_date'.tr,
                    date: dueDate,
                    onChanged: (date) => setState(() => dueDate = date),
                  ),
                  const SizedBox(height: 20),
                  ReminderPicker(
                    enabled: enabled,
                    mode: reminderMode,
                    reminderOffset: reminderOffset,
                    dueDate: dueDate,
                    onChanged: (offset, mode) => setState(() {
                      reminderOffset = offset;
                      reminderMode = mode;
                    }),
                  ),
                  const SizedBox(height: 20),
                  SubjectPicker(
                    enabled: enabled,
                    onChanged: (s) => setState(() => subject = s),
                    selectedSubjectId: subject?.id,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    initialValue: widget.taskToEdit?.description,
                    enabled: enabled,
                    onChanged: (s) => description = s,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'description'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  const SizedBox(height: 80),
                  MaterialButton(
                    onPressed: enabled ? createTask : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text(widget.taskToEdit == null
                            ? 'create_caps'.tr
                            : 'save_caps'.tr)
                        : const CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}