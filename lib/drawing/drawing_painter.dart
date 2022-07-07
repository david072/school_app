import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:school_app/drawing/drawing_state.dart';

class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.state,
  });

  final DrawerState state;

  @override
  void paint(Canvas canvas, Size size) async {
    var paint = Paint();

    for (var line in state.lines) {
      paint.color = line.color;

      final outlinePoints = getStroke(line.points,
          simulatePressure: false, size: state.thickness);
      final path = Path();

      if (outlinePoints.isEmpty) {
        continue;
      } else if (outlinePoints.length < 2) {
        // Only one point
        path.addOval(Rect.fromCircle(
            center: Offset(outlinePoints[0].x, outlinePoints[0].y),
            radius: state.thickness));
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

class DrawingUIPainter extends CustomPainter {
  const DrawingUIPainter({required this.state});

  final DrawerState state;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.pointerPosition == null) return;

    var paint = Paint()..color = state.activeColor;

    switch (state.penType) {
      case PenType.pen:
        if (!state.hovering) break;

        var icon = (state.penType.getIcon() as Icon).icon!;
        var painter = TextPainter(textDirection: TextDirection.rtl)
          ..text = TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 20,
              fontFamily: icon.fontFamily!,
              color: Colors.black,
            ),
          );
        painter.layout();
        painter.paint(canvas, state.pointerPosition!);

        canvas.drawCircle(state.pointerPosition!, state.thickness - 2, paint);
        break;
      case PenType.eraser:
        // WHY THIS MADNESS FOR DRAWING AN SVG TO THE CANVAS AAAAAAAAH
        var svgRoot = state.eraserSvgRoot;
        var desiredSize = const Size(20, 20);
        canvas.save();
        canvas.translate(state.pointerPosition!.dx, state.pointerPosition!.dy);
        var svgSize = svgRoot.viewport.size;
        var matrix = Matrix4.identity();
        matrix.scale(desiredSize.width / svgSize.width,
            desiredSize.height / svgSize.height);
        canvas.transform(matrix.storage);
        svgRoot.draw(canvas, Rect.zero);
        canvas.restore();

        paint.style = PaintingStyle.stroke;
        canvas.drawCircle(
            state.pointerPosition!, state.eraserThickness - 2, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
