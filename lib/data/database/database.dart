import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';

abstract class Database {
  /// Short for `instance`
  static Database get I => GetIt.I.get<Database>();

  static void use(Database db) {
    GetIt.I.registerSingleton<Database>(db);
  }

  Stream<List<Subject>> querySubjects();

  Stream<Subject> querySubject(String id);

  Future<Subject> querySubjectOnce(String id);

  void createSubject(String name, String abbreviation, Color color);

  void editSubject(String id, String name, String abbreviation, Color color);

  Future<void> deleteSubject(String id);

  Stream<List<Task>> queryTasks({DateTime? maxDueDate});

  Future<List<Task>> queryTasksOnce({DateTime? maxDueDate});

  Stream<Task> queryTask(String taskId);

  void createTask(String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId);

  void editTask(String id, String title, String description, DateTime dueDate,
      DateTime reminder, String subjectId);

  void updateTaskStatus(String id, bool completed);

  void deleteTask(String id);
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