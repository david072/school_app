import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/notebook.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/pages/subject_picker_widget.dart';
import 'package:school_app/util.dart';

class CreateNotebookPage extends StatefulWidget {
  const CreateNotebookPage({
    Key? key,
    this.notebookToEdit,
  }) : super(key: key);

  final Notebook? notebookToEdit;

  @override
  State<CreateNotebookPage> createState() => _CreateNotebookPageState();
}

class _CreateNotebookPageState extends State<CreateNotebookPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true;

  late String name;
  late Subject? subject;

  @override
  void initState() {
    super.initState();
    name = widget.notebookToEdit?.name ?? "";
    subject = widget.notebookToEdit?.subject;
  }

  void createSubject() {
    setState(() => enabled = false);

    bool isValid = true;
    if (subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle ein Fach aus!')),
      );
      isValid = false;
    }
    if (!validateForm(formKey)) {
      isValid = false;
    }

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    if (widget.notebookToEdit == null) {
      Database.I.createNotebook(name, subject!.id);
    } else {
      Database.I.editNotebook(widget.notebookToEdit!.id, name, subject!.id);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebookToEdit == null
            ? 'Heft erstellen'
            : 'Heft bearbeiten'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  initialValue: widget.notebookToEdit?.name,
                  enabled: enabled,
                  decoration: buildInputDecoration('Name'),
                  onChanged: (s) => name = s,
                  validator: InputValidator.validateNotEmpty,
                ),
                const SizedBox(height: 40),
                SubjectPicker(
                  enabled: enabled,
                  onChanged: (s) => setState(() => subject = s),
                  selectedSubjectId: subject?.id,
                ),
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: enabled ? createSubject : null,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: enabled
                      ? Text(widget.notebookToEdit == null
                          ? 'ERSTELLEN'
                          : 'SPEICHERN')
                      : const CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
