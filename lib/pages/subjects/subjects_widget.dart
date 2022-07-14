import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/pages/subjects/create_subject_page.dart';
import 'package:school_app/pages/subjects/subject_notes_dialog.dart';
import 'package:school_app/pages/subjects/subject_page.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

import '../../data/subject.dart';
import '../home/footer.dart';

class SubjectsWidget extends StatefulWidget {
  const SubjectsWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<SubjectsWidget> createState() => _SubjectsWidgetState();
}

class _SubjectsWidgetState extends State<SubjectsWidget> {
  List<Subject> subjects = [];
  late StreamSubscription<List<Subject>> subscription;

  @override
  void initState() {
    super.initState();
    subscription = Database.I
        .querySubjects()
        .listen((data) => setState(() => subjects = data));
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
        children: [
          Expanded(
            child: subjects.isNotEmpty
                ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen(context) ? 3 : 4,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (ctx, i) => _Subject(subject: subjects[i]),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('no_subjects'.tr,
                          style: Theme.of(context).textTheme.headline5),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'cs_start'.tr,
                                style: Theme.of(context).textTheme.bodyMedium),
                            const WidgetSpan(child: Icon(Icons.add, size: 20)),
                            TextSpan(
                                text: 'cs_end'.tr,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Footer(
            text: 'subjects'.tr,
            onClick: () => Get.to(() => const CreateSubjectPage()),
          ),
        ],
      ),
    );
  }
}

class _Subject extends StatefulWidget {
  const _Subject({
    Key? key,
    required this.subject,
  }) : super(key: key);

  final Subject subject;

  @override
  State<_Subject> createState() => _SubjectState();
}

class _SubjectState extends State<_Subject> {
  var enabled = true;

  @override
  Widget build(BuildContext context) {
    print(
        "subject: ${widget.subject.name}, tasks: ${widget.subject.taskCount}");
    return LongPressPopupMenu(
      onTap: () => Get.to(() => SubjectPage(subjectId: widget.subject.id)),
      enabled: enabled,
      items: [
        PopupMenuItem(
          value: 0,
          child: Text('notes'.tr),
        ),
        PopupMenuItem(
          value: 1,
          child: Text('edit'.tr),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('delete'.tr),
        ),
      ],
      functions: [
            () => showDialog(
          context: context,
          builder: (context) => SubjectNotesDialog(
            notes: widget.subject.notes,
            subjectId: widget.subject.id,
          ),
        ),
            () => Get.to(() => CreateSubjectPage(subjectToEdit: widget.subject)),
            () => showConfirmationDialog(
          context: context,
          title: 'delete'.tr,
          content: 'confirm_delete_subject'
              .trParams({'name': widget.subject.name}),
          cancelText: 'cancel_caps'.tr,
          confirmText: 'delete_caps'.tr,
          onConfirm: () => Database.I.deleteSubject(widget.subject.id),
        )
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: !enabled ? Theme.of(context).disabledColor : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              color: widget.subject.color,
              size: 40,
            ),
            SizedBox(height: isSmallScreen(context) ? 10 : 20),
            Text(
              widget.subject.name,
              style: isSmallScreen(context)
                  ? Theme.of(context).textTheme.bodyLarge
                  : Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen(context) ? 5 : 10),
            Text(
                '${widget.subject.taskCount} '
                '(+ ${widget.subject.completedTasksCount}) '
                '${'task'.trPlural('tasks', widget.subject.taskCount)}',
                style: Theme.of(context).textTheme.caption),
          ],
        ),
      ),
    );
  }
}
