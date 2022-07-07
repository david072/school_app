import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

enum PenType { pen, eraser }

extension Ic on PenType {
  Widget getIcon() {
    switch (this) {
      case PenType.pen:
        return const Icon(Icons.edit);
      case PenType.eraser:
        return SvgPicture.asset('assets/eraser.svg');
    }
  }
}

enum EraserMode { points, lines }

class DrawerState {
  static const double minScale = 0.1;
  static const double maxScale = 6;

  DrawerState({required this.drawing, required this.eraserSvgRoot});

  Drawing drawing;
  Line? currentLine;

  Color activeColor = Colors.black;
  double thickness = 5;
  PenType penType = PenType.pen;

  EraserMode eraserMode = EraserMode.points;
  double eraserThickness = 5;

  bool hovering = false;
  Offset? pointerPosition;

  bool allowFingerDrawing = true;

  DrawableRoot eraserSvgRoot;

  static Future<DrawerState> init(Drawing drawing) async {
    var rawSvg = await rootBundle.loadString('assets/eraser.svg');
    var eraserSvgRoot = await svg.fromSvgString(rawSvg, rawSvg);
    return DrawerState(drawing: drawing, eraserSvgRoot: eraserSvgRoot);
  }

  void newLine([Offset? firstPoint]) {
    finishLine();
    currentLine = Line(color: activeColor);
    if (firstPoint != null) addPointFromOffset(firstPoint);
  }

  void finishLine() {
    if (currentLine == null) return;
    drawing.lines.add(currentLine!);
    currentLine = null;
  }

  void discardLine() {
    currentLine = null;
  }

  void addPoint(double x, double y) {
    if (x < 0 || y < 0) return;
    if (currentLine == null) return;
    currentLine!.addPoint(x, y);
  }

  void addPointFromOffset(Offset offset) => addPoint(offset.dx, offset.dy);

  void eraseAt(Offset center) {
    for (int i = 0; i < drawing.lines.length; i++) {
      final line = drawing.lines[i];
      for (int j = 0; j < line.points.length; j++) {
        final point = line.points[j];
        final a = center.dx - point.x;
        final b = center.dy - point.y;
        final distSquared = pow(a, 2) + pow(b, 2);

        if (distSquared > pow(eraserThickness, 2)) {
          continue;
        }

        if (eraserMode == EraserMode.points) {
          final leftHalf = line.points.sublist(0, j);
          final rightHalf = line.points.sublist(j + 1);
          drawing.lines[i] = Line(color: line.color, points: leftHalf);
          drawing.lines.add(Line(color: line.color, points: rightHalf));
        }
        else if (eraserMode == EraserMode.lines) {
          drawing.lines.removeAt(i);
          i--;
        }
        break;
      }
    }

    for (int i = 0; i < drawing.lines.length; i++) {
      if (drawing.lines[i].points.isEmpty) {
        drawing.lines.removeAt(i);
      }
    }
  }

  List<Line> get lines {
    var list = [...drawing.lines];
    if (currentLine != null) list.add(currentLine!);
    return list;
  }
}
