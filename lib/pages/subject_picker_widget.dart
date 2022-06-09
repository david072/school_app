import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/pages/tasks/clickable_row.dart';

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
  late StreamSubscription<List<Subject>> subscription;

  @override
  void initState() {
    super.initState();
    getSubjects();
  }

  // For some reason, stream.first apparently does not work properly on
  // generator functions, so I have to do it myself.
  void getSubjects() {
    subscription = Database.I.querySubjects().listen((data) {
      setState(() => subjects = data);
      subscription.cancel();
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
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
                        title: const Text('Fach auswählen'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: subjects!
                                .map(
                                  (el) => _AlertDialogSubject(
                                    subject: el,
                                    selectedSubjectId: widget.selectedSubjectId,
                                    onChanged: widget.onChanged,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    )
                : null,
            left: const Text('Fach:'),
            right: Text(
              widget.selectedSubjectId == null
                  ? 'Fach auswählen'
                  : subjects!
                      .firstWhere((el) => el.id == widget.selectedSubjectId)
                      .name,
              style: widget.selectedSubjectId == null
                  ? Theme.of(context)
                      .textTheme
                      .caption
                      ?.copyWith(fontStyle: FontStyle.italic)
                  : Theme.of(context).textTheme.bodyLarge,
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
        Navigator.pop(context);
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
