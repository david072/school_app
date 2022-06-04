import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum FailState { formValidation, authentication }

class Authentication {
  static Future<FailState?> signUp(
      GlobalKey<FormState> key, String email, String password) async {
    var formState = key.currentState;
    if (formState == null || !formState.validate()) {
      return FailState.formValidation;
    }

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      print('sign up error: $e');
      return FailState.authentication;
    }
  }

  static Future<FailState?> signIn(
      GlobalKey<FormState> key, String email, String password) async {
    var formState = key.currentState;
    if (formState == null || !formState.validate()) {
      return FailState.formValidation;
    }

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      print('sign in error $e');
      return FailState.authentication;
    }
  }
}

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
}

InputDecoration buildInputDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    alignLabelWithHint: true,
  );
}
