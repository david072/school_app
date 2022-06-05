import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/data/subjects/create_subject_page.dart';

import '../data/subjects/subject.dart';

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
          _Footer(
            subjectCount: subjects.length,
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

  late Offset longPressPosition;

  void showPopupMenu() {
    final RenderBox? overlay =
        Overlay.of(context)?.context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ein unerwarteter Fehler ist aufgetreten (Error: No RenderBox found).'),
        ),
      );
      return;
    }

    showMenu(
      context: context,
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: const Text('Löschen'),
          onTap: () async {
            setState(() => enabled = false);
            await Database.deleteSubject(widget.subject.id);
          },
        )
      ],
      position: RelativeRect.fromRect(
        longPressPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: enabled
          ? (details) => longPressPosition = details.globalPosition
          : null,
      onLongPress: enabled ? showPopupMenu : null,
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

class _Footer extends StatelessWidget {
  const _Footer({
    Key? key,
    required this.subjectCount,
    required this.onAdd,
  }) : super(key: key);

  final int subjectCount;
  final void Function() onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            'Fächer: $subjectCount',
            style: Theme.of(context).textTheme.caption,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(5),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
