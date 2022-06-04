import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum FailState { formValidation, login }

class Authentication {
  static Future<FailState?> signIn(
      GlobalKey<FormState> key, String email, String password) async {
    var formState = key.currentState;
    if (formState == null || !formState.validate())
      return FailState.formValidation;

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      print("auth error $e");
      return FailState.login;
    }
  }
}
