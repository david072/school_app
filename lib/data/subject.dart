import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String abbreviation;
  final Color color;

  const Subject(this.id, this.name, this.abbreviation, this.color);

  static Subject fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.id, doc.data()!);
  }

  static Subject fromRow(Map<String, dynamic> row) {
    return _fromMap(row['id'].toString(), row);
  }

  static Subject _fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id,
      map['name'],
      map['abbreviation'],
      Color(map['color']),
    );
  }
}
