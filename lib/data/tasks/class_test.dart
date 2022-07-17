import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/util/util.dart';

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
  final String type;

  @override
  final DateTime? deletedAt;

  const ClassTest(
    this.id,
    this.dueDate,
    this.reminder,
    this.subject,
    this.topics,
    this.type, [
    this.deletedAt,
  ]);

  static Future<ClassTest> fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.id, doc.data()!);
  }

  static Future<ClassTest> fromRow(Map<String, dynamic> row,
      {String? subjectId}) {
    return _fromMap(row['id'].toString(), row, subjectId: subjectId);
  }

  static Future<ClassTest> _fromMap(String id, Map<String, dynamic> map,
      {String? subjectId}) async {
    var dateTime = DateTime.fromMillisecondsSinceEpoch;

    return ClassTest(
      id,
      dateTime(map['due_date']),
      dateTime(map['reminder']),
      subjectId == null
          ? await Database.I.querySubjectOnce(map['subject_id'].toString())
          : Subject(subjectId, '', '', Colors.black, 0, 0),
      decodeTopicsList(map['topics']),
      map['type'],
      map.containsKey('deleted_at') ? dateTime(map['deleted_at']) : null,
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
  String deleteDialogContent() =>
      (deletedAt != null
          ? 'delete_class_test_permanently_confirm'
          : 'delete_class_test_confirm')
      .tr;

  @override
  String notificationTitle() => 'class_test_notification_title'.trParams({
        'type': type,
        'subjectAbb': subject.abbreviation,
      });

  @override
  String notificationContent() => 'class_test_notification_content'.trParams({
        'type': type,
        'subjectName': subject.name,
      });

  @override
  bool needsReminder() {
    final now = DateTime.now().date;
    return reminder.isBefore(now) || reminder.isAtSameMomentAs(now);
  }

  @override
  void delete() {
    if (deletedAt == null) {
      Database.I.deleteClassTest(id);
    } else {
      Database.I.permanentlyDeleteClassTest(id);
    }
  }

  @override
  DataCell getCompletedCell() => const DataCell(Icon(Icons.description));

  @override
  DataCell getTitleCell(BuildContext context) => DataCell(Text(
        type,
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

  @override
  Map<String, dynamic> data() => {
        'type': type,
        'due_date': dueDate.millisecondsSinceEpoch,
        'reminder': reminder.millisecondsSinceEpoch,
        'subject_id': subject.id,
        'topics': ClassTest.encodeTopicsList(topics),
      };
}

// "<topic>:<res>|<topic>:<res>|<topic>:<res>|<topic>:<res>|<topic>:<res>"