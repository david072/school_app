import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

export 'package:perfect_freehand/src/point.dart';

// TODO: Pressure, edit color
class Line {
  final List<Point> _points = [];
  final Color color;

  Line({
    required this.color,
  });

  void addPoint(double x, double y) {
    _points.add(Point(x, y));
  }

  List<Point> get points => _points;
}

// TODO: Load / Save to file
class Drawing {
  final List<Line> _lines = [];

  void addPoint(double x, double y) => _lines.last.addPoint(x, y);

  List<Line> get lines => _lines;
}
