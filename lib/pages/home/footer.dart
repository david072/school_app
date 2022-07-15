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
                    onPressed: widget.popupItems == null
                        ? widget.onClick!
                        : () async {
                            setState(() => isExpanded = true);

                            final renderBox =
                                context.findRenderObject()! as RenderBox;
                            final overlay = Overlay.of(context)!
                                .context
                                .findRenderObject()! as RenderBox;

                            final offset =
                                Offset(0, -renderBox.size.height - 30);
                            final position = RelativeRect.fromRect(
                              Rect.fromPoints(
                                renderBox.localToGlobal(offset,
                                    ancestor: overlay),
                                renderBox.localToGlobal(
                                    renderBox.size.bottomRight(Offset.zero) -
                                        offset,
                                    ancestor: overlay),
                              ),
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
                          },
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
}
