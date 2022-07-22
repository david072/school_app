import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/pages/tasks/completing_text_field.dart';
import 'package:school_app/pages/tasks/create_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({
    Key? key,
    this.initialData,
    this.editMode = false,
    this.initialSubject,
  }) : super(key: key);

  final Task? initialData;
  final bool editMode;
  final Subject? initialSubject;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  static const titleSuggestionsKey = 'used-task-titles';

  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true;

  final titleController = TextEditingController();
  final titleKey = GlobalKey<CompletingTextFormFieldState>();

  late String description;
  late DateTime dueDate;
  late Subject? subject;

  late ReminderMode reminderMode;
  late Duration reminderOffset;

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      titleController.text = widget.initialData!.title;
    }

    description = widget.initialData?.description ?? "";
    dueDate = widget.initialData?.dueDate ?? DateTime.now().date;

    if (widget.initialData?.subject != null) {
      if (widget.initialData!.subject.id.isEmpty) {
        subject = widget.initialSubject;
      } else {
        subject = widget.initialData!.subject;
      }
    } else {
      subject = widget.initialSubject;
    }

    reminderOffset = widget.initialData != null
        ? widget.initialData!.reminderOffset()
        : Duration.zero;
    reminderMode = widget.initialData != null
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

    final title = titleController.text.trim();
    saveTitleSuggestion(title);

    if (!widget.editMode) {
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
        widget.initialData!.id,
        title,
        description,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!,
        widget.initialData!.completed,
      ));
    }

    Get.back(result: true);
  }

  void saveTitleSuggestion(String title) async {
    var sp = await SharedPreferences.getInstance();
    var list = sp.getStringList(titleSuggestionsKey) ?? [];
    list.addIf(!list.contains(title), title);
    sp.setStringList(titleSuggestionsKey, list);
  }

  Future<void> removeTitleSuggestion(String title) async {
    var sp = await SharedPreferences.getInstance();
    var list = sp.getStringList(titleSuggestionsKey) ?? [];
    list.remove(title);
    sp.setStringList(titleSuggestionsKey, list);
  }

  Future<List<String>> getTitleSuggestions() async {
    var sp = await SharedPreferences.getInstance();
    return sp.getStringList(titleSuggestionsKey) ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          !widget.editMode ? 'create_task_title'.tr : 'edit_task_title'.tr,
        ),
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
                  CompletingTextFormField(
                    key: titleKey,
                    controller: titleController,
                    suggestionsCallback: getTitleSuggestions,
                    labelText: 'title'.tr,
                    itemBuilder: (_, suggestion) => ListTile(
                      title: Text(suggestion),
                      trailing: IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await removeTitleSuggestion(suggestion);
                          titleKey.currentState?.updateSuggestions();
                        },
                      ),
                    ),
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
                    initialValue: widget.initialData?.description,
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
                        ? Text(!widget.editMode
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
