import 'dart:io';

import 'package:flutter/material.dart';
import 'package:school_app/drawing/line.dart';

class Drawing {
  late final List<Line> lines;

  Drawing({List<Line>? lines}) {
    this.lines = lines ?? [];
  }

  void addPoint(double x, double y) => lines.last.addPoint(x, y);

  static Future<Drawing> fromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return Drawing();
    var contents = await file.readAsString();
    if (contents.isEmpty) return Drawing();

    List<Line> lines = [];
    for (final line in contents.split('\n')) {
      if (line.isEmpty) continue;
      lines.add(Line.fromString(line));
    }

    return Drawing(lines: lines);
  }

  @override
  String toString() {
    var string = "";
    for (final line in lines) {
      string += '$line\n';
    }
    return string;
  }
}

class DrawerState {
  Drawing drawing;
  Color activeColor = Colors.black;

  void setActiveColor(Color color) => activeColor = color;

  void newLine() => drawing.lines.add(Line(color: activeColor));

  void addPoint(double x, double y) {
    if (x < 0 || y < 0) return;
    drawing.addPoint(x, y);
  }

  void addPointOffset(Offset offset) => addPoint(offset.dx, offset.dy);

  DrawerState({
    required this.drawing,
    Color? activeColor,
  }) {
    if (activeColor != null) this.activeColor = activeColor;
  }
}
