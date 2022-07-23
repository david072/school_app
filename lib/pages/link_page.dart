import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/pages/class_tests/create_class_test_page.dart';
import 'package:school_app/pages/subjects/create_subject_page.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';

class LinkPage extends StatefulWidget {
  const LinkPage({
    Key? key,
    required this.uri,
  }) : super(key: key);

  final Uri uri;

  @override
  State<LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<LinkPage> with AfterLayoutMixin {
  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    var json = await http.get(widget.uri);
    Map<String, dynamic> data = jsonDecode(json.body);

    // Verify known type
    var type = data['type'];
    if (type != Task.sharingType && type != ClassTest.sharingType) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unknown type'),
          content: const Text('The task\'s type is unknown.\n'
              'Please make sure your app is up to date.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Get.back();
      return;
    }

    // Get / Create subject if necessary
    var subject = await getSubject(data['subject']['name']);
    subject ??= await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Missing subject'),
        content: Text('The task\'s subject \'${data['subject']['name']}\' '
            'was not found in your subjects.\nWould you like to create it now, '
            'or select a different one?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(result: null);
            },
            child: Text('cancel_caps'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: Subject.empty()),
            child: const Text('SELECT DIFFERENT ONE'),
          ),
          TextButton(
            onPressed: () async {
              var initialData = Subject.data(
                data['subject']['name'],
                data['subject']['abbreviation'],
                Color(data['subject']['color']),
              );

              var createdSubject = await Get.to<Subject?>(
                  () => CreateSubjectPage(initialData: initialData));
              if (createdSubject != null) {
                Get.back(result: createdSubject);
              }
            },
            child: Text('create_caps'.tr),
          ),
        ],
      ),
    );

    if (subject == null) {
      Get.back();
      return;
    }

    var dateTime = DateTime.fromMillisecondsSinceEpoch;
    switch (data['type']) {
      case Task.sharingType:
        var initialData = Task(
          '',
          data['title'],
          data['description'],
          dateTime(data['due_date']),
          dateTime(data['reminder']),
          subject,
          false,
        );
        Get.off(() => CreateTaskPage(initialData: initialData));
        break;
      case ClassTest.sharingType:
        var initialData = ClassTest(
          '',
          dateTime(data['due_date']),
          dateTime(data['reminder']),
          subject,
          ClassTest.decodeTopicsList(data['topics']),
          data['test_type'],
        );
        Get.off(() => CreateClassTestPage(initialData: initialData));
        break;
    }
  }

  Future<Subject?> getSubject(String name) async {
    name = name.toLowerCase();
    var subjects = await Database.I.querySubjectsOnce();
    for (final subject in subjects) {
      if (subject.name.toLowerCase() == name) return subject;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link'),
        leadingWidth: 0,
        leading: const SizedBox(),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
