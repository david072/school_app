import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/home/footer.dart';
import 'package:school_app/pages/tasks/create_task_page.dart';
import 'package:school_app/pages/tasks/view_task_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

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
  List<Task> tasks = [];
  late StreamSubscription subscription;

  late Offset longPressPosition;

  @override
  void initState() {
    super.initState();
    subscription = Database.I
        .queryTasks(
          maxDueDate: widget.maxDateTime,
        )
        .listen((data) => setState(() {
              tasks = data.where((task) {
                if (widget.subjectFilter == null) return true;
                return task.subject.id == widget.subjectFilter!.id;
              }).toList();
            }));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: GestureDetector(
                    onTapDown: (details) =>
                        longPressPosition = details.globalPosition,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.minWidth),
                      child: DataTable(
                        columnSpacing: isSmallScreen(context) ? 20 : null,
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(label: Text('done'.tr)),
                          DataColumn(label: Text('due'.tr)),
                          DataColumn(label: Text('title'.tr)),
                          DataColumn(label: Text('subject'.tr)),
                        ],
                        rows: tasks
                            .map(
                              (task) => _taskRow(
                                context,
                                task,
                                () => showPopupMenu(
                                  context: context,
                                  items: [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Text('edit'.tr),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Text('delete'.tr),
                                    ),
                                  ],
                                  longPressPosition: longPressPosition,
                                  functions: [
                                    () => Get.to(
                                        () => CreateTaskPage(taskToEdit: task)),
                                    () => showConfirmationDialog(
                                      context: context,
                                          title: 'delete'.tr,
                                          content: 'delete_task_confirm'
                                              .trParams({'name': task.title}),
                                          cancelText: 'cancel_caps'.tr,
                                          confirmText: 'delete_caps'.tr,
                                          onConfirm: () =>
                                              Database.I.deleteTask(task.id),
                                        ),
                                  ],
                                ),
                                () =>
                                    Get.to(() => ViewTaskPage(taskId: task.id)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Footer(
            reverse: widget.isHorizontal ? true : false,
            displayName: 'tasks'.tr,
            count: tasks.length,
            onAdd: () => Get.to(
                () => CreateTaskPage(initialSubject: widget.subjectFilter)),
          ),
        ],
      ),
    );
  }
}

DataRow _taskRow(BuildContext context, Task task, void Function() onLongPress,
    void Function() onSelectChanged) {
  return DataRow(
    color: MaterialStateProperty.resolveWith((states) {
      if (task.completed) {
        if (!Get.isDarkMode) {
          return Colors.grey.shade300;
        } else {
          return Colors.grey.shade800;
        }
      }
      return null;
    }),
    cells: [
      DataCell(
        Builder(
          builder: (_) {
            // (HACK) to make the UI element update instantly
            var value = task.completed;
            return StatefulBuilder(builder: (context, setState) {
              return SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  onChanged: (b) {
                    if (b == null) return;
                    setState(() => value = b);
                    Database.I.updateTaskStatus(task.id, b);
                  },
                  value: value,
                ),
              );
            });
          },
        ),
      ),
      DataCell(Text(task.formatRelativeDueDate(),
          style: Theme.of(context).textTheme.bodyLarge)),
      DataCell(
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
                    ? Icon(Icons.sticky_note_2_outlined,
                        color: Theme.of(context).hintColor)
                    : Container(),
              )
            ],
          ),
        ),
      ),
      DataCell(
        RichText(
          text: TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(Icons.book_outlined, color: task.subject.color),
              ),
              const WidgetSpan(child: SizedBox(width: 10)),
              TextSpan(
                text: task.subject.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: task.subject.color,
                    ),
              ),
            ],
          ),
        ),
      ),
    ],
    onLongPress: onLongPress,
    onSelectChanged: (_) => onSelectChanged(),
  );
}
