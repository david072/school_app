import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/data/database/database.dart';

class Subject {
  final String id;
  final String name;
  final String abbreviation;
  final Color color;

  final int taskCount;
  final int completedTasksCount;

  final String notes;

  const Subject(
    this.id,
    this.name,
    this.abbreviation,
    this.color,
    this.taskCount,
    this.completedTasksCount, [
    this.notes = "",
  ]);

  Subject.data(
    this.name,
    this.abbreviation,
    this.color, [
    this.id = '',
    this.notes = '',
  ])  : taskCount = 0,
        completedTasksCount = 0;

  static Future<Subject> fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.id, doc.data()!);
  }

  static Future<Subject> fromRow(Map<String, dynamic> row) {
    return _fromMap(row['id'].toString(), row);
  }

  static Future<Subject> _fromMap(String id, Map<String, dynamic> map) async {
    var taskCounts = await Database.I.queryTaskCountForSubject(id);

    return Subject(
      id,
      map['name'],
      map['abbreviation'],
      Color(map['color']),
      taskCounts[0],
      taskCounts[1],
      map['notes'] ?? "",
    );
  }

  Map<String, dynamic> data() => {
        'name': name,
        'abbreviation': abbreviation,
        'color': color,
        'notes': notes,
      };
}