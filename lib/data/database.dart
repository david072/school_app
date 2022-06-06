import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/data/tasks/task.dart';

import './subjects/subject.dart';

class Database {
  static const _subjectsCollection = 'subjects';
  static const _tasksCollection = 'tasks';

  static Stream<List<Subject>> querySubjects() async* {
    // TODO: Query / store task count
    var subjects = _collection(_subjectsCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .snapshots();

    await for (final docs in subjects) {
      yield docs.docs.map(Subject.fromDocument).toList();
    }
  }

  static Future<Subject> querySubject(String id) async {
    var doc = await _collection(_subjectsCollection).doc(id).get();
    return Subject.fromDocument(doc);
  }

  static Future<void> createSubject(
      String name, String abbreviation, Color color) async {
    await _collection(_subjectsCollection).add({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  static Future<void> editSubject(String id, String name, String abbreviation,
      Color color) async {
    var doc = _collection(_subjectsCollection).doc(id);
    await doc.update({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  static Future<void> deleteSubject(String id) async =>
      await _delete(_subjectsCollection, id);

  static Stream<List<Task>> queryTasks() async* {
    var tasks = _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .snapshots();

    await for (final docs in tasks) {
      yield await Future.wait(docs.docs.map((doc) => Task.fromDocument(doc)));
    }
  }

  static Future<void> createTask(String title, String description,
      DateTime dueDate, DateTime reminder, String subjectId) async {
    await _collection(_tasksCollection).add({
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'reminder': reminder.millisecondsSinceEpoch,
      'subject_id': subjectId,
      'user_id': _requireUser().uid,
    });
  }

  static Future<void> editTask(String id, String title, String description,
      DateTime dueDate, DateTime reminder, String subjectId) async {
    var doc = _collection(_tasksCollection).doc(id);
    await doc.update({
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'reminder': reminder.millisecondsSinceEpoch,
      'subject_id': subjectId,
      'user_id': _requireUser().uid,
    });
  }

  static Future<void> deleteTask(String id) async =>
      await _delete(_tasksCollection, id);

  static CollectionReference<Map<String, dynamic>> _collection(
      String collection) =>
      FirebaseFirestore.instance.collection(collection);

  static Future<void> _delete(String collection, String id) async {
    var doc = _collection(collection).doc(id);
    await doc.delete();
  }

  static User _requireUser() {
    var user = FirebaseAuth.instance.currentUser;
    assert(user != null, 'User required for operation!');
    return user!;
  }
}
