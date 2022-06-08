import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/data/task.dart';

import 'subject.dart';

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

  static Stream<Subject> querySubject(String id) async* {
    var doc = _collection(_subjectsCollection).doc(id).snapshots();
    await for (final subject in doc) {
      yield Subject.fromDocument(subject);
    }
  }

  static Future<Subject> querySubjectOnce(String id) async {
    var doc = await _collection(_subjectsCollection).doc(id).get();
    return Subject.fromDocument(doc);
  }

  static void createSubject(String name, String abbreviation, Color color) {
    _collection(_subjectsCollection).add({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  static void editSubject(
      String id, String name, String abbreviation, Color color) {
    var doc = _collection(_subjectsCollection).doc(id);
    doc.update({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  /// Also deletes tasks associated with this subject
  static Future<void> deleteSubject(String id) async {
    // Delete tasks associated with this subject id
    var tasks = await _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .where('subject_id', isEqualTo: id)
        .get();
    // Run deletions in parallel (prob not significant but doesn't hurt)
    for (final task in tasks.docs) {
      task.reference.delete();
    }
    // await Future.wait(futures);

    _delete(_subjectsCollection, id);
  }

  static Query<Map<String, dynamic>> _tasksQuery({DateTime? maxDueDate}) {
    var query = _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUser().uid);
    if (maxDueDate != null) {
      query = query.where('due_date',
          isLessThan: maxDueDate.millisecondsSinceEpoch);
    }
    return query.orderBy('due_date');
  }

  static Stream<List<Task>> queryTasks({DateTime? maxDueDate}) async* {
    var query = _tasksQuery(maxDueDate: maxDueDate).snapshots();

    await for (final docs in query) {
      var tasks = await Future.wait(docs.docs.map(Task.fromDocument));

      List<Task> result = [];
      // Sort tasks, so that completed tasks are always at the bottom
      for (int i = tasks.length - 1; i >= 0; i--) {
        final task = tasks[i];
        if (task.completed) {
          result.add(task);
        } else {
          result.insert(0, task);
        }
      }
      yield result;
    }
  }

  static Future<List<Task>> queryTasksOnce({DateTime? maxDueDate}) async {
    var tasks = await _tasksQuery(maxDueDate: maxDueDate).get();
    return await Future.wait(tasks.docs.map(Task.fromDocument));
  }

  static Stream<Task> queryTask(String taskId) async* {
    var query = _collection(_tasksCollection).doc(taskId).snapshots();
    await for (final task in query) {
      yield await Task.fromDocument(task);
    }
  }

  static void createTask(String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId) {
    _collection(_tasksCollection).add({
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'reminder': reminder.millisecondsSinceEpoch,
      'subject_id': subjectId,
      'completed': false,
      'user_id': _requireUser().uid,
    });
  }

  static void editTask(String id, String title, String description,
      DateTime dueDate, DateTime reminder, String subjectId) {
    var doc = _collection(_tasksCollection).doc(id);
    doc.update({
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'reminder': reminder.millisecondsSinceEpoch,
      'subject_id': subjectId,
      'user_id': _requireUser().uid,
    });
  }

  static void updateTaskStatus(String id, bool completed) {
    var doc = _collection(_tasksCollection).doc(id);
    doc.update({'completed': completed});
  }

  static void deleteTask(String id) => _delete(_tasksCollection, id);

  static CollectionReference<Map<String, dynamic>> _collection(
          String collection) =>
      FirebaseFirestore.instance.collection(collection);

  static void _delete(String collection, String id) {
    var doc = _collection(collection).doc(id);
    doc.delete();
  }

  static User _requireUser() {
    var user = FirebaseAuth.instance.currentUser;
    assert(user != null, 'User required for operation!');
    return user!;
  }
}
