import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './subjects/subject.dart';

class Database {
  static const _subjectsCollection = 'subjects';

  static Stream<List<Subject>> querySubjects() async* {
    // TODO: Query / store task count
    var subjects = FirebaseFirestore.instance
        .collection(_subjectsCollection)
        .where('user_id', isEqualTo: _requireUser().uid)
        .snapshots();

    await for (final docs in subjects) {
      yield docs.docs.map(Subject.fromDocument).toList();
    }
  }

  static Future<void> createSubject(
      String name, String abbreviation, Color color) async {
    await FirebaseFirestore.instance.collection(_subjectsCollection).add({
      'name': name,
      'abbreviation': abbreviation,
      'color': color.value,
      'user_id': _requireUser().uid,
    });
  }

  static Future<void> deleteSubject(String id) async {
    var doc =
        FirebaseFirestore.instance.collection(_subjectsCollection).doc(id);
    await doc.delete();
  }

  static User _requireUser() {
    var user = FirebaseAuth.instance.currentUser;
    assert(user != null, 'User required for operation!');
    return user!;
  }
}
