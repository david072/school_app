import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/util/util.dart';

import '../subject.dart';

class DatabaseFirestore implements Database {
  static const _subjectsCollection = 'subjects';
  static const _tasksCollection = 'tasks';
  static const _deletedTasksCollection = 'deleted_tasks';
  static const _classTestsCollection = 'class_tests';
  static const _deletedClassTestsCollection = 'deleted_class_tests';

  static const _linkBaseUrl = 'https://school-app-3bd33.web.app/link?id=';
  static const _linksCollection = 'links';

  @override
  Stream<List<Subject>> querySubjects() async* {
    var controller = StreamController<List<Subject>>();

    // TODO: Query / store task count
    _collection(_subjectsCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .snapshots()
        .listen((event) async {
      controller.sink.add(await event.docs.mapWaiting(Subject.fromDocument));
    });

    _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .snapshots(includeMetadataChanges: false)
        .listen((event) async {
      controller.sink.add(await querySubjectsOnce());
    });

    await for (final subjects in controller.stream) {
      yield subjects;
    }
  }

  @override
  Future<List<Subject>> querySubjectsOnce() async {
    var subjects = await _collection(_subjectsCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .get();
    return await subjects.docs.mapWaiting(Subject.fromDocument);
  }

  @override
  Stream<Subject> querySubject(String id) async* {
    var doc = _collection(_subjectsCollection).doc(id).snapshots();
    await for (final subject in doc) {
      yield await Subject.fromDocument(subject);
    }
  }

  @override
  Future<Subject> querySubjectOnce(String id) async {
    var doc = await _collection(_subjectsCollection).doc(id).get();
    return Subject.fromDocument(doc);
  }

  @override
  Future<List<int>> queryTaskCountForSubject(String id) async {
    var tasks = await _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .where('subject_id', isEqualTo: id)
        .get();

    var taskCount = 0;
    var completedTaskCount = 0;
    for (final doc in tasks.docs) {
      if (doc.data()['completed'] == 1) {
        completedTaskCount++;
      } else {
        taskCount++;
      }
    }

    return [taskCount, completedTaskCount];
  }

  // Doesn't use async features, but the return type has to be a future because of sqlite
  @override
  Future<String> createSubject(Subject subject) async {
    var newSubject = _collection(_subjectsCollection).doc();
    newSubject.set({
      ...subject.data(),
      'user_id': _requireUserUID(),
    });
    return newSubject.id;
  }

  @override
  void editSubject(Subject data) {
    var doc = _collection(_subjectsCollection).doc(data.id);
    doc.update({
      ...data.data(),
      'user_id': _requireUserUID(),
    });
  }

  @override
  void updateSubjectNotes(String id, String notes) {
    var doc = _collection(_subjectsCollection).doc(id);
    doc.update({'notes': notes});
  }

  /// Also deletes tasks associated with this subject
  @override
  Future<void> deleteSubject(String id) async {
    // Delete tasks associated with this subject id
    var tasks = await _collection(_tasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .where('subject_id', isEqualTo: id)
        .get();
    var deletedTasks = await _collection(_deletedTasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .where('subject_id', isEqualTo: id)
        .get();
    for (final task in [...tasks.docs, ...deletedTasks.docs]) {
      task.reference.delete();
    }

    _delete(_subjectsCollection, id);
  }

  Query<Map<String, dynamic>> _tasksQuery(String collection,
      {DateTime? maxDueDate}) {
    var query =
        _collection(collection).where('user_id', isEqualTo: _requireUserUID());
    if (maxDueDate != null) {
      query = query.where('due_date',
          isLessThan: maxDueDate.millisecondsSinceEpoch);
    }
    return query.orderBy('due_date');
  }

  @override
  Stream<List<Task>> queryTasks({DateTime? maxDueDate}) async* {
    var query =
        _tasksQuery(_tasksCollection, maxDueDate: maxDueDate).snapshots();

    await for (final docs in query) {
      yield orderByCompleted(await docs.docs.mapWaiting(Task.fromDocument));
    }
  }

  @override
  Future<List<Task>> queryTasksOnce({DateTime? maxDueDate}) async {
    var tasks =
        await _tasksQuery(_tasksCollection, maxDueDate: maxDueDate).get();
    return await tasks.docs.mapWaiting(Task.fromDocument);
  }

  @override
  Stream<Task> queryTask(String taskId) async* {
    var query = _collection(_tasksCollection).doc(taskId).snapshots();
    await for (final task in query) {
      yield await Task.fromDocument(task);
    }
  }

  @override
  void createTask(Task task) {
    _collection(_tasksCollection).add({
      ...task.data(),
      'user_id': _requireUserUID(),
    });
  }

  @override
  void editTask(Task data) {
    var doc = _collection(_tasksCollection).doc(data.id);
    doc.update(data.data());
  }

  @override
  void updateTaskStatus(String id, bool completed) {
    var doc = _collection(_tasksCollection).doc(id);
    doc.update({'completed': completed});
  }

  @override
  void deleteTask(String id) async {
    var task = await _collection(_tasksCollection).doc(id).get();

    var data = task.data()!;
    data['deleted_at'] = DateTime.now().date.millisecondsSinceEpoch;
    _collection(_deletedTasksCollection).add(data);
    task.reference.delete();
  }

  @override
  Stream<List<Task>> queryDeletedTasks() async* {
    var deletedTasks = _collection(_deletedTasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .orderBy('deleted_at', descending: true)
        .snapshots();

    await for (final tasks in deletedTasks) {
      yield await tasks.docs.mapWaiting(Task.fromDocument);
    }
  }

  @override
  Future<List<Task>> queryDeletedTasksOnce() async {
    var query = await _collection(_deletedTasksCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .get();
    return await query.docs.mapWaiting(Task.fromDocument);
  }

  @override
  Stream<Task> queryDeletedTask(String id) async* {
    var query = _collection(_deletedTasksCollection).doc(id).snapshots();
    await for (final task in query) {
      yield await Task.fromDocument(task);
    }
  }

  void createDeletedTask(Task task) {
    _collection(_deletedTasksCollection).add({
      ...task.data(),
      'deleted_at': task.deletedAt!.millisecondsSinceEpoch,
      'user_id': _requireUserUID(),
    });
  }

  @override
  void permanentlyDeleteTask(String id) => _delete(_deletedTasksCollection, id);

  @override
  Stream<List<ClassTest>> queryClassTests({DateTime? maxDueDate}) async* {
    var query =
        _tasksQuery(_classTestsCollection, maxDueDate: maxDueDate).snapshots();
    await for (final docs in query) {
      yield await docs.docs.mapWaiting(ClassTest.fromDocument);
    }
  }

  @override
  Future<List<ClassTest>> queryClassTestsOnce() async {
    var query = await _collection(_classTestsCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .get();
    return await query.docs.mapWaiting(ClassTest.fromDocument);
  }

  @override
  Stream<ClassTest> queryClassTest(String id) async* {
    var query = _collection(_classTestsCollection).doc(id).snapshots();
    await for (final doc in query) {
      yield await ClassTest.fromDocument(doc);
    }
  }

  @override
  void createClassTest(ClassTest classTest) {
    _collection(_classTestsCollection).add({
      ...classTest.data(),
      'user_id': _requireUserUID(),
    });
  }

  @override
  void editClassTest(ClassTest data) {
    var doc = _collection(_classTestsCollection).doc(data.id);
    doc.update(data.data());
  }

  @override
  void deleteClassTest(String id) async {
    var classTest = await _collection(_classTestsCollection).doc(id).get();

    var data = classTest.data()!;
    data['deleted_at'] = DateTime.now().date.millisecondsSinceEpoch;
    _collection(_deletedClassTestsCollection).add(data);
    classTest.reference.delete();
  }

  @override
  Stream<List<ClassTest>> queryDeletedClassTests() async* {
    var stream = _collection(_deletedClassTestsCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .orderBy('deleted_at', descending: true)
        .snapshots();

    await for (final docs in stream) {
      yield await docs.docs.mapWaiting(ClassTest.fromDocument);
    }
  }

  @override
  Future<List<ClassTest>> queryDeletedClassTestsOnce() async {
    var snapshot = await _collection(_deletedClassTestsCollection)
        .where('user_id', isEqualTo: _requireUserUID())
        .get();
    return snapshot.docs.mapWaiting(ClassTest.fromDocument);
  }

  @override
  Stream<ClassTest> queryDeletedClassTest(String id) async* {
    var stream = _collection(_deletedClassTestsCollection).doc(id).snapshots();
    await for (final doc in stream) {
      yield await ClassTest.fromDocument(doc);
    }
  }

  void createDeletedClassTest(ClassTest classTest) {
    _collection(_deletedClassTestsCollection).add({
      ...classTest.data(),
      'deleted_at': classTest.deletedAt!.millisecondsSinceEpoch,
      'user_id': _requireUserUID(),
    });
  }

  @override
  void permanentlyDeleteClassTest(String id) =>
      _delete(_deletedClassTestsCollection, id);

  @override
  void deleteAllData() {
    _deleteAllFromCollection(_tasksCollection);
    _deleteAllFromCollection(_classTestsCollection);
    _deleteAllFromCollection(_subjectsCollection);
  }

  void _deleteAllFromCollection(String collection) {
    _collection(collection)
        .where('user_id', isEqualTo: _requireUserUID())
        .get()
        .then((value) {
      for (final doc in value.docs) {
        doc.reference.delete();
      }
    });
  }

  @override
  Future<String> createTaskLink(Task task) async {
    var linkDocument = await _collection(_linksCollection).add({
      'title': task.title,
      'due_date': task.dueDate.millisecondsSinceEpoch,
      'reminder': task.reminder.millisecondsSinceEpoch,
      'description': task.description,
      'subject': task.subject.data()..remove('notes'),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    return '$_linkBaseUrl${linkDocument.id}';
  }

  CollectionReference<Map<String, dynamic>> _collection(String collection) =>
      FirebaseFirestore.instance.collection(collection);

  void _delete(String collection, String id) {
    var doc = _collection(collection).doc(id);
    doc.delete();
  }

  String _requireUserUID() {
    var user = FirebaseAuth.instance.currentUser;
    assert(user != null, 'User required for operation!');
    return user!.uid;
  }
}
