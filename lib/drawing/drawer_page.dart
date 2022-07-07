import 'package:flutter/material.dart';
import 'package:school_app/drawing/drawing_canvas_widget.dart';
import 'package:school_app/drawing/drawing_state.dart';
import 'package:school_app/util.dart';

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
  DrawerState? state;

  double scale = 1;

  @override
  void initState() {
    super.initState();
    loadState();
  }

  Future<void> loadState() async {
    state = await DrawerState.init(widget.drawing ?? Drawing());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School App'),
        actions: [
          PopupMenuButton(
            onSelected: (i) {
              switch (i) {
                case 0:
                  if (state != null) {
                    state!.allowFingerDrawing = !state!.allowFingerDrawing;
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 0,
                checked: state?.allowFingerDrawing ?? true,
                child: const Text('Handzeichnen'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey,
      body: state != null
          ? Column(
              children: [
                _Toolbar(
                  state: state!,
                  scale: scale,
                ),
                Flexible(
                  child: DrawingCanvas(
                    state: state!,
                    onScaleChanged: (s) => setState(() => scale = s),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Toolbar extends StatefulWidget {
  const _Toolbar({
    Key? key,
    required this.state,
    this.scale = 1,
  }) : super(key: key);

  final DrawerState state;
  final double scale;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  static const colors = [
    Colors.black,
    Colors.white,
    Colors.blue,
    Colors.green,
    Colors.red
  ];

  DrawerState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 10),
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _PenButton(
                          state: widget.state,
                          penType: PenType.pen,
                          onChanged: () => setState(() {}),
                          onDoSecondaryAction: _showPenPopupMenu,
                        ),
                        _PenButton(
                          state: state,
                          penType: PenType.eraser,
                          onChanged: () => setState(() {}),
                          onDoSecondaryAction: _showEraserPopupMenu,
                        ),
                        const VerticalDivider(),
                        const SizedBox(width: 10),
                        ...colors
                            .map((item) => _ColorWidget(
                                  state: state,
                                  color: item,
                                  onChanged: () => setState(() {}),
                                ))
                            .toList(growable: false),
                        const VerticalDivider(),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(widget.scale * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(
            height: 0,
            indent: 0,
            endIndent: 0,
            thickness: 2,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  void _showEraserPopupMenu(Offset pos) => showPopupMenu(
        context: context,
        items: [
          CheckedPopupMenuItem(
            checked: state.eraserMode == EraserMode.lines,
            value: 0,
            child: const Text('Linien Radierer'),
          ),
          CheckedPopupMenuItem(
            checked: state.eraserMode == EraserMode.points,
            value: 1,
            child: const Text('Punkt Radierer'),
          ),
          PopupMenuItem(
            child: StatefulBuilder(
              builder: (context, setState) => Slider(
                min: 5,
                max: 15,
                divisions: 10,
                label: state.eraserThickness.toStringAsFixed(0),
                value: state.eraserThickness,
                onChanged: (val) => setState(() => state.eraserThickness = val),
              ),
            ),
          ),
        ],
        position: pos,
        functions: [
          () => state.eraserMode = EraserMode.lines,
          () => state.eraserMode = EraserMode.points,
        ],
      );

  void _showPenPopupMenu(Offset pos) => showPopupMenu(
        context: context,
        items: [
          PopupMenuItem(
            child: StatefulBuilder(
              builder: (context, setState) => Slider(
                min: 1,
                max: 15,
                divisions: 14,
                label: state.thickness.toStringAsFixed(0),
                value: state.thickness,
                onChanged: (val) => setState(
                  (() => state.thickness = val),
                ),
              ),
            ),
          ),
        ],
        position: pos,
      );
}

class _ColorWidget extends StatelessWidget {
  const _ColorWidget({
    Key? key,
    required this.state,
    required this.color,
    required this.onChanged,
  }) : super(key: key);

  final DrawerState state;
  final Color color;
  final void Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return _Button(
      selected: state.activeColor == color,
      backgroundColor: color,
      onTap: () {
        state.activeColor = color;
        onChanged();
      },
      border: Border.all(
          color: color.computeLuminance() > 0.5
              ? Colors.grey
              : Colors.transparent),
    );
  }
}

class _PenButton extends StatelessWidget {
  const _PenButton({
    Key? key,
    required this.state,
    required this.penType,
    required this.onChanged,
    this.onDoSecondaryAction,
  }) : super(key: key);

  final DrawerState state;
  final PenType penType;
  final void Function() onChanged;
  final void Function(Offset)? onDoSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return _Button(
      selected: state.penType == penType,
      backgroundColor: Colors.white,
      onTap: () {
        if (state.penType == penType) {
          var renderBox = context.findRenderObject()! as RenderBox;
          var pos = renderBox.localToGlobal(Offset.zero);
          pos = pos.translate(0, renderBox.size.height + 10);
          onDoSecondaryAction?.call(pos);
        }
        state.penType = penType;
        onChanged();
      },
      border: Border.all(color: Colors.grey),
      icon: penType.getIcon(),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    Key? key,
    required this.selected,
    required this.backgroundColor,
    this.icon,
    this.border,
    required this.onTap,
  }) : super(key: key);

  final bool selected;
  final Color backgroundColor;
  final Widget? icon;
  final Border? border;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    var borderRadius = BorderRadius.circular(selected ? 5 : 20);
    return AnimatedContainer(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: border,
        borderRadius: borderRadius,
        color: backgroundColor,
      ),
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: icon != null ? Center(child: icon) : null,
          ),
        ),
      ),
    );
  }
}
