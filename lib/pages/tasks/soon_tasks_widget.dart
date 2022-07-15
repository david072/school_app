import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/class_test.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/class_tests/create_class_test_page.dart';
import 'package:school_app/pages/class_tests/view_class_test_page.dart';
import 'package:school_app/pages/home/footer.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/pages/tasks/view_task_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

enum TasksListMode { normal, deleted }

class TasksList extends StatefulWidget {
  const TasksList({
    Key? key,
    required this.items,
    this.mode = TasksListMode.normal,
  }) : super(key: key);

  final List items;
  final TasksListMode mode;

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  late Offset longPressPosition;

  bool get isDeletedMode => widget.mode == TasksListMode.deleted;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: GestureDetector(
            onTapDown: (details) => longPressPosition = details.globalPosition,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.minWidth),
              child: DataTable(
                columnSpacing: isSmallScreen(context) ? 20 : null,
                showCheckboxColumn: false,
                columns: [
                  DataColumn(
                      label: Text((!isDeletedMode ? 'done' : 'deleted_at').tr)),
                  DataColumn(
                      label: Text(!isDeletedMode ? 'due'.tr : 'done'.tr)),
                  DataColumn(label: Text('title'.tr)),
                  DataColumn(label: Text('subject'.tr)),
                ],
                rows: widget.items
                    .map(
                      (task) => _taskRow(
                        context,
                        widget.mode,
                        task,
                        () => showPopupMenu(
                          context: context,
                          items: !isDeletedMode
                              ? [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Text('edit'.tr),
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Text('delete'.tr),
                                  ),
                                ]
                              : [
                                  PopupMenuItem(
                                    value: 1,
                                    child: Text('delete_permanently'.tr),
                                  ),
                                ],
                          position: longPressPosition,
                          functions: [
                            () =>
                                Get.to(() => CreateTaskPage(taskToEdit: task)),
                            () => showConfirmationDialog(
                                  context: context,
                                  title: !isDeletedMode
                                      ? 'delete'.tr
                                      : 'delete_permanently'.tr,
                                  content: (!isDeletedMode
                                          ? 'delete_task_confirm'
                                          : 'delete_task_permanently_confirm')
                                      .trParams({'name': task.title}),
                                  cancelText: 'cancel_caps'.tr,
                                  confirmText: 'delete_caps'.tr,
                                  onConfirm: () {
                                    if (!isDeletedMode) {
                                      Database.I.deleteTask(task.id);
                                    } else {
                                      Database.I.permanentlyDeleteTask(task.id);
                                    }
                                  },
                                ),
                          ],
                        ),
                        () {
                          if (task is Task) {
                            Get.to(() => ViewTaskPage(
                                  taskId: task.id,
                                  isTaskDeleted: isDeletedMode,
                                ));
                          } else if (task is ClassTest) {
                            Get.to(() => ViewClassTestPage(
                                  testId: task.id,
                                ));
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _taskRow(
    BuildContext context,
    TasksListMode mode,
    dynamic task,
    void Function() onLongPress,
    void Function() onSelectChanged,
  ) {
    DataCell completedCell;
    DataCell titleCell;
    Subject subject;
    String relativeDueDate;

    if (task is Task) {
      subject = task.subject;
      relativeDueDate = task.formatRelativeDueDate();

      completedCell = DataCell(
        Builder(
          builder: (_) {
            // (HACK) to make the UI element update instantly
            var value = task.completed;
            return StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  onChanged: mode != TasksListMode.normal
                      ? null
                      : (b) {
                          if (b == null) return;
                          setState(() => value = b);
                          Database.I.updateTaskStatus(task.id, b);
                        },
                  value: value,
                ),
              ),
            );
          },
        ),
      );

      titleCell = DataCell(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: task.title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              WidgetSpan(
                  child: task.description.isNotEmpty
                      ? const SizedBox(width: 10)
                      : Container()),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: task.description.isNotEmpty
                    ? IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.sticky_note_2_outlined,
                            color: Theme.of(context).hintColor),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('description'.tr),
                            content: Text(task.description),
                          ),
                        ),
                      )
                    : Container(),
              )
            ],
          ),
        ),
      );
    } else if (task is ClassTest) {
      subject = task.subject;
      relativeDueDate = task.formatRelativeDueDate();
      completedCell = const DataCell(Icon(Icons.description));
      titleCell = DataCell(Text(
        'TODO',
        style: Theme.of(context).textTheme.bodyLarge,
      ));
    } else {
      throw 'task argument has invalid type';
    }

    var subjectCell = DataCell(
      RichText(
        text: TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.book_outlined, color: task.subject.color),
            ),
            const WidgetSpan(child: SizedBox(width: 10)),
            TextSpan(
              text: subject.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: task.subject.color,
                  ),
            ),
          ],
        ),
      ),
    );

    List<DataCell> cells;

    if (mode == TasksListMode.normal) {
      cells = [
        completedCell,
        DataCell(Text(relativeDueDate,
            style: Theme.of(context).textTheme.bodyLarge)),
        titleCell,
        subjectCell,
      ];
    } else {
      assert(task is Task, 'Deleted class tests not supported yet.');
      cells = [
        DataCell(Text(
            '${formatDate((task as Task).deletedAt!)} '
            '(${task.formatRelativeDeletedAtDate()})',
            style: Theme.of(context).textTheme.bodyLarge)),
        completedCell,
        titleCell,
        subjectCell,
      ];
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith((states) {
        if (task is ClassTest) return Colors.grey.shade900;

        if (task.completed) {
          if (!Get.isDarkMode) {
            return Colors.grey.shade300;
          } else {
            return Colors.grey.shade800;
          }
        }
        return null;
      }),
      cells: cells,
      onLongPress: onLongPress,
      onSelectChanged: (_) => onSelectChanged(),
    );
  }
}

