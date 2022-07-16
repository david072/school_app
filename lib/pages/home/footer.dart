import 'package:flutter/material.dart';

class Footer extends StatefulWidget {
  const Footer({
    Key? key,
    this.reverse = false,
    this.popupItems,
    this.onPopupItemSelected,
    required this.text,
    this.onClick,
  }) : super(key: key);

  final bool reverse;
  final List<PopupMenuItem>? popupItems;
  final void Function(dynamic)? onPopupItemSelected;
  final Widget text;
  final void Function()? onClick;

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final iconButtonKey = GlobalKey();

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          !widget.reverse
              ? DefaultTextStyle(
                  style: Theme.of(context).textTheme.caption!,
                  child: widget.text,
                )
              : Container(),
          Expanded(
            child: Align(
              alignment: !widget.reverse
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: AnimatedRotation(
                  turns: !isExpanded ? 0 : 0.126,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: iconButtonKey,
                    onPressed: widget.popupItems == null
                        ? widget.onClick!
                        : showPopupMenu,
                    icon: const Icon(Icons.add),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(5),
                  ),
                ),
              ),
            ),
          ),
          !widget.reverse
              ? Container()
              : DefaultTextStyle(
                  style: Theme.of(context).textTheme.caption!,
                  child: widget.text,
                ),
        ],
      ),
    );
  }

  Future<void> showPopupMenu() async {
    setState(() => isExpanded = true);

    final renderBox =
        iconButtonKey.currentContext!.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context)!.context.findRenderObject()! as RenderBox;

    // Offset popup menu up by 90 units (and set at correct X pos)
    final offset = Offset(
      renderBox.localToGlobal(renderBox.size.topRight(Offset.zero)).dx,
      -renderBox.size.height - 90,
    );
    // Points: top right & bottom left
    final position = RelativeRect.fromRect(
      // Outer rect
      Rect.fromPoints(
        renderBox.localToGlobal(offset, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomLeft(Offset.zero) - offset,
            ancestor: overlay),
      ),
      // Inner rect
      Offset.zero & overlay.size,
    );

    final result = await showMenu(
      position: position,
      context: context,
      items: widget.popupItems!,
    );
    if (result == null) {
      setState(() => isExpanded = false);
      return;
    }

    widget.onPopupItemSelected!(result);
    setState(() => isExpanded = false);
  }
}
