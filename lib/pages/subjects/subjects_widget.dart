import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/pages/subjects/create_subject_page.dart';
import 'package:school_app/pages/subjects/subject_page.dart';
import 'package:school_app/util.dart';

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
    subscription = Database.querySubjects()
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (ctx, i) => _Subject(subject: subjects[i]),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Keine Fächer',
                          style: Theme.of(context).textTheme.headline5),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Erstelle Fächer mit dem ',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const WidgetSpan(child: Icon(Icons.add, size: 20)),
                            TextSpan(
                                text: ' unten rechts.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Footer(
            displayName: 'Fächer',
            count: subjects.length,
            onAdd: () => Get.to(() => const CreateSubjectPage()),
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
    return LongPressPopupMenu(
      onTap: () => Get.to(() => SubjectPage(subjectId: widget.subject.id)),
      enabled: enabled,
      items: const [
        PopupMenuItem(
          value: 0,
          child: Text('Bearbeiten'),
        ),
        PopupMenuItem(
          value: 1,
          child: Text('Löschen'),
        ),
      ],
      functions: [
            () => Get.to(() => CreateSubjectPage(subjectToEdit: widget.subject)),
            () => showConfirmationDialog(
          context: context,
          title: 'Löschen',
          content:
          'Möchtest du das Fach \'${widget.subject.name}\' wirklich löschen?\n'
              'Dadurch werden auch alle Aufgaben mit diesem Fach gelöscht!',
          cancelText: 'Abbrechen',
          confirmText: 'Löschen',
          onConfirm: () => Database.deleteSubject(widget.subject.id),
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
            const SizedBox(height: 20),
            Text(widget.subject.name,
                style: Theme.of(context).textTheme.headline6),
            const SizedBox(height: 10),
            // TODO: Task count
            // Text('$taskCount Aufgabe${taskCount == 1 ? '' : 'n'}',
            //     style: Theme.of(context).textTheme.caption),
            Text('0 Aufgaben', style: Theme.of(context).textTheme.caption),
          ],
        ),
      ),
    );
  }
}
