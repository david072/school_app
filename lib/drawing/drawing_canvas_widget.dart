import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:school_app/drawing/drawing_painter.dart';
import 'package:school_app/drawing/drawing_state.dart';
import 'package:school_app/util.dart';

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    Key? key,
    required this.state,
    this.onScaleChanged,
  }) : super(key: key);

  final DrawerState state;
  final void Function(double)? onScaleChanged;

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas>
    with AfterLayoutMixin<DrawingCanvas> {
  final GlobalKey canvasKey = GlobalKey();

  final transformationController = TransformationController();

  int pointersOnScreen = 0;

  DrawerState get state => widget.state;

  double width = 0;
  double height = 0;

  Timer? hoverTimer;

  /// Returns current [InteractiveViewer] scale in the range [[0, 1]]
  double get scale {
    var s = transformationController.value.getMaxScaleOnAxis();
    return mapInRange(s, DrawerState.minScale, DrawerState.maxScale, 0, 1);
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    print(MediaQuery.of(context).devicePixelRatio * 160);
    width = 3508 / MediaQuery.of(context).devicePixelRatio;
    height = 2480 / MediaQuery.of(context).devicePixelRatio;
    setState(() {});
  }

  bool allowEvent(PointerEvent e) {
    if (state.allowFingerDrawing) return true;
    return e.kind == PointerDeviceKind.stylus;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        if (!allowEvent(e)) return;
        state.pointerPosition = e.localPosition;
      },
      onPointerMove: (e) {
        if (!allowEvent(e)) return;
        state.pointerPosition = e.localPosition;
      },
      onPointerHover: (e) {
        if (e.distance <= 10000 && e.distance != 0) {
          state.hovering = true;
          state.pointerPosition = e.localPosition;
        } else {
          state.hovering = false;
          state.pointerPosition = null;
        }
        setState(() {});

        print('hover: ${e.kind}, ${e.buttons == kPrimaryStylusButton}, '
            '${e.distance}, max: ${e.distanceMax}, min: ${e.distanceMin}');

        // TODO: THIS IS AN AWFUL HACK :)
        hoverTimer?.cancel();
        hoverTimer = Timer(const Duration(milliseconds: 80), () {
          setState(() => state.pointerPosition = null);
        });
      },
      child: CustomPaint(
        foregroundPainter: DrawingUIPainter(state: widget.state),
        child: InteractiveViewer(
          transformationController: transformationController,
          onInteractionUpdate: (_) {
            // widget.onScaleChanged?.call(scale / 6);
          },
          onInteractionEnd: (details) {
            // reset scale
            // transformationController.value = Matrix4.identity();
            print(scale);
            // widget.onScaleChanged?.call(scale / 6);
            setState(() {});
          },
          panEnabled: false,
          minScale: DrawerState.minScale,
          maxScale: DrawerState.maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Listener(
            onPointerDown: (e) {
              pointersOnScreen++;
              if (e.device > 0) {
                setState(() => state.discardLine());
                return;
              }
              if (!allowEvent(e)) return;

              state.pointerPosition = e.localPosition;

              print('down: ${e.device}, ${e.kind}');
              if (state.penType != PenType.eraser) {
                state.newLine();
              }
              setState(() {});
            },
            onPointerMove: (e) {
              if (pointersOnScreen > 1) return;
              if (!allowEvent(e)) return;

              RenderBox box =
                  canvasKey.currentContext!.findRenderObject()! as RenderBox;
              if (e.localPosition.dx > box.size.width ||
                  e.localPosition.dy > box.size.height) {
                return;
              }

              if (state.penType == PenType.pen) {
                setState(() => state.addPointFromOffset(e.localPosition));
              } else {
                setState(() => state.eraseAt(e.localPosition));
              }
            },
            onPointerUp: (e) {
              print("up");
              pointersOnScreen--;
              state.finishLine();
            },
            child: Container(
              key: canvasKey,
              color: Colors.white,
              width: width,
              height: height,
              child: CustomPaint(
                  painter: DrawingPainter(
                state: state,
              )),
            ),
          ),
        ),
      ),
    );
  }
}
