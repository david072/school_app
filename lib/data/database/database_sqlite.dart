import 'dart:async';

import 'package:path/path.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/data/tasks/task.dart';
import 'package:school_app/util/util.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqlbrite/sqlbrite.dart' as b;

class DatabaseSqlite extends Database {
  static const _subjectsTable = 'subjects';
  static const _tasksTable = 'tasks';
  static const _deletedTasksTable = 'deleted_tasks';
  static const _classTestsTable = 'class_tests';
  static const _deletedClassTestsTable = 'deleted_class_tests';

  b.BriteDatabase? database;

  /// Lock for `_open()`
  Future<void>? _openRunning;

  @override
  Stream<List<Subject>> querySubjects() async* {
    await _open();

    var controller = StreamController<List<Subject>>();

    database!.createQuery(_subjectsTable).listen((event) async {
      var rows = await event();
      controller.sink.add(await rows.mapWaiting(Subject.fromRow));
    });

    database!.createQuery(_tasksTable).listen((event) async {
      var subjects = await database!.query(_subjectsTable);
      controller.sink.add(await subjects.mapWaiting(Subject.fromRow));
    });

    await for (final subjects in controller.stream) {
      yield subjects;
    }
  }

  @override
  Stream<Subject> querySubject(String id) async* {
    await _open();
    var subject = database!.createQuery(
      _subjectsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );
    await for (final func in subject) {
      var row = (await func())[0];
      yield await Subject.fromRow(row);
    }
  }

