import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lit_relative_date_time/controller/relative_date_format.dart';
import 'package:lit_relative_date_time/model/relative_date_time.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/data/subjects/subject.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime reminder;
  final Subject subject;

  const Task(
    this.id,
    this.title,
    this.description,
    this.dueDate,
    this.reminder,
    this.subject,
  );

  static Future<Task> fromDocument(QueryDocumentSnapshot<Map> doc) async {
    var data = doc.data();
    return Task(
      doc.id,
      data['title'],
      data['description'],
      DateTime.fromMillisecondsSinceEpoch(data['due_date']),
      DateTime.fromMillisecondsSinceEpoch(data['reminder']),
      await Database.querySubject(data['subject_id']),
    );
  }

  String formatDueDate() {
    var now = DateTime.now();
    var rdt = RelativeDateTime(
        dateTime: DateTime(now.year, now.month, now.day), other: dueDate);
    return const RelativeDateFormat(Locale('de')).format(rdt);
  }
}
