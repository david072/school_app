import 'dart:ui';

import 'package:get_it/get_it.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';

abstract class Database {
  /// Short for `instance`
  static Database get I => GetIt.I.get<Database>();

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
