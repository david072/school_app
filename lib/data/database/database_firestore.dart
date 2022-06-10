import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/notebook.dart';
import 'package:school_app/data/task.dart';

import '../subject.dart';

class DatabaseFirestore implements Database {
  static const _subjectsCollection = 'subjects';
  static const _tasksCollection = 'tasks';
  static const _notebooksCollection = 'notebooks';

  @override
  Stream<List<Subject>> querySubjects() async* {
    // TODO: Query / store task count
    var subjects = _collection(_subjectsCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .snapshots();

    await for (final docs in subjects) {
      yield docs.docs.map(Subject.fromDocument).toList();
    }
  }

  @override
  Stream<Subject> querySubject(String id) async* {
    var doc = _collection(_subjectsCollection).doc(id).snapshots();
    await for (final subject in doc) {
      yield Subject.fromDocument(subject);
    }
  }

  @override
  Future<Subject> querySubjectOnce(String id) async {
    var doc = await _collection(_subjectsCollection).doc(id).get();
    return Subject.fromDocument(doc);
  }

  @override
  String createSubject(String name, String abbreviation, Color color) {
    var newSubject = _collection(_subjectsCollection).doc();
    newSubject.set({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
    return newSubject.id;
  }

  @override
  void editSubject(String id, String name, String abbreviation, Color color) {
    var doc = _collection(_subjectsCollection).doc(id);
    doc.update({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  /// Also deletes tasks associated with this subject
  @override
  Future<void> deleteSubject(String id) async {
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

  Query<Map<String, dynamic>> _tasksQuery({DateTime? maxDueDate}) {
    var query = _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUser().uid);
    if (maxDueDate != null) {
      query = query.where('due_date',
          isLessThan: maxDueDate.millisecondsSinceEpoch);
    }
    return query.orderBy('due_date');
  }

  @override
  Stream<List<Task>> queryTasks({DateTime? maxDueDate}) async* {
    var query = _tasksQuery(maxDueDate: maxDueDate).snapshots();

    await for (final docs in query) {
      yield orderByCompleted(
          await Future.wait(docs.docs.map(Task.fromDocument)));
    }
  }

  @override
  Future<List<Task>> queryTasksOnce({DateTime? maxDueDate}) async {
    var tasks = await _tasksQuery(maxDueDate: maxDueDate).get();
    return await Future.wait(tasks.docs.map(Task.fromDocument));
  }

  @override
  Stream<Task> queryTask(String taskId) async* {
    var query = _collection(_tasksCollection).doc(taskId).snapshots();
    await for (final task in query) {
      yield await Task.fromDocument(task);
    }
  }

  @override
  void createTask(String title, String description, DateTime dueDate,
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

  @override
  void editTask(String id, String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId) {
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

  @override
  void updateTaskStatus(String id, bool completed) {
    var doc = _collection(_tasksCollection).doc(id);
    doc.update({'completed': completed});
  }

  @override
  void deleteTask(String id) => _delete(_tasksCollection, id);

  @override
  Stream<List<Notebook>> queryNotebooks(String subjectId) async* {
    var query = _collection(_notebooksCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .where('subject_id', isEqualTo: subjectId)
        .snapshots();
    await for (final subjects in query) {
      yield await Future.wait(subjects.docs.map(Notebook.fromDocument));
    }
  }

  @override
  String createNotebook(String name, String subjectId) {
    var newNotebook = _collection(_notebooksCollection).doc();
    newNotebook.set({
      'name': name,
      'subject_id': subjectId,
      'user_id': _requireUser().uid,
    });
    return newNotebook.id;
  }

  @override
  void editNotebook(String id, String name, String subjectId) {
    var doc = _collection(_notebooksCollection).doc(id);
    doc.update({
      'name': name,
      'subject_id': subjectId,
      'user_id': _requireUser().uid,
    });
  }

  @override
  void deleteNotebook(String id) => _delete(_notebooksCollection, id);

  @override
  bool hasAccount() => true;

  CollectionReference<Map<String, dynamic>> _collection(String collection) =>
      FirebaseFirestore.instance.collection(collection);

  void _delete(String collection, String id) {
    var doc = _collection(collection).doc(id);
    doc.delete();
  }

  User _requireUser() {
    var user = FirebaseAuth.instance.currentUser;
    assert(user != null, 'User required for operation!');
    return user!;
  }
}
