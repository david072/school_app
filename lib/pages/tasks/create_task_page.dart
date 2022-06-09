import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/subject_picker_widget.dart';
import 'package:school_app/pages/tasks/clickable_row.dart';
import 'package:school_app/util.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({
    Key? key,
    this.taskToEdit,
    this.initialSubject,
  }) : super(key: key);

  final Task? taskToEdit;
  final Subject? initialSubject;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true;

  late String title;
  late String description;
  late DateTime dueDate;
  late Subject? subject;

  late ReminderMode reminderMode;
  late Duration reminderOffset;

  @override
  void initState() {
    super.initState();

    title = widget.taskToEdit?.title ?? "";
    description = widget.taskToEdit?.description ?? "";
    dueDate = widget.taskToEdit?.dueDate ?? DateTime.now().date;
    subject = widget.taskToEdit?.subject ?? widget.initialSubject;
    reminderOffset = widget.taskToEdit != null
        ? widget.taskToEdit!.dueDate.difference(widget.taskToEdit!.reminder)
        : Duration.zero;
    reminderMode = widget.taskToEdit != null
        ? reminderModeFromOffset(reminderOffset)
        : ReminderMode.none;
  }

  void createSubject() {
    setState(() => enabled = false);

    bool isValid = true;
    if (subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte wähle ein Fach aus!')));
      isValid = false;
    }
    if (!validateForm(formKey)) {
      isValid = false;
    }

    if (!isValid) {
      setState(() => enabled = true);
      return;
    }

    if (widget.taskToEdit == null) {
      Database.I.createTask(
        title,
        description,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!.id,
      );
    } else {
      Database.I.editTask(
        widget.taskToEdit!.id,
        title,
        description,
        dueDate,
        dueDate.subtract(reminderOffset),
        subject!.id,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskToEdit == null
            ? 'Aufgabe erstellen'
            : 'Aufgabe bearbeiten'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    initialValue: widget.taskToEdit?.title,
                    enabled: enabled,
                    decoration: buildInputDecoration('Titel'),
                    onChanged: (s) => title = s,
                    validator: InputValidator.validateNotEmpty,
                  ),
                  const SizedBox(height: 40),
                  _DatePicker(
                    enabled: enabled,
                    prefix: 'Fälligkeitsdatum',
                    date: dueDate,
                    onChanged: (date) => setState(() => dueDate = date),
                  ),
                  const SizedBox(height: 20),
                  _ReminderPicker(
                    enabled: enabled,
                    mode: reminderMode,
                    reminderOffset: reminderOffset,
                    dueDate: dueDate,
                    onChanged: (offset, mode) => setState(() {
                      reminderOffset = offset;
                      reminderMode = mode;
                    }),
                  ),
                  const SizedBox(height: 20),
                  SubjectPicker(
                    enabled: enabled,
                    onChanged: (s) => setState(() => subject = s),
                    selectedSubjectId: subject?.id,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    initialValue: widget.taskToEdit?.description,
                    enabled: enabled,
                    onChanged: (s) => description = s,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Beschreibung',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  const SizedBox(height: 80),
                  MaterialButton(
                    onPressed: enabled ? createSubject : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text(widget.taskToEdit == null
                            ? 'ERSTELLEN'
                            : 'SPEICHERN')
                        : const CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  _DatePicker({
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

class _ReminderPicker extends StatelessWidget {
  const _ReminderPicker({
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
                  title: const Text('Erinnerung:'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: ReminderMode.values.map((val) {
                        if (val == ReminderMode.custom) {
                          return _DatePicker(
                            prefix: 'Benutzerdefiniert',
                            highlightPrefix: mode == val,
                            date: dueDate.subtract(reminderOffset),
                            firstDate: DateTime(DateTime.now().year - 5),
                            lastDate: dueDate,
                            onChanged: (date) {
                              var offset = dueDate.difference(date);
                              Navigator.pop(context);
                              onChanged(offset, ReminderMode.custom);
                            },
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
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
      left: const Text('Erinnerung:'),
      right: Text(
        mode != ReminderMode.custom
            ? mode.string
            : formatDate(dueDate.subtract(reminderOffset)),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
