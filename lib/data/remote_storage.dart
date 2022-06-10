import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:school_app/data/notebook.dart';

class RemoteStorage {
  static Future<FullMetadata?> getMetadata(Notebook notebook) async {
    var ref = _notebookReference(notebook);
    try {
      return await ref.getMetadata();
    } catch (_) {
      return null;
    }
  }

  static Future<void> download(File file, Notebook notebook) async {
    var ref = _notebookReference(notebook);
    if (!await _exists(ref)) return;

    if (!await file.exists()) file.create(recursive: true);
    await ref.writeToFile(file);
  }

  static Future<void> delete(Notebook notebook) async {
    var ref = _notebookReference(notebook);
    if (!await _exists(ref)) return;
    await ref.delete();
  }

  /// There is no `.exists()` function on a reference, so we have to use this
  /// workaround.
  static Future<bool> _exists(Reference reference) async {
    try {
      await reference.getDownloadURL();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Reference _notebookReference(Notebook notebook) =>
      FirebaseStorage.instance.ref().child(notebook.filePath());
}
