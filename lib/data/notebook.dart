import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/subject.dart';

class Notebook {
  final String id;
  final String name;
  final Subject subject;

  const Notebook(this.id, this.name, this.subject);

  Future<String> fullFilePath() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, filePath());
  }

  String filePath() => join(subject.id, '$id.sanote');

  static Future<Notebook> fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    return _fromMap(doc.id, doc.data()!);
  }

  static Future<Notebook> fromRow(Map<String, dynamic> row) {
    return _fromMap(row['id'].toString(), row);
  }

  static Future<Notebook> _fromMap(String id, Map<String, dynamic> map) async {
    return Notebook(
      id,
      map['name'],
      await Database.I.querySubjectOnce(map['subject_id'].toString()),
    );
  }
}
