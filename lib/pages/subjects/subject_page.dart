import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/pages/subjects/create_subject_page.dart';
import 'package:school_app/pages/subjects/subject_notes_dialog.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';
import 'package:school_app/util/util.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({
    Key? key,
    required this.subjectId,
  }) : super(key: key);

  final String subjectId;

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  late StreamSubscription<Subject> subscription;

  Subject? subject;
  late Color appBarContentColor;

  @override
  void initState() {
    super.initState();
    subscription =
        Database.I.querySubject(widget.subjectId).listen((s) => setState(() {
              subject = s;
              appBarContentColor = subject!.color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white;
            }));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return subject != null
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                '${subject!.name} (${subject!.abbreviation})',
                style: TextStyle(color: appBarContentColor),
              ),
              iconTheme: IconThemeData(color: appBarContentColor),
              backgroundColor: subject!.color,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notes),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => SubjectNotesDialog(
                      notes: subject!.notes,
                      subjectId: subject!.id,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Get.to(() => CreateSubjectPage(
                        initialData: subject!,
                        editMode: true,
                      )),
                ),
                IconButton(
                  onPressed: () => showConfirmationDialog(
                    context: context,
                    title: 'delete'.tr,
                    content: 'confirm_delete_subject'
                        .trParams({'name': subject!.name}),
                    cancelText: 'cancel_caps'.tr,
                    confirmText: 'delete_caps'.tr,
                    onConfirm: () {
                      Database.I.deleteSubject(subject!.id);
                      Get.back();
                    },
                  ),
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            body: Row(
              children: [
                TaskListWidget(subjectFilter: subject!),
              ],
            ),
          )
        : const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
  }
}
