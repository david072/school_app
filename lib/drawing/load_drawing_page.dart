import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/notebook.dart';
import 'package:school_app/data/remote_storage.dart';
import 'package:school_app/drawing/drawer_page.dart';
import 'package:school_app/drawing/drawing_state.dart';
import 'package:school_app/util.dart';

class LoadDrawingPage extends StatefulWidget {
  const LoadDrawingPage({
    Key? key,
    required this.notebook,
  }) : super(key: key);

  final Notebook notebook;

  @override
  State<LoadDrawingPage> createState() => _LoadDrawingPageState();
}

class _LoadDrawingPageState extends State<LoadDrawingPage> {
  @override
  void initState() {
    super.initState();
    loadDrawing();
  }

  Future<void> loadDrawing() async {
    final path = await widget.notebook.fullFilePath();
    final file = File(path);

    if (!Database.I.hasAccount() || !await isNetworkAvailable()) {
      if (!await file.exists()) {
        await file.create(recursive: true);
      }
    } else {
      var metadata = await RemoteStorage.getMetadata(widget.notebook);
      if (metadata == null) return;

      if (!await file.exists()) {
        await RemoteStorage.download(file, widget.notebook);
      } else {
        var modified = await file.lastModified();
        if (metadata.updated != null && modified.isBefore(metadata.updated!)) {
          await RemoteStorage.download(file, widget.notebook);
        }
      }
    }

    final drawing = await Drawing.fromFile(path);
    if (!mounted) return;

    await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DrawerPage(drawing: drawing),
        ));

    // `drawing` was modified by [DrawerPage]
    var newFileContent = drawing.toString();
    await file.writeAsString(newFileContent);
    if (Database.I.hasAccount()) {
      await FirebaseStorage.instance
          .ref()
          .child(widget.notebook.filePath())
          .putFile(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
