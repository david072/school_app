import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/data/tasks/class_test.dart';
import 'package:school_app/data/tasks/task.dart';
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

  final List<AbstractTask> items;
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
                            () {
                              if (task is Task) {
                                Get.to(() => CreateTaskPage(taskToEdit: task));
                              } else if (task is ClassTest) {
                                Get.to(() =>
                                    CreateClassTestPage(classTestToEdit: task));
                              } else {
                                throw 'task has invalid type';
                              }
                            },
                            () => showConfirmationDialog(
                                  context: context,
                                  title: !isDeletedMode
                                      ? 'delete'.tr
                                      : 'delete_permanently'.tr,
                                  content: task.deleteDialogContent(),
                                  cancelText: 'cancel_caps'.tr,
                                  confirmText: 'delete_caps'.tr,
                                  onConfirm: () => task.delete(),
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
                                  isClassTestDeleted: isDeletedMode,
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
    AbstractTask task,
    void Function() onLongPress,
    void Function() onSelectChanged,
  ) {
    DataCell completedCell = task.getCompletedCell(mode);
    DataCell titleCell = task.getTitleCell(context);
    Subject subject = task.subject;
    String relativeDueDate = task.formatRelativeDueDate();

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
      cells = [
        DataCell(Text(
            '${formatDate(task.deletedAt!)} '
            '(${task.formatRelativeDeletedAtDate()})',
            style: Theme.of(context).textTheme.bodyLarge)),
        completedCell,
        titleCell,
        subjectCell,
      ];
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith(
          (states) => task.tableRowBackgroundColor()),
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
  List<AbstractTask> items = [];
  late StreamSubscription subscription;

  late Offset longPressPosition;

  @override
  void initState() {
    super.initState();
    subscription = Database.queryTasksAndClassTests().listen((tasks) =>
        setState(() => items = tasks
            .where((task) =>
                widget.subjectFilter == null ||
                task.subject.id == widget.subjectFilter!.id)
            .toList()));
  }

  @override
  void dispose() {
    subscription.cancel();
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
                  Text('${'class_tests'.tr}: $classTestCount'),
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
              PopupMenuItem(
                value: 1,
                child: Text('class_test'.tr),
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