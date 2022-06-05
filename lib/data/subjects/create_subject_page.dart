import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database.dart';
import 'package:school_app/util.dart';

import 'subject.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({
    Key? key,
    this.subjectToEdit,
  }) : super(key: key);

  /// Optional subject. If not null, the screen will edit instead of create.
  final Subject? subjectToEdit;

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectPageState();
}

class _CreateSubjectPageState extends State<CreateSubjectPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true.obs;

  late String name;
  late String abbreviation;
  late Color color;

  @override
  void initState() {
    super.initState();
    name = widget.subjectToEdit?.name ?? "";
    abbreviation = widget.subjectToEdit?.abbreviation ?? "";
    color = widget.subjectToEdit?.color ?? randomColor();
  }

  void createSubject() async {
    enabled.call(false);

    if (!validateForm(formKey)) {
      enabled.call(true);
      return;
    }

    if (widget.subjectToEdit == null) {
      await Database.createSubject(name, abbreviation, color);
    } else {
      await Database.editSubject(
          widget.subjectToEdit!.id, name, abbreviation, color);
    }

    enabled.call(true);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectToEdit == null
            ? 'Fach erstellen'
            : 'Fach bearbeiten'),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        initialValue: widget.subjectToEdit?.name,
                        enabled: enabled.value,
                        decoration: buildInputDecoration('Name'),
                        onChanged: (s) => name = s,
                        validator: InputValidator.validateNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      flex: 1,
                      child: TextFormField(
                        initialValue: widget.subjectToEdit?.abbreviation,
                        enabled: enabled.value,
                        decoration: buildInputDecoration('Abkürzung'),
                        onChanged: (s) => abbreviation = s,
                        validator: InputValidator.validateNotEmpty,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _ColorPicker(
                      color: color,
                      onColorChanged: (c) => setState(() => color = c),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      children: [
                        const Text('Farbe'),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                MaterialButton(
                  onPressed: enabled.value ? createSubject : null,
                  minWidth: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  child: enabled.value
                      ? Text(widget.subjectToEdit == null
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

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  final Color color;
  final void Function(Color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Wähle eine Farbe'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: color,
          onColorChanged: onColorChanged,
          enableAlpha: false,
        ),
      ),
    );
  }
}
