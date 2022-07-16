import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/pages/class_tests/class_test_topic_editor.dart';
import 'package:school_app/pages/tasks/create_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class CreateClassTestPage extends StatefulWidget {
  const CreateClassTestPage({
    Key? key,
    this.classTestToEdit,
  }) : super(key: key);

  final ClassTest? classTestToEdit;

  @override
  State<CreateClassTestPage> createState() => _CreateClassTestPageState();
}

class _CreateClassTestPageState extends State<CreateClassTestPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final typeController = TextEditingController();
  final typeKey = GlobalKey<_ClassTestTypeFieldState>();

  bool enabled = true;

  late DateTime dueDate = DateTime.now();
  late Subject? subject;
  late List<ClassTestTopic> topics = [ClassTestTopic(topic: '', resources: '')];

  late ReminderMode reminderMode = ReminderMode.none;
  late Duration reminderOffset = Duration.zero;

  bool get isEditMode => widget.classTestToEdit != null;

  @override
  void initState() {
    super.initState();

    dueDate = widget.classTestToEdit?.dueDate ?? DateTime.now().date;
    subject = widget.classTestToEdit?.subject;
    topics = widget.classTestToEdit?.topics ??
        [ClassTestTopic(topic: '', resources: '')];
    reminderOffset =
        isEditMode ? widget.classTestToEdit!.reminderOffset() : Duration.zero;
    reminderMode =
        isEditMode ? reminderModeFromOffset(reminderOffset) : ReminderMode.none;

    if (isEditMode) {
      typeController.text = widget.classTestToEdit!.type;
    }
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
    if (typeController.text.trim().isEmpty) {
      isValid = false;
      if (typeKey.currentState != null) {
        typeKey.currentState!.errorText = 'Please provide a type!';
      }
    } else {
      if (typeKey.currentState != null) {
        typeKey.currentState!.errorText = null;
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide topics!')));
      isValid = false;
    }

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    if (!isEditMode) {
      Database.I.createClassTest(
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!.id,
        validTopics,
        typeController.text.trim(),
      );
    } else {
      Database.I.editClassTest(
          widget.classTestToEdit!.id,
          dueDate,
          dueDate.subtract(reminderOffset),
          subject!.id,
          validTopics,
          typeController.text.trim());
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(!isEditMode ? 'Create Class Test' : 'Edit Class Test'),
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
                  _ClassTestTypeField(
                    key: typeKey,
                    controller: typeController,
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

class _ClassTestTypeField extends StatefulWidget {
  const _ClassTestTypeField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final TextEditingController controller;

  @override
  State<_ClassTestTypeField> createState() => _ClassTestTypeFieldState();
}

class _ClassTestTypeFieldState extends State<_ClassTestTypeField>
    with AfterLayoutMixin {
  static final List<String> typeSuggestions = [
    'Class Test',
    'Vocabulary Test',
  ];

  final suggestionsController = SuggestionsBoxController();

  String? errorText;

  // There seems to be a bug in the flutter_typeahead library,
  // where [SuggestionBoxController.isOpened()] errors because some member
  // variable has not been initialized yet. Calling it after the first
  // layout fixes it.
  bool isFirstLayout = true;

  final typeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    typeFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    typeFocusNode.dispose();
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) =>
      setState(() => isFirstLayout = false);

  @override
  Widget build(BuildContext context) {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        decoration: InputDecoration(
          errorText: errorText,
          alignLabelWithHint: true,
          labelText: 'Type',
          suffixIcon: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.controller.text.isNotEmpty
                  ? IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => widget.controller.text = ''),
                    )
                  : const SizedBox(),
              IconButton(
                icon: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isFirstLayout
                      ? 0
                      : suggestionsController.isOpened()
                          ? 0.504
                          : 0,
                  child: const Icon(Icons.arrow_drop_down),
                ),
                onPressed: () => setState(() => suggestionsController.toggle()),
              ),
            ],
          ),
        ),
        onChanged: (_) => setState(() => errorText = null),
        controller: widget.controller,
        focusNode: typeFocusNode,
      ),
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) return typeSuggestions;

        // Fuzzy(?) insertion search
        // Checks that all characters from the pattern are in
        // the string in the order they appear in the pattern
        List<String> result = [];

        for (final suggestion in typeSuggestions) {
          int patternIndex = 0;
          for (final char in suggestion.toLowerCase().characters) {
            if (char != pattern[patternIndex]) continue;
            patternIndex++;
            if (patternIndex >= pattern.length) break;
          }

          if (patternIndex >= pattern.length) {
            result.add(suggestion);
          }
        }

        return result;
      },
      suggestionsBoxController: suggestionsController,
      hideOnEmpty: true,
      hideOnError: true,
      itemBuilder: (context, suggestion) => ListTile(
        title: Text(suggestion! as String),
      ),
      onSuggestionSelected: (suggestion) => setState(() {
        widget.controller.text = suggestion as String? ?? '';
        errorText = null;
      }),
    );
  }
}
