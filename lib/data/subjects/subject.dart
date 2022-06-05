import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String abbreviation;
  final Color color;

  const Subject(this.id, this.name, this.abbreviation, this.color);

  static Subject fromDocument(QueryDocumentSnapshot<Map> doc) {
    var data = doc.data();
    return Subject(
      doc.id,
      data['name'],
      data['abbreviation'],
      Color(data['color']),
    );
  }
}