class TaskListWidget extends StatefulWidget {
  const TaskListWidget({
    Key? key,
    this.isHorizontal = false,
    this.maxDateTime,
    this.subjectFilter,
  }) : super(key: key);

  final bool isHorizontal;
  final DateTime? maxDateTime;
  final Subject? subjectFilter;

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  List items = [];
  late StreamSubscription tasksSubscription;
  late StreamSubscription classTestsSubscription;

  late Offset longPressPosition;

  @override
  void initState() {
    super.initState();
    tasksSubscription = Database.I
        .queryTasks(
      maxDueDate: widget.maxDateTime,
    )
        .listen((data) {
      data.where((item) =>
          widget.subjectFilter != null &&
          item.subject.id == widget.subjectFilter!.id);
      updateTasks(data);
    });

    classTestsSubscription = Database.I
        .queryClassTests(maxDueDate: widget.maxDateTime)
        .listen((data) {
      data.removeWhere((item) =>
          widget.subjectFilter != null &&
          item.subject.id == widget.subjectFilter!.id);
      updateClassTests(data);
    });
  }

  void updateClassTests(List<ClassTest> newItems) {
    if (newItems.isEmpty) return;
    items.removeWhere((item) => item is ClassTest);

    if (items.isEmpty) {
      items.addAll(newItems);
      return;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Task) throw 'Invalid type in items list';

      DateTime newClassTestDueDate = newItems.first.dueDate;
      if (newClassTestDueDate.isBefore(item.dueDate) ||
          newClassTestDueDate.isAtSameMomentAs(item.dueDate)) {
        items.insert(i, newItems.first);
        newItems.removeAt(0);
      }

      if (newItems.isEmpty) break;
    }

    if (newItems.isNotEmpty) items.addAll(newItems);

    setState(() {});
  }

  void updateTasks(List<Task> newItems) {
    if (newItems.isEmpty) return;
    items.removeWhere((item) => item is Task);

    if (items.isEmpty) {
      items.addAll(newItems);
      setState(() {});
      return;
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! ClassTest) throw 'Invalid type in items list';

      DateTime newTaskDueDate = newItems.first.dueDate;
      if (newTaskDueDate.isBefore(item.dueDate)) {
        items.insert(i, newItems.first);
        newItems.removeAt(0);
      } else if (newTaskDueDate.isAtSameMomentAs(item.dueDate)) {
        items.insert(++i, newItems.first);
        newItems.removeAt(0);
      }

      if (newItems.isEmpty) break;
    }

    if (newItems.isNotEmpty) items.addAll(newItems);

    setState(() {});
  }

  @override
  void dispose() {
    tasksSubscription.cancel();
    classTestsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var completedTasks =
        items.where((task) => task is Task && task.completed).length;
    var taskCount = items.whereType<Task>().length - completedTasks;
    var classTestCount = items.whereType<ClassTest>().length;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: TasksList(items: items)),
          Footer(
            reverse: widget.isHorizontal ? true : false,
            text: IntrinsicHeight(
              child: Row(
                children: [
                  Text('Class tests: $classTestCount'),
                  const VerticalDivider(thickness: 2),
                  Text('${'tasks'.tr}: $taskCount (+ $completedTasks)'),
                ],
              ),
            ),
            popupItems: [
              PopupMenuItem(
                value: 0,
                child: Text('task'.tr),
              ),
              const PopupMenuItem(
                value: 1,
                child: Text('Class test'),
              ),
            ],
            onPopupItemSelected: (i) {
              switch (i) {
                case 0:
                  Get.to(() =>
                      CreateTaskPage(initialSubject: widget.subjectFilter));
                  break;
                case 1:
                  Get.to(() => const CreateClassTestPage());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
