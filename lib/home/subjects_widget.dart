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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              itemCount: subjects.length,
              itemBuilder: (ctx, i) => _Subject(
                name: subjects[i].name,
                color: subjects[i].color,
                taskCount: 0, // TODO!
              ),
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

class _Subject extends StatelessWidget {
  const _Subject({
    Key? key,
    required this.name,
    required this.color,
    required this.taskCount,
  }) : super(key: key);

  final String name;
  final Color color;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.book_outlined,
          color: color,
          size: 40,
        ),
        const SizedBox(height: 20),
        Text(name, style: Theme.of(context).textTheme.headline6),
        const SizedBox(height: 10),
        Text('$taskCount Aufgabe${taskCount == 1 ? '' : 'n'}',
            style: Theme.of(context).textTheme.caption),
      ],
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
