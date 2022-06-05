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
    this.enabled,
    required this.child,
    required this.items,
    required this.functions,
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

  @override
  State<LongPressPopupMenu> createState() => _LongPressPopupMenuState();
}

class _LongPressPopupMenuState extends State<LongPressPopupMenu> {
  late Offset longPressPosition;

  Future<void> showPopupMenu() async {
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

    int? selected = await showMenu(
      context: context,
      items: widget.items,
      position: RelativeRect.fromRect(
        longPressPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
    );

    if (selected == null) return;
    if (widget.functions.length <= selected) return;
    widget.functions[selected]();
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
