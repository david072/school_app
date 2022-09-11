import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/pages/subjects/create_subject_page.dart';
import 'package:school_app/pages/tasks/view_task_widgets.dart';
import 'package:school_app/util/util.dart';

class DatePicker extends StatelessWidget {
  DatePicker({
    Key? key,
    this.enabled = true,
    required this.prefix,
    this.highlightPrefix = false,
    DateTime? firstDate,
    DateTime? lastDate,
    required this.date,
    required this.onChanged,
  }) : super(key: key) {
    var now = DateTime.now();
    this.firstDate = firstDate ?? now;
    this.lastDate = lastDate ?? DateTime(now.year + 5, 12, 31);
  }

  final bool enabled;
  final String prefix;
  final bool highlightPrefix;
  late final DateTime firstDate;
  late final DateTime lastDate;
  final DateTime date;
  final void Function(DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    return ClickableRow(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: firstDate,
                lastDate: lastDate,
              );
              if (picked != null && picked != date) onChanged(picked);
            }
          : null,
      left: Text(
        '$prefix:',
        style: !highlightPrefix
            ? Theme.of(context).textTheme.bodyText2
            : Theme.of(context).textTheme.bodyText1,
      ),
      right: Text(
        formatDate(date),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class ReminderPicker extends StatelessWidget {
  const ReminderPicker({
    Key? key,
    this.enabled = true,
    required this.mode,
    required this.reminderOffset,
    required this.dueDate,
    required this.onChanged,
  }) : super(key: key);

  final bool enabled;
  final ReminderMode mode;
  final Duration reminderOffset;
  final DateTime dueDate;
  final void Function(Duration, ReminderMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return ClickableRow(
      onTap: enabled
          ? () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('reminder_colon'.tr),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: ReminderMode.values.map((val) {
                        if (val == ReminderMode.custom) {
                          return DatePicker(
                            prefix: 'user_defined'.tr,
                            highlightPrefix: mode == val,
                            date: dueDate.subtract(reminderOffset),
                            firstDate: DateTime(DateTime.now().year - 5),
                            lastDate: dueDate,
                            onChanged: (date) {
                              var offset = dueDate.difference(date);
                              Get.back();
                              onChanged(offset, ReminderMode.custom);
                            },
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.back();
                                  onChanged(val.offset, val);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Text(val.string,
                                      style: mode == val
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyText2),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
          : null,
      left: Text('reminder_colon'.tr),
      right: Text(
        mode != ReminderMode.custom
            ? mode.string
            : formatDate(dueDate.subtract(reminderOffset)),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class SubjectPicker extends StatefulWidget {
  const SubjectPicker({
    Key? key,
    this.enabled = true,
    this.selectedSubjectId,
    required this.onChanged,
  }) : super(key: key);

  final bool enabled;
  final String? selectedSubjectId;
  final void Function(Subject) onChanged;

  @override
  State<SubjectPicker> createState() => _SubjectPickerState();
}

class _SubjectPickerState extends State<SubjectPicker> {
  List<Subject>? subjects;

  @override
  void initState() {
    super.initState();
    Database.I.querySubjects().listen((data) {
      setState(() => subjects = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return subjects == null
        ? Row(
            children: const [
              Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            ],
          )
        : ClickableRow(
            onTap: widget.enabled
                ? () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('select_subject'.tr),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...subjects!
                                  .map(
                                    (el) => _AlertDialogSubject(
                                      subject: el,
                                      selectedSubjectId:
                                          widget.selectedSubjectId,
                                      onChanged: widget.onChanged,
                                    ),
                                  )
                                  .toList(),
                              InkWell(
                                onTap: () async {
                                  var subject = await Get.to<Subject?>(
                                      () => const CreateSubjectPage());
                                  if (subject == null) return;

                                  Get.back();
                                  widget.onChanged(subject);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.add_circle_outline),
                                      const SizedBox(width: 10),
                                      Text(
                                        'cs_title'.tr,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                : null,
            left: Text('subject_colon'.tr),
            right: Text(
              widget.selectedSubjectId == null
                  ? 'select_subject'.tr
                  : subjects!
                          .firstWhereOrNull(
                              (el) => el.id == widget.selectedSubjectId)
                          ?.name ??
                      'select_subject'.tr,
              style: widget.selectedSubjectId == null
                  ? Theme.of(context)
                      .textTheme
                      .caption
                      ?.copyWith(fontStyle: FontStyle.italic)
                  : Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: subjects!
                            .firstWhereOrNull(
                                (s) => s.id == widget.selectedSubjectId)
                            ?.color,
                      ),
            ),
          );
  }
}

class _AlertDialogSubject extends StatelessWidget {
  const _AlertDialogSubject({
    Key? key,
    required this.subject,
    required this.selectedSubjectId,
    required this.onChanged,
  }) : super(key: key);

  final Subject subject;
  final String? selectedSubjectId;
  final void Function(Subject) onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.back();
        onChanged(subject);
      },
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                subject.name,
                style:
                    selectedSubjectId != null && subject.id == selectedSubjectId
                        ? Theme.of(context).textTheme.bodyText1
                        : Theme.of(context).textTheme.bodyText2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: subject.color,
              borderRadius: BorderRadius.circular(5),
            ),
            height: 25,
            width: 25,
          )
        ],
      ),
    );
  }
}
