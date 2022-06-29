import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';

class SubjectNotesDialog extends StatefulWidget {
  const SubjectNotesDialog({
    Key? key,
    required this.notes,
    required this.subjectId,
  }) : super(key: key);

  final String notes;
  final String subjectId;

  @override
  State<SubjectNotesDialog> createState() => _SubjectNotesDialogState();
}

class _SubjectNotesDialogState extends State<SubjectNotesDialog> {
  final scrollController = ScrollController();
  late String notes;

  @override
  initState() {
    super.initState();
    notes = widget.notes;
  }

  @override
  void dispose() {
    Database.I.updateSubjectNotes(widget.subjectId, notes.trim());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return AlertDialog(
      title: Text('subject_notes'.tr),
      content: SizedBox(
        width: size.width * 0.7,
        height: size.height * 0.7,
        child: Scrollbar(
          controller: scrollController,
          child: TextField(
            controller: TextEditingController(text: notes),
            scrollController: scrollController,
            onChanged: (s) => notes = s,
            decoration: InputDecoration(
              labelText: 'notes'.tr,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
            textAlignVertical: TextAlignVertical.top,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            expands: true,
          ),
        ),
      ),
    );
  }
}
