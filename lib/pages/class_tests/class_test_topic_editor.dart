import 'package:flutter/material.dart';
import 'package:school_app/data/class_test.dart';
import 'package:school_app/util/util.dart';

class ClassTestTopicEditor extends StatefulWidget {
  const ClassTestTopicEditor({
    Key? key,
    this.editable = true,
    required this.topics,
  }) : super(key: key);

  final bool editable;
  final List<ClassTestTopic> topics;

  @override
  State<ClassTestTopicEditor> createState() => _ClassTestTopicEditorState();
}

class _ClassTestTopicEditorState extends State<ClassTestTopicEditor> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  bool get isEditable => widget.editable;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isEditable
            ? TextButton(
                onPressed: () {
                  setState(() => widget.topics
                      .add(ClassTestTopic(topic: "", resources: "")));
                  listKey.currentState!.insertItem(widget.topics.length - 1,
                      duration: const Duration(milliseconds: 100));
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: 'Add',
                          style: Theme.of(context).textTheme.bodyText1),
                      const WidgetSpan(child: SizedBox(width: 5)),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.add,
                            color:
                                Theme.of(context).textTheme.bodyText1!.color),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox(),
        AnimatedList(
          key: listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: widget.topics.length,
          itemBuilder: (context, i, animation) => FadeTransition(
            opacity: animation.drive(Tween(begin: 0, end: 1)),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isEditable
                        ? Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      final removedTopic =
                                          widget.topics.removeAt(i);
                                      listKey.currentState!.removeItem(
                                        i,
                                        (context, animation) => _animateOutCard(
                                            removedTopic, animation),
                                        duration:
                                            const Duration(milliseconds: 100),
                                      );
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                    isEditable ? const Divider() : const SizedBox(),
                    Row(
                      children: [
                        Flexible(
                          child: TextField(
                            enabled: isEditable,
                            controller: TextEditingController(
                                text: widget.topics[i].topic),
                            onChanged: (s) => widget.topics[i].topic = s,
                            maxLines: null,
                            decoration: buildInputDecoration("Topic"),
                          ),
                        ),
                        const VerticalDivider(),
                        Flexible(
                          child: TextField(
                            enabled: isEditable,
                            controller: TextEditingController(
                                text: widget.topics[i].resources),
                            onChanged: (s) => widget.topics[i].resources = s,
                            maxLines: null,
                            decoration: buildInputDecoration("Resources"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _animateOutCard(ClassTestTopic topic, Animation animation) {
    return FadeTransition(
      opacity: animation.drive(Tween(begin: 0, end: 1)),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.delete),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: TextEditingController(text: topic.topic),
                      enabled: false,
                      maxLines: null,
                      decoration: buildInputDecoration("Topic"),
                    ),
                  ),
                  const VerticalDivider(),
                  Flexible(
                    child: TextField(
                      controller: TextEditingController(text: topic.resources),
                      enabled: false,
                      maxLines: null,
                      decoration: buildInputDecoration("Resources"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
