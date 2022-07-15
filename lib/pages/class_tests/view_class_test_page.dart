import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/data/class_test.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/pages/class_tests/class_test_topic_editor.dart';
import 'package:school_app/pages/class_tests/create_class_test_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class ViewClassTestPage extends StatefulWidget {
  const ViewClassTestPage({
    Key? key,
    required this.testId,
  }) : super(key: key);

  final String testId;

  @override
  State<ViewClassTestPage> createState() => _ViewClassTestPageState();
}

class _ViewClassTestPageState extends State<ViewClassTestPage> {
  late StreamSubscription<ClassTest> subscription;

  ClassTest? classTest;

  @override
  void initState() {
    super.initState();
    subscription = Database.I
        .queryClassTest(widget.testId)
        .listen((ct) => setState(() => classTest = ct));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return classTest != null
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Class Test'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Get.to(
                      () => CreateClassTestPage(classTestToEdit: classTest)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => showConfirmationDialog(
                    context: context,
                    title: 'delete'.tr,
                    content: 'delete_class_test_confirm'.tr,
                    confirmText: 'delete_caps'.tr,
                    cancelText: 'cancel_caps'.tr,
                    onConfirm: () {
                      Database.I.deleteClassTest(classTest!.id);
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
            body: Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: formWidth(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClickableRow(
                        left: Text('due_date_colon'.tr),
                        right: Text(
                          '${DateFormat('EEE').format(classTest!.dueDate)}, '
                          '${formatDate(classTest!.dueDate)} '
                          '(${classTest!.formatRelativeDueDate()})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: Text('reminder_colon'.tr),
                        right: Text(
                          formatDate(classTest!.reminder),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClickableRow(
                        left: Text('subject_colon'.tr),
                        right: Text(
                          classTest!.subject.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ClassTestTopicEditor(
                        editable: false,
                        topics: classTest!.topics,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        : const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
