import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/notebook.dart';
import 'package:school_app/pages/drawing/create_notebook_page.dart';
import 'package:school_app/pages/home/footer.dart';
import 'package:school_app/util.dart';

class NotebooksWidget extends StatefulWidget {
  const NotebooksWidget({
    Key? key,
    required this.subjectId,
  }) : super(key: key);

  final String subjectId;

  @override
  State<NotebooksWidget> createState() => _NotebooksWidgetState();
}

class _NotebooksWidgetState extends State<NotebooksWidget> {
  late StreamSubscription<List<Notebook>> subscription;
  List<Notebook> notebooks = [];

  @override
  void initState() {
    super.initState();
    subscription = Database.I
        .queryNotebooks(widget.subjectId)
        .listen((data) => setState(() => notebooks = data));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: notebooks.isNotEmpty
                ? GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemCount: notebooks.length,
                    itemBuilder: (ctx, i) => _Notebook(notebook: notebooks[i]),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Keine Hefte',
                          style: Theme.of(context).textTheme.headline5),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'Erstelle Hefte mit dem ',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const WidgetSpan(child: Icon(Icons.add, size: 20)),
                            TextSpan(
                                text: ' unten rechts.',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Footer(
            displayName: 'Hefte',
            count: notebooks.length,
            onAdd: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateNotebookPage())),
          ),
        ],
      ),
    );
  }
}

class _Notebook extends StatefulWidget {
  const _Notebook({
    Key? key,
    required this.notebook,
  }) : super(key: key);

  final Notebook notebook;

  @override
  State<_Notebook> createState() => _NotebookState();
}

class _NotebookState extends State<_Notebook> {
  var enabled = true;

  @override
  Widget build(BuildContext context) {
    return LongPressPopupMenu(
      onTap: () => print("open notebook"),
      enabled: enabled,
      items: const [
        PopupMenuItem(
          value: 0,
          child: Text('Bearbeiten'),
        ),
        PopupMenuItem(
          value: 1,
          child: Text('Löschen'),
        ),
      ],
      functions: [
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    CreateNotebookPage(notebookToEdit: widget.notebook))),
        () => showConfirmationDialog(
              context: context,
              title: 'Löschen',
              content:
                  'Möchtest du das Heft \'${widget.notebook.name}\' wirklich löschen?',
              cancelText: 'Abbrechen',
              confirmText: 'Löschen',
              onConfirm: () => Database.I.deleteNotebook(widget.notebook.id),
            ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: !enabled ? Theme.of(context).disabledColor : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.note,
              size: 40,
            ),
            const SizedBox(height: 20),
            Text(
              widget.notebook.name,
              style: Theme.of(context).textTheme.headline6,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
