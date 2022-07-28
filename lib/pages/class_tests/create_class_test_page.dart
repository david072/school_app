import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/pages/class_tests/class_test_topic_editor.dart';
import 'package:school_app/pages/tasks/completing_text_field.dart';
import 'package:school_app/pages/tasks/create_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class CreateClassTestPage extends StatefulWidget {
  const CreateClassTestPage({
    Key? key,
    this.initialData,
    this.editMode = false,
    this.initialSubject,
  }) : super(key: key);

  final ClassTest? initialData;
  final bool editMode;
  final Subject? initialSubject;

  @override
  State<CreateClassTestPage> createState() => _CreateClassTestPageState();
}

class _CreateClassTestPageState extends State<CreateClassTestPage> {
  static final List<String> typeSuggestions = [
    'class_test'.tr,
    'vocab_test'.tr,
  ];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final typeController = TextEditingController();

  bool enabled = true;

  late DateTime dueDate = DateTime.now();
  late Subject? subject;
  late List<ClassTestTopic> topics = [ClassTestTopic(topic: '', resources: '')];

  late ReminderMode reminderMode = ReminderMode.none;
  late Duration reminderOffset = Duration.zero;

  bool get isEditMode => widget.editMode;

  @override
  void initState() {
    super.initState();

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

    topics = widget.initialData?.topics ??
        [ClassTestTopic(topic: '', resources: '')];
    reminderOffset =
        isEditMode ? widget.initialData!.reminderOffset() : Duration.zero;
    reminderMode =
        isEditMode ? reminderModeFromOffset(reminderOffset) : ReminderMode.none;

    typeController.text = widget.initialData!.type;
  }

  Future<void> createClassTest() async {
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

    // Trim strings and remove empty ones
    var validTopics = topics
        .map((topic) => ClassTestTopic(
              topic: topic.topic.trim(),
              resources: topic.resources.trim(),
            ))
        .where((topic) => topic.topic.isNotEmpty && topic.resources.isNotEmpty)
        .toList();
    if (validTopics.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('missing_topics_error'.tr)));
      isValid = false;
    }

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    if (!isEditMode) {
      Database.I.createClassTest(ClassTest(
        '',
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!,
        validTopics,
        typeController.text.trim(),
      ));
    } else {
      Database.I.editClassTest(ClassTest(
        widget.initialData!.id,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!,
        validTopics,
        typeController.text.trim(),
      ));
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          !isEditMode
              ? 'create_class_test_title'.tr
              : 'edit_class_test_title'.tr,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: formWidth(context),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CompletingTextFormField(
                    controller: typeController,
                    suggestionsCallback: () => typeSuggestions,
                    labelText: 'type'.tr,
                    itemBuilder: (_, s) => ListTile(title: Text(s)),
                    validator: InputValidator.validateNotEmpty,
                  ),
                  const SizedBox(height: 40),
                  DatePicker(
                    enabled: enabled,
                    prefix: 'due_date'.tr,
                    onChanged: (date) => setState(() => dueDate = date),
                    date: dueDate,
                  ),
                  const SizedBox(height: 20),
                  ReminderPicker(
                    enabled: enabled,
                    mode: reminderMode,
                    reminderOffset: reminderOffset,
                    dueDate: dueDate,
                    onChanged: (offset, mode) => setState(() {
                      reminderMode = mode;
                      reminderOffset = offset;
                    }),
                  ),
                  const SizedBox(height: 20),
                  SubjectPicker(
                    enabled: enabled,
                    selectedSubjectId: subject?.id,
                    onChanged: (s) => setState(() => subject = s),
                  ),
                  const SizedBox(height: 40),
                  ClassTestTopicEditor(topics: topics),
                  const SizedBox(height: 40),
                  MaterialButton(
                    onPressed: enabled ? createClassTest : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text(!isEditMode ? 'create_caps'.tr : 'save_caps'.tr)
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
