import 'dart:async';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/data/tasks/task.dart';

abstract class Database {
  /// Short for `instance`
  static Database get I => Get.find<Database>();

  static void use(Database db) {
    Get.delete<Database>(force: true);
    Get.put(db, permanent: true);
  }

  // Subjects
  Stream<List<Subject>> querySubjects();

  Stream<Subject> querySubject(String id);

  Future<Subject> querySubjectOnce(String id);

  Future<List<int>> queryTaskCountForSubject(String id);

  void createSubject(String name, String abbreviation, Color color);

  void editSubject(String id, String name, String abbreviation, Color color);

  void updateSubjectNotes(String id, String notes);

  Future<void> deleteSubject(String id);

  // Tasks
  Stream<List<Task>> queryTasks({DateTime? maxDueDate});

  Future<List<Task>> queryTasksOnce({DateTime? maxDueDate});

  Stream<Task> queryTask(String taskId);

  void createTask(String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId);

  void editTask(String id, String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId);

  void updateTaskStatus(String id, bool completed);

  void deleteTask(String id);

  // Deleted tasks
  Stream<List<Task>> queryDeletedTasks();

  Future<List<Task>> queryDeletedTasksOnce();

  Stream<Task> queryDeletedTask(String id);

  void permanentlyDeleteTask(String id);

  // Class tests
  Stream<List<ClassTest>> queryClassTests({DateTime? maxDueDate});

  Future<List<ClassTest>> queryClassTestsOnce();

  Stream<ClassTest> queryClassTest(String id);

  void createClassTest(DateTime dueDate, DateTime reminder, String subjectId,
      List<ClassTestTopic> topics, String type);

  void editClassTest(String id, DateTime dueDate, DateTime reminder,
      String subjectId, List<ClassTestTopic> topics, String type);

  void deleteClassTest(String id);

  // Deleted class tests
  Stream<List<ClassTest>> queryDeletedClassTests();

  Future<List<ClassTest>> queryDeletedClassTestsOnce();

  Stream<ClassTest> queryDeletedClassTest(String id);

  void permanentlyDeleteClassTest(String id);

  // Miscellaneous
  void deleteAllData();

  static Stream<List<AbstractTask>> queryTasksAndClassTests(
      {DateTime? maxDueDate, bool areDeleted = false}) async* {
    var controller = StreamController<List<AbstractTask>>();

    Stream<List<Task>> tasksStream;
    Stream<List<ClassTest>> classTestsStream;

    if (!areDeleted) {
      tasksStream = I.queryTasks(maxDueDate: maxDueDate);
      classTestsStream = I.queryClassTests(maxDueDate: maxDueDate);
    } else {
      tasksStream = I.queryDeletedTasks();
      classTestsStream = I.queryDeletedClassTests();
    }

    tasksStream.listen(controller.sink.add);
    classTestsStream.listen(controller.sink.add);

    List<AbstractTask> result = [];
    await for (final tasks in controller.stream) {
      if (tasks is List<Task>) {
        yield updateTasks(result, tasks);
      } else if (tasks is List<ClassTest>) {
        yield updateClassTests(result, tasks);
      } else {
        throw 'Invalid list type from stream';
      }
    }
  }

  static Future<List<AbstractTask>> queryTasksAndClassTestsOnce(
      {bool areDeleted = false}) async {
    Future<List<Task>> tasksFuture;
    Future<List<ClassTest>> classTestsFuture;

    if (!areDeleted) {
      tasksFuture = I.queryTasksOnce();
      classTestsFuture = I.queryClassTestsOnce();
    } else {
      tasksFuture = I.queryDeletedTasksOnce();
      classTestsFuture = I.queryDeletedClassTestsOnce();
    }

    final results = await Future.wait([tasksFuture, classTestsFuture]);
    List<AbstractTask> result = [];
    updateTasks(result, results[0] as List<Task>);
    updateClassTests(result, results[1] as List<ClassTest>);

    return result;
  }

  static List<AbstractTask> updateClassTests(
      List<AbstractTask> list, List<ClassTest> newItems) {
    list.removeWhere((item) => item is ClassTest);
    if (newItems.isEmpty) return list;

    if (list.isEmpty) {
      list.addAll(newItems);
      return list;
    }

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Task) throw 'Invalid type in list list';

      DateTime newClassTestDueDate = newItems.first.dueDate;
      if (newClassTestDueDate.isBefore(item.dueDate) ||
          newClassTestDueDate.isAtSameMomentAs(item.dueDate)) {
        list.insert(i, newItems.first);
        newItems.removeAt(0);
      }

      if (newItems.isEmpty) break;
    }

    if (newItems.isNotEmpty) list.addAll(newItems);
    return list;
  }

  static List<AbstractTask> updateTasks(
      List<AbstractTask> list, List<Task> newItems) {
    list.removeWhere((item) => item is Task);
    if (newItems.isEmpty) return list;

    if (list.isEmpty) {
      list.addAll(newItems);
      return list;
    }

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! ClassTest) throw 'Invalid type in list list';

      DateTime newTaskDueDate = newItems.first.dueDate;
      if (newTaskDueDate.isBefore(item.dueDate)) {
        list.insert(i, newItems.first);
        newItems.removeAt(0);
      } else if (newTaskDueDate.isAtSameMomentAs(item.dueDate)) {
        list.insert(++i, newItems.first);
        newItems.removeAt(0);
      }

      if (newItems.isEmpty) break;
    }

    if (newItems.isNotEmpty) list.addAll(newItems);
    return list;
  }
}

/// Helper to move all completed tasks to the bottom of the list,
/// keeping order for the other ones.
List<Task> orderByCompleted(List<Task> tasks) {
  List<Task> result = [];
  for (int i = tasks.length - 1; i >= 0; i--) {
    final task = tasks[i];
    if (task.completed) {
      result.add(task);
    } else {
      result.insert(0, task);
    }
  }
  return result;
}

extension MapWaiting<T> on List<T> {
  Future<List<R>> mapWaiting<R>(Future<R> Function(T) func) async {
    return await Future.wait(map(func));
  }
}
