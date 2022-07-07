import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

export 'package:perfect_freehand/src/point.dart';

// TODO: Pressure, edit color
class Line {
  late List<Point> points;
  final Color color;

  Line({required this.color, List<Point>? points}) {
    this.points = points ?? [];
  }

  void addPoint(double x, double y) {
    points.add(Point(x, y));
  }

  static Line fromString(String lineString) {
    var pointParts = lineString.split('|');
    List<Point> points = [];
    for (int i = 0; i < pointParts.length - 1; i++) {
      var parts = pointParts[i].split(';');
      var x = double.parse(parts[0]);
      var y = double.parse(parts[1]);
      points.add(Point(x, y));
    }

    var color = Color(int.parse(pointParts.last));
    return Line(color: color, points: points);
  }

  @override
  String toString() {
    var result = "";
    for (int i = 0; i < points.length; i++) {
      var point = points[i];
      result += '${point.x};${point.y}|';
    }

    return result + color.value.toString();
  }
}
