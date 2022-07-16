import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/pages/class_tests/class_test_topic_editor.dart';
import 'package:school_app/pages/class_tests/create_class_test_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

class ViewClassTestPage extends StatefulWidget {
  const ViewClassTestPage({
    Key? key,
    required this.testId,
    this.isClassTestDeleted = false,
  }) : super(key: key);

  final String testId;
  final bool isClassTestDeleted;

  @override
  State<ViewClassTestPage> createState() => _ViewClassTestPageState();
}

class _ViewClassTestPageState extends State<ViewClassTestPage> {
  late StreamSubscription<ClassTest> subscription;

  ClassTest? classTest;

  final typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isClassTestDeleted) {
      subscription = Database.I.queryClassTest(widget.testId).listen(listen);
    } else {
      subscription =
          Database.I.queryDeletedClassTest(widget.testId).listen(listen);
    }
  }

  void listen(ClassTest ct) {
    classTest = ct;
    typeController.text = ct.type;
    setState(() {});
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
              title: Text('class_test'.tr),
              actions: [
                !widget.isClassTestDeleted
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Get.to(() =>
                            CreateClassTestPage(classTestToEdit: classTest)),
                      )
                    : Container(),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => showConfirmationDialog(
                    context: context,
                    title: classTest!.deleteDialogTitle(),
                    content: classTest!.deleteDialogContent(),
                    confirmText: 'delete_caps'.tr,
                    cancelText: 'cancel_caps'.tr,
                    onConfirm: () {
                      classTest!.delete();
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
                      TextField(
                        enabled: false,
                        decoration: buildInputDecoration('type'.tr),
                        controller: typeController,
                      ),
                      const SizedBox(height: 40),
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
