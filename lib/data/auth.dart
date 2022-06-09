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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      return null;
    } catch (e) {
      print('sign in error $e');
      return FailState.authentication;
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      print("send password reset error: $e");
      return e.code;
    }
  }
}
