import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:school_app/data/notebook.dart';
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
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDir.path, widget.notebook.subject.id,
        '${widget.notebook.id}.sanote');
    final file = File(path);

    // TEMP!
    // if (!Database.I.hasAccount() || !await isNetworkAvailable()) {
    if (true) {
      // Load local file
      if (!await file.exists()) {
        await file.create(recursive: true);

        var string = "";
        for (int i = 0; i < 100; i++) {
          string += '$i;$i|';
        }
        string += randomColor().value.toString();
        await file.writeAsString(string);
      }
    } else {
      // Download from Firebase Storage
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
