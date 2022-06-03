import 'package:flutter/material.dart';
import 'package:school_app/drawer.dart';
import 'package:school_app/types.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'School App',
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// TODO: Use InteractiveViewer or something for panning
class _HomePageState extends State<HomePage> {
  DrawerState state = DrawerState(drawing: Drawing());

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
                child: CustomPaint(painter: DrawerPainter(state: state)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildColorWidget({
  required Color color,
  required DrawerState state,
  required void Function(void Function()) setState,
}) {
  return AnimatedContainer(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(state.activeColor == color ? 5 : 20),
      color: color,
    ),
    duration: const Duration(milliseconds: 100),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => state.setActiveColor(color)),
        child: const SizedBox(
          width: 40,
          height: 40,
        ),
      ),
    ),
  );
}
