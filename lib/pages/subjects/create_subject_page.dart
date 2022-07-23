import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/pages/tasks/view_task_widgets.dart';
import 'package:school_app/util/sizes.dart';
import 'package:school_app/util/util.dart';

import '../../data/subject.dart';

class CreateSubjectPage extends StatefulWidget {
  const CreateSubjectPage({
    Key? key,
    this.initialData,
    this.editMode = false,
  }) : super(key: key);

  /// Optional subject. If not null, the screen will edit instead of create.
  final Subject? initialData;
  final bool editMode;

  @override
  State<CreateSubjectPage> createState() => _CreateSubjectPageState();
}

class _CreateSubjectPageState extends State<CreateSubjectPage> {
  final GlobalKey formKey = GlobalKey<FormState>();

  var enabled = true;

  late String name;
  late String abbreviation;
  late Color color;

  @override
  void initState() {
    super.initState();
    name = widget.initialData?.name ?? "";
    abbreviation = widget.initialData?.abbreviation ?? "";
    color = widget.initialData?.color ?? randomColor();
  }

  Future<void> createSubject() async {
    setState(() => enabled = false);

    if (!validateForm(formKey)) {
      setState(() => enabled = true);
      return;
    }

    Subject? createdSubject;
    if (!widget.editMode) {
      var id = await Database.I
          .createSubject(Subject.data(name, abbreviation, color));
      createdSubject = Subject.data(name, abbreviation, color, id);
    } else {
      Database.I.editSubject(
          Subject.data(name, abbreviation, color, widget.initialData!.id));
    }

    Get.back(result: createdSubject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(!widget.editMode ? 'cs_title'.tr : 'es_title'.tr),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: formWidth(context),
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
                          initialValue: widget.initialData?.name,
                          enabled: enabled,
                          decoration: buildInputDecoration('name'.tr),
                          onChanged: (s) => name = s,
                          validator: InputValidator.validateNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 1,
                        child: TextFormField(
                          initialValue: widget.initialData?.abbreviation,
                          enabled: enabled,
                          decoration: buildInputDecoration('abbreviation'.tr),
                          onChanged: (s) => abbreviation = s,
                          validator: InputValidator.validateNotEmpty,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ClickableRow(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _ColorPicker(
                        color: color,
                        onColorChanged: (c) => setState(() => color = c),
                      ),
                    ),
                    left: Text('color'.tr),
                    right: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  MaterialButton(
                    onPressed: enabled ? createSubject : null,
                    minWidth: double.infinity,
                    color: Theme.of(context).colorScheme.primary,
                    child: enabled
                        ? Text(
                            !widget.editMode
                                ? 'create_caps'.tr
                                : 'save_caps'.tr,
                          )
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

class _ColorPicker extends StatefulWidget {
  const _ColorPicker({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  final Color color;
  final void Function(Color) onColorChanged;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    pickerColor = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('color_picker_title'.tr),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: pickerColor,
          onColorChanged: (color) => setState(() => pickerColor = color),
          enableAlpha: false,
        ),
      ),
      actions: [
        TextButton(
          child: Text('cancel_caps'.tr),
          onPressed: () => Get.back(),
        ),
        TextButton(
          child: Text('confirm_caps'.tr),
          onPressed: () {
            widget.onColorChanged(pickerColor);
            Get.back();
          },
        ),
      ],
    );
  }
}
