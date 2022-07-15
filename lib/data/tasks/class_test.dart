import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';

class ClassTestTopic {
  String topic;
  String resources;

  ClassTestTopic({required this.topic, required this.resources});

  @override
  String toString() {
    return "ClassTestTopic($topic, $resources)";
  }
}

class ClassTest extends AbstractTask {
  @override
  final String id;
  @override
  final DateTime dueDate;
  @override
  final DateTime reminder;
  @override
  final Subject subject;

  final List<ClassTestTopic> topics;

  @override
  final DateTime? deletedAt;

  const ClassTest(
    this.id,
    this.dueDate,
    this.reminder,
    this.subject,
    this.topics, [
    this.deletedAt,
  ]);

  static Future<ClassTest> fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc,
      {bool isDeleted = false}) {
    return _fromMap(doc.id, doc.data()!, isDeleted: isDeleted);
  }

  static Future<ClassTest> fromRow(Map<String, dynamic> row,
      {bool isDeleted = false}) {
    return _fromMap(
      row['id'].toString(),
      row,
      isDeleted: isDeleted,
    );
  }

  static Future<ClassTest> _fromMap(String id, Map<String, dynamic> map,
      {bool isDeleted = false}) async {
    var dateTime = DateTime.fromMillisecondsSinceEpoch;

    return ClassTest(
      id,
      dateTime(map['due_date']),
      dateTime(map['reminder']),
      await Database.I.querySubjectOnce(map['subject_id'].toString()),
      decodeTopicsList(map['topics']),
      !isDeleted ? null : dateTime(map['deleted_at']),
    );
  }

  String encodeTopics() => encodeTopicsList(topics);

  static String encodeTopicsList(List<ClassTestTopic> topics) {
    String result = "";
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      result += '${topic.topic}:${topic.resources}';
      if (i + 1 < topics.length) {
        result += '|';
      }
    }
    return result;
  }

  static List<ClassTestTopic> decodeTopicsList(String encoded) {
    List<ClassTestTopic> result = [];
    var classTestTopics = encoded.split('|');
    for (final topic in classTestTopics) {
      var parts = topic.split(':');
      result.add(ClassTestTopic(topic: parts[0], resources: parts[1]));
    }

    return result;
  }

  @override
  String deleteDialogContent() => 'delete_class_test_confirm'.tr;

  @override
  DataCell getCompletedCell(TasksListMode mode) =>
      const DataCell(Icon(Icons.description));

  @override
  DataCell getTitleCell(BuildContext context) => DataCell(Text(
        'TODO',
        style: Theme.of(context).textTheme.bodyLarge,
      ));

  @override
  Color? tableRowBackgroundColor() {
    if (!Get.isDarkMode) {
      return Colors.grey.shade200;
    } else {
      return Colors.grey.shade900;
    }
  }
}

// "<topic>:<res>|<topic>:<res>|<topic>:<res>|<topic>:<res>|<topic>:<res>"
