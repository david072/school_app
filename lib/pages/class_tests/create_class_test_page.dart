import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/class_test.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/tasks/create_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class CreateClassTestPage extends StatefulWidget {
  const CreateClassTestPage({Key? key}) : super(key: key);

  @override
  State<CreateClassTestPage> createState() => _CreateClassTestPageState();
}

class _CreateClassTestPageState extends State<CreateClassTestPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool enabled = true;

  DateTime dueDate = DateTime.now();
  Subject? subject;
  List<ClassTestTopic> topics = [ClassTestTopic(topic: '', resources: '')];

  ReminderMode reminderMode = ReminderMode.none;
  Duration reminderOffset = Duration.zero;

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

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    print(topics);
    print("TODO: create class test");

    setState(() => enabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Class Test'),
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
                  _ClassTopicEditor(
                    topics: topics,
                    onChanged: (ts) => setState(() => topics = ts),
                  ),
                  const SizedBox(height: 40),
                  MaterialButton(
                    onPressed: enabled ? createClassTest : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text('create_caps'.tr)
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

class _ClassTopicEditor extends StatefulWidget {
  const _ClassTopicEditor({
    Key? key,
    required this.topics,
    required this.onChanged,
  }) : super(key: key);

  final List<ClassTestTopic> topics;
  final void Function(List<ClassTestTopic>) onChanged;

  @override
  State<_ClassTopicEditor> createState() => _ClassTopicEditorState();
}

class _ClassTopicEditorState extends State<_ClassTopicEditor> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () {
            setState(() =>
                widget.topics.add(ClassTestTopic(topic: "", resources: "")));
            listKey.currentState!.insertItem(widget.topics.length - 1,
                duration: const Duration(milliseconds: 100));
          },
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: 'Add', style: Theme.of(context).textTheme.bodyText1),
                const WidgetSpan(child: SizedBox(width: 5)),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.add,
                      color: Theme.of(context).textTheme.bodyText1!.color),
                ),
              ],
            ),
          ),
        ),
        AnimatedList(
          key: listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: widget.topics.length,
          itemBuilder: (context, i, animation) => FadeTransition(
            opacity: animation.drive(Tween(begin: 0, end: 1)),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final removedTopic = widget.topics.removeAt(i);
                                listKey.currentState!.removeItem(
                                  i,
                                  (context, animation) =>
                                      _animateOutCard(removedTopic, animation),
                                  duration: const Duration(milliseconds: 100),
                                );
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Flexible(
                          child: TextField(
                            controller: TextEditingController(
                                text: widget.topics[i].topic),
                            onChanged: (s) => widget.topics[i].topic = s,
                            maxLines: null,
                            decoration: buildInputDecoration("Topic"),
                          ),
                        ),
                        const VerticalDivider(),
                        Flexible(
                          child: TextField(
                            controller: TextEditingController(
                                text: widget.topics[i].resources),
                            onChanged: (s) => widget.topics[i].resources = s,
                            maxLines: null,
                            decoration: buildInputDecoration("Resources"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animateOutCard(ClassTestTopic topic, Animation animation) {
    return FadeTransition(
      opacity: animation.drive(Tween(begin: 0, end: 1)),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.delete),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: TextEditingController(text: topic.topic),
                      enabled: false,
                      maxLines: null,
                      decoration: buildInputDecoration("Topic"),
                    ),
                  ),
                  const VerticalDivider(),
                  Flexible(
                    child: TextField(
                      controller: TextEditingController(text: topic.resources),
                      enabled: false,
                      maxLines: null,
                      decoration: buildInputDecoration("Resources"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
