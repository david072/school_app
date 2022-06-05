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