  @override
  Future<Subject> querySubjectOnce(String id) async {
    await _open();
    var subject = await database!.query(
      _subjectsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    return Subject.fromRow(subject[0]);
  }

  @override
  Future<List<int>> queryTaskCountForSubject(String id) async {
    await _open();
    var tasks = await database!.query(_tasksTable,
        where: 'subject_id = ?', whereArgs: [int.parse(id)]);

    var taskCount = 0;
    var completedTaskCount = 0;
    for (final row in tasks) {
      if (row['completed'] == 1) {
        completedTaskCount++;
      } else {
        taskCount++;
      }
    }

    return [taskCount, completedTaskCount];
  }

  @override
  void createSubject(Subject subject) async {
    await _open();
    database!.insert(_subjectsTable, subject.data());
  }

  @override
  void editSubject(Subject data) async {
    await _open();
    database!.update(
      _subjectsTable,
      where: 'id = ?',
      whereArgs: [int.parse(data.id)],
      data.data(),
    );
  }

  @override
  void updateSubjectNotes(String id, String notes) async {
    await _open();
    database!.update(
      _subjectsTable,
      {'notes': notes},
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  @override
  Future<void> deleteSubject(String id) async {
    await _open();
    var tasks = await database!.query(
      _tasksTable,
      where: 'subject_id = ?',
      whereArgs: [int.parse(id)],
    );
    for (final task in tasks) {
      database!.delete(_tasksTable, where: 'id = ?', whereArgs: [task['id']]);
    }

    database!
        .delete(_subjectsTable, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  @override
  Stream<List<Task>> queryTasks({DateTime? maxDueDate}) async* {
    await _open();

    String? where = maxDueDate != null ? 'due_date < ?' : null;
    List? whereArgs =
        maxDueDate != null ? [maxDueDate.millisecondsSinceEpoch] : null;
    var query = database!.createQuery(
      _tasksTable,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'due_date ASC',
    );
    await for (final func in query) {
      var rows = await func();
      yield orderByCompleted(await Future.wait(rows.map(Task.fromRow)));
    }
  }

  @override
  Future<List<Task>> queryTasksOnce({DateTime? maxDueDate}) async {
    await _open();
    var tasks = await database!.query(_tasksTable);
    return Future.wait(tasks.map(Task.fromRow));
  }

  @override
  Stream<Task> queryTask(String taskId) async* {
    await _open();
    var task = database!.createQuery(
      _tasksTable,
      where: 'id = ?',
      whereArgs: [int.parse(taskId)],
    );
    await for (final func in task) {
      var row = await func();
      yield await Task.fromRow(row[0]);
    }
  }

  @override
  void createTask(Task task) async {
    await _open();
    database!.insert(_tasksTable, task.data());
  }

  @override
  void editTask(Task data) async {
    await _open();
    database!.update(
      _tasksTable,
      data.data(),
      where: 'id = ?',
      whereArgs: [int.parse(data.id)],
    );
  }

  @override
  void updateTaskStatus(String id, bool completed) async {
    await _open();
    database!.update(
      _tasksTable,
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  @override
  void deleteTask(String id) async {
    await _open();

    var newId = await database!.rawInsert(
      'INSERT INTO $_deletedTasksTable'
      ' SELECT * FROM $_tasksTable WHERE id = ?',
      [int.parse(id)],
    );
    // Add deleted_at
    database!.update(
      _deletedTasksTable,
      {'deleted_at': DateTime.now().date.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [newId],
    );

    database!.delete(_tasksTable, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  @override
  Stream<List<Task>> queryDeletedTasks() async* {
    await _open();

    var query = database!.createQuery(_deletedTasksTable);
    await for (final func in query) {
      var row = await func();
      yield await Future.wait(row.map(Task.fromRow));
    }
  }

  @override
  Future<List<Task>> queryDeletedTasksOnce() async {
    await _open();

    var query = await database!.query(_deletedTasksTable);
    return await Future.wait(query.map(Task.fromRow));
  }

  @override
  Stream<Task> queryDeletedTask(String id) async* {
    await _open();

    var query = database!.createQuery(
      _deletedTasksTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    await for (final func in query) {
      var row = await func();
      yield await Task.fromRow(row[0]);
    }
  }

  @override
  void permanentlyDeleteTask(String id) async {
    await _open();
    database!.delete(
      _deletedTasksTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  @override
  Stream<List<ClassTest>> queryClassTests({DateTime? maxDueDate}) async* {
    await _open();
    var query = database!.createQuery(_classTestsTable);
    await for (final func in query) {
      final rows = await func();
      yield await rows.mapWaiting(ClassTest.fromRow);
    }
  }

  @override
  Future<List<ClassTest>> queryClassTestsOnce() async {
    await _open();
    var query = await database!.query(_classTestsTable);
    return query.mapWaiting(ClassTest.fromRow);
  }

  @override
  Stream<ClassTest> queryClassTest(String id) async* {
    await _open();
    var query = database!.createQuery(_classTestsTable,
        where: 'id = ?', whereArgs: [int.parse(id)]);
    await for (final func in query) {
      var rows = await func();
      yield await ClassTest.fromRow(rows[0]);
    }
  }

  @override
  void createClassTest(ClassTest classTest) async {
    await _open();
    database!.insert(_classTestsTable, classTest.data());
  }

  @override
  void editClassTest(ClassTest data) async {
    await _open();
    database!.update(
      _classTestsTable,
      where: 'id = ?',
      whereArgs: [int.parse(data.id)],
      data.data(),
    );
  }

  @override
  void deleteClassTest(String id) async {
    await _open();
    var row = await database!.query(
      _classTestsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );

    database!.insert(_deletedClassTestsTable, {
      ...row[0],
      'deleted_at': DateTime.now().date.millisecondsSinceEpoch,
    });

    database!.delete(
      _classTestsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  @override
  Stream<List<ClassTest>> queryDeletedClassTests() async* {
    await _open();

    var query = database!.createQuery(_deletedClassTestsTable);
    await for (final func in query) {
      var rows = await func();
      yield await rows.mapWaiting(ClassTest.fromRow);
    }
  }

  @override
  Future<List<ClassTest>> queryDeletedClassTestsOnce() async {
    await _open();

    var query = await database!.query(_deletedClassTestsTable);
    return query.mapWaiting(ClassTest.fromRow);
  }

  @override
  Stream<ClassTest> queryDeletedClassTest(String id) async* {
    await _open();

    var query = database!.createQuery(
      _deletedClassTestsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    await for (final func in query) {
      var rows = await func();
      yield await ClassTest.fromRow(rows[0]);
    }
  }

  @override
  void permanentlyDeleteClassTest(String id) async {
    await _open();
    database!.delete(
      _deletedClassTestsTable,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }

  // Firebase specific
  @override
  void deleteAllData() async => throw 'This should not be called!';

  @override
  Future<String> createTaskLink(Task task) =>
      DatabaseFirestore().createTaskLink(task);

  /// NOTE: Calls to this function wait for a previous call to finish. This
  /// prevents overriding [database] with a following call to the function.
  /// Each execution waits for the previous one, using the [_openRunning]
  /// future.
  Future<void> _open() async {
    if (_openRunning != null) {
      await _openRunning;
    }

    // Lock _open()
    var completer = Completer<void>();
    _openRunning = completer.future;

    if (database != null) {
      completer.complete();
      return;
    }

    var db = await sqflite.openDatabase(
      await _databasePath(),
      onCreate: (db, version) async {
        // Subjects table
        await db.execute('CREATE TABLE $_subjectsTable('
            'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'name TEXT,'
            'abbreviation TEXT,'
            'color INTEGER,'
            'notes TEXT'
            ')');

        // Tasks table and deleted tasks table
        const tasksTableSql = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'title TEXT,'
            'description TEXT,'
            'due_date INTEGER,'
            'reminder INTEGER,'
            'completed INTEGER,'
            'subject_id INTEGER';
        await db.execute('CREATE TABLE $_tasksTable($tasksTableSql)');
        await db.execute('CREATE TABLE $_deletedTasksTable('
            '$tasksTableSql,'
            'deleted_at INTEGER'
            ')');

        // Class tests table and deleted class tests table
        const classTestsTableSql = 'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'due_date INTEGER,'
            'reminder INTEGER,'
            'subject_id INTEGER,'
            'topics STRING,'
            'type STRING';
        await db.execute('CREATE TABLE $_classTestsTable($classTestsTableSql)');
        await db.execute('CREATE TABLE $_deletedClassTestsTable('
            '$classTestsTableSql,'
            'deleted_at INTEGER'
            ')');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (newVersion >= 1 && newVersion < 2) {
          // Create deleted tasks table
          await db.execute('CREATE TABLE $_deletedTasksTable('
              'id INTEGER PRIMARY KEY AUTOINCREMENT,'
              'title TEXT,'
              'description TEXT,'
              'due_date INTEGER,'
              'reminder INTEGER,'
              'completed INTEGER,'
              'subject_id INTEGER'
              'deleted_at INTEGER'
              ')');
        }

        if (newVersion >= 2 && newVersion < 3) {
          await db.execute('ALTER TABLE $_subjectsTable ADD notes TEXT');
        }

        if (newVersion >= 4) {
          await db.execute('CREATE TABLE $_classTestsTable('
              'id INTEGER PRIMARY KEY AUTOINCREMENT,'
              'due_date INTEGER,'
              'reminder INTEGER,'
              'subject_id INTEGER,'
              'topics STRING,'
              'type STRING'
              ')');
        }
      },
      version: 4,
    );

    database = b.BriteDatabase(db, logger: null);
    completer.complete();
  }

  /// Moves all locally stored data to Firebase Firestore and then deletes
  /// the local database.
  static Future<void> migrateToFirestore() async {
    if (!await sqflite.databaseExists(await _databasePath())) return;

    var db = await sqflite.openDatabase(await _databasePath());
    var firestoreDb = DatabaseFirestore();

    var subjects = await db.query(_subjectsTable);
    Map<int, String> subjectIdsMap = {};

    for (final row in subjects) {
      var subject = await Subject.fromRow(row);
      var id = firestoreDb.createSubject(subject);
      subjectIdsMap[row['id'] as int] = id;
    }

    var tasks = await db.query(_tasksTable);
    for (final row in tasks) {
      var subjectId = subjectIdsMap[row['subject_id'] as int]!;
      var task = await Task.fromRow(row, subjectId: subjectId);
      firestoreDb.createTask(task);
    }

    var deletedTasks = await db.query(_deletedTasksTable);
    for (final row in deletedTasks) {
      var subjectId = subjectIdsMap[row['subject_id'] as int]!;
      var task = await Task.fromRow(row, subjectId: subjectId);
      firestoreDb.createDeletedTask(task);
    }

    var classTests = await db.query(_classTestsTable);
    for (final row in classTests) {
      var subjectId = subjectIdsMap[row['subject_id'] as int]!;
      var classTest = await ClassTest.fromRow(row, subjectId: subjectId);
      firestoreDb.createClassTest(classTest);
    }

    var deletedClassTests = await db.query(_deletedClassTestsTable);
    for (final row in deletedClassTests) {
      var subjectId = subjectIdsMap[row['subject_id'] as int]!;
      var classTest = await ClassTest.fromRow(row, subjectId: subjectId);
      firestoreDb.createDeletedClassTest(classTest);
    }

    sqflite.deleteDatabase(await _databasePath());
  }

  static Future<String> _databasePath() async =>
      join(await sqflite.getDatabasesPath(), 'database.db');
}
