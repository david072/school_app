import 'dart:async';
import 'dart:ui';

import 'package:path/path.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/database/database_firestore.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/util/util.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqlbrite/sqlbrite.dart' as b;

class DatabaseSqlite extends Database {
  static const _subjectsTable = 'subjects';
  static const _tasksTable = 'tasks';
  static const _deletedTasksTable = 'deleted_tasks';

  b.BriteDatabase? database;

  /// Lock for `_open()`
  Future<void>? _openRunning;

  @override
  Stream<List<Subject>> querySubjects() async* {
    await _open();

    // TODO: Task count
    var subjects = database!.createQuery(_subjectsTable);
    await for (final func in subjects) {
      var rows = await func();
      yield rows.map(Subject.fromRow).toList();
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
      yield Subject.fromRow(row);
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
  void createSubject(String name, String abbreviation, Color color) async {
    await _open();
    database!.insert(_subjectsTable, {
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
    });
  }

  @override
  void editSubject(
      String id, String name, String abbreviation, Color color) async {
    await _open();
    database!.update(_subjectsTable, {
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
    });
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
  void createTask(String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId) async {
    await _open();
    database!.insert(_tasksTable, {
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'reminder': reminder.millisecondsSinceEpoch,
      'subject_id': int.parse(subjectId),
      'completed': 0,
    });
  }

  @override
  void editTask(String id, String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId) async {
    await _open();
    database!.update(
      _tasksTable,
      {
        'title': title,
        'description': description,
        'due_date': dueDate.millisecondsSinceEpoch,
        'reminder': reminder.millisecondsSinceEpoch,
        'subject_id': int.parse(subjectId),
      },
      where: 'id = ?',
      whereArgs: [int.parse(id)],
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
      {'deleted_at': DateTime.now().date},
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
      yield await Future.wait(
        row.map((e) => Task.fromRow(e, isDeleted: true)),
      );
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
  void deleteAllData() async => throw Exception("This should not be called!");

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
        await db.execute('CREATE TABLE $_subjectsTable('
            'id INTEGER PRIMARY KEY AUTOINCREMENT,'
            'name TEXT,'
            'abbreviation TEXT,'
            'color INTEGER'
            ')');

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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion == 1 && newVersion == 2) {
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
      },
      version: 2,
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
      var subject = Subject.fromRow(row);
      var id = firestoreDb.createSubject(
        subject.name,
        subject.abbreviation,
        subject.color,
      );
      subjectIdsMap[row['id'] as int] = id;
    }

    var tasks = await db.query(_tasksTable);
    for (final row in tasks) {
      var subjectId = subjectIdsMap[row['subject_id'] as int]!;
      firestoreDb.createTask(
        row['title']! as String,
        row['description']! as String,
        DateTime.fromMillisecondsSinceEpoch(row['due_date']! as int),
        DateTime.fromMillisecondsSinceEpoch(row['reminder']! as int),
        subjectId,
      );
    }

    sqflite.deleteDatabase(await _databasePath());
  }

  static Future<String> _databasePath() async =>
      join(await sqflite.getDatabasesPath(), 'database.db');
}
