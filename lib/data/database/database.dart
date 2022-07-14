import 'dart:ui';

import 'package:get/get.dart';
import 'package:school_app/data/class_test.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';

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
      List<ClassTestTopic> topics);

  void editClassTest(String id, DateTime dueDate, DateTime reminder,
      String subjectId, List<ClassTestTopic> topics);

  void deleteClassTest(String id);

  // Miscellaneous
  void deleteAllData();
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
