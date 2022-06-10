import 'package:flutter/material.dart';
import 'package:school_app/drawing/drawing_painter.dart';
import 'package:school_app/drawing/drawing_state.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({
    Key? key,
    this.drawing,
  }) : super(key: key);

  final Drawing? drawing;

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

// TODO: Use InteractiveViewer or something for panning
class _DrawerPageState extends State<DrawerPage> {
  late DrawerState state;

  @override
  void initState() {
    super.initState();
    state = DrawerState(drawing: widget.drawing ?? Drawing());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School App'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.grey.shade200,
            ),
            width: MediaQuery.of(context).size.width - 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildVerticalDivider(),
                  _buildColorWidget(
                    color: Colors.black,
                    state: state,
                    setState: setState,
                  ),
                  const SizedBox(width: 10),
                  _buildColorWidget(
                    color: Colors.blue,
                    state: state,
                    setState: setState,
                  ),
                  const SizedBox(width: 10),
                  _buildColorWidget(
                    color: Colors.red,
                    state: state,
                    setState: setState,
                  ),
                  const SizedBox(width: 10),
                  _buildColorWidget(
                    color: Colors.green,
                    state: state,
                    setState: setState,
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: Listener(
              onPointerDown: (event) {
                state.newLine();
                state.addPointOffset(event.localPosition);
                setState(() {});
              },
              onPointerMove: (event) =>
                  setState(() => state.addPointOffset(event.localPosition)),
              child: SizedBox.expand(
                child: CustomPaint(painter: DrawingPainter(state: state)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildVerticalDivider() {
  return Container(
    margin: const EdgeInsets.only(left: 10, right: 10),
    color: Colors.grey.shade300,
    child: const SizedBox(height: 30, width: 2),
  );
}

Widget _buildColorWidget({
  required Color color,
  required DrawerState state,
  required void Function(void Function()) setState,
}) {
  return _buildButton(
    color: color,
    borderRadius: state.activeColor == color ? 5 : 20,
    onTap: () => setState(() => state.setActiveColor(color)),
  );
}

Widget _buildButton({
  required Color color,
  required double borderRadius,
  required void Function() onTap,
  Icon? icon,
}) {
  return AnimatedContainer(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color,
    ),
    duration: const Duration(milliseconds: 100),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: icon == null ? null : Center(child: icon),
        ),
      ),
    ),
  );
}
