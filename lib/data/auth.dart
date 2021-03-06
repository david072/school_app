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

  static Future<String?> reauthenticate(String password) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'No user';

    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: user.email!, password: password);
    } on FirebaseAuthException catch (e) {
      print("reauthenticate error: $e");
      return e.code;
    }

    return null;
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

  static Future<String?> updatePassword(
      String oldPassword, String newPassword) async {
    try {
      var reauthenticateResult = await reauthenticate(oldPassword);
      if (reauthenticateResult != null) return reauthenticateResult;

      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      print("update password error: $e");
      return e.code;
    }
  }

  static Future<String?> deleteUser() async {
    try {
      await FirebaseAuth.instance.currentUser!.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      print("delete user error: $e");
      return e.code;
    }
  }
}
