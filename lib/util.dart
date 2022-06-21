import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Helper for validating user input in login + sign up forms.
/// (email & password)
class InputValidator {
  static String? validateEmail(String? email) {
    if (email == null || !EmailValidator.validate(email)) {
      return 'Bitte gib eine gültige Email-Adresse an';
    }

    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Bitte gib ein Passwort an';
    } else if (password.length < 6) {
      return 'Das Passwort muss mindestens 6 Zeichen lang sein';
    }

    return null;
  }

  static String? validateNotEmpty(String? s) {
    if (s == null || s.isEmpty) {
      return 'Darf nicht leer sein';
    }

    return null;
  }
}

InputDecoration buildInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    alignLabelWithHint: true,
  );
}

Color randomColor() =>
    Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

bool validateForm(GlobalKey key) {
  var formState = (key as GlobalKey<FormState>).currentState;
  return formState != null && formState.validate();
}

Future<void> showPopupMenu(
    {required BuildContext context,
    required List<PopupMenuEntry<int>> items,
    required Offset longPressPosition,
    List<void Function()>? functions}) async {
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

  var selected = await showMenu(
    context: context,
    items: items,
    position: RelativeRect.fromRect(
      longPressPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
  );

  if (selected == null) return;
  if (functions == null) return;
  if (functions.length <= selected) return;
  functions[selected]();
}

class LongPressPopupMenu extends StatefulWidget {
  const LongPressPopupMenu({
    Key? key,
    this.enabled,
    required this.child,
    required this.items,
    required this.functions,
    this.onTap,
  }) : super(key: key);

  final bool? enabled;
  final Widget child;

  /// Functions to call after a menu item has been pressed.
  /// Useful when trying to navigate to another screen, since after the item's
  /// `onTap`, a route will be popped for the popup menu.
  /// Set the value of the corresponding popup item of the function to the
  /// index of the function in this array.
  final List<void Function()> functions;
  final List<PopupMenuEntry<int>> items;

  final void Function()? onTap;

  @override
  State<LongPressPopupMenu> createState() => _LongPressPopupMenuState();
}

class _LongPressPopupMenuState extends State<LongPressPopupMenu> {
  late Offset longPressPosition;

  Future<void> showPopup() async {
    await showPopupMenu(
      context: context,
      items: widget.items,
      longPressPosition: longPressPosition,
      functions: widget.functions,
    );
  }

  bool isEnabled() => widget.enabled == null ? true : widget.enabled!;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onTapDown: isEnabled()
          ? (details) => longPressPosition = details.globalPosition
          : null,
      onLongPress: isEnabled() ? showPopup : null,
      child: widget.child,
    );
  }
}

void showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmText,
  required String cancelText,
  required void Function() onConfirm,
}) =>
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

String formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

extension Date on DateTime {
  DateTime get date => DateTime(year, month, day);
}

class PasswordTextFormField extends StatefulWidget {
  const PasswordTextFormField({
    Key? key,
    this.enabled = true,
    this.labelText = 'Passwort',
    this.validator = InputValidator.validatePassword,
    required this.onChanged,
  }) : super(key: key);

  final bool enabled;
  final String labelText;
  final void Function(String) onChanged;
  final String? Function(String?)? validator;

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enabled: widget.enabled,
      keyboardType: TextInputType.visiblePassword,
      onChanged: widget.onChanged,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        alignLabelWithHint: true,
        suffixIcon: IconButton(
          onPressed: () => setState(() => obscureText = !obscureText),
          icon: Icon(!obscureText ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      obscureText: obscureText,
    );
  }
}
