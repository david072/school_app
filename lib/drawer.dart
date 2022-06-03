import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:school_app/types.dart';

// TODO: - Display something under the cursor when hovering
class DrawerState {
  Drawing drawing;
  Color activeColor = Colors.black;

  void setActiveColor(Color color) => activeColor = color;

  void newLine() => drawing.lines.add(Line(color: activeColor));

  void addPoint(double x, double y) {
    // TODO: With this approach, the two ends are being connected when entering
    //  again
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

class DrawerPainter extends CustomPainter {
  DrawerPainter({
    required this.state,
  });

  final DrawerState state;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();

    for (var line in state.drawing.lines) {
      paint.color = line.color;

      final outlinePoints = getStroke(line.points, simulatePressure: false);
      final path = Path();

      if (outlinePoints.isEmpty) {
        continue;
      } else if (outlinePoints.length < 2) {
        // Only one point
        path.addOval(Rect.fromCircle(
            center: Offset(outlinePoints[0].x, outlinePoints[0].y), radius: 1));
      } else {
        // Draw line that connects each point with a bezier curve segment
        path.moveTo(outlinePoints[0].x, outlinePoints[0].y);
        for (int i = 0; i < outlinePoints.length - 1; ++i) {
          final p0 = outlinePoints[i];
          final p1 = outlinePoints[i + 1];

          path.quadraticBezierTo(
              p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
