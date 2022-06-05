import 'dart:math';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

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

class LongPressPopupMenu extends StatefulWidget {
  const LongPressPopupMenu({
    Key? key,
    required this.enabled,
    required this.child,
    required this.items,
  }) : super(key: key);

  final bool? enabled;
  final Widget child;
  final List<PopupMenuEntry> items;

  @override
  State<LongPressPopupMenu> createState() => _LongPressPopupMenuState();
}

class _LongPressPopupMenuState extends State<LongPressPopupMenu> {
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
      items: widget.items,
      position: RelativeRect.fromRect(
        longPressPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
    );
  }

  bool isEnabled() => widget.enabled == null ? true : widget.enabled!;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: isEnabled()
          ? (details) => longPressPosition = details.globalPosition
          : null,
      onLongPress: isEnabled() ? showPopupMenu : null,
      child: widget.child,
    );
  }
}
