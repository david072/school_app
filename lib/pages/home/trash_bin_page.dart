import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/task.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';

class TrashBinPage extends StatefulWidget {
  const TrashBinPage({Key? key}) : super(key: key);

  @override
  State<TrashBinPage> createState() => _TrashBinPageState();
}

class _TrashBinPageState extends State<TrashBinPage> {
  late StreamSubscription<List<Task>> subscription;

  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    subscription = Database.I
        .queryDeletedTasks()
        .listen((event) => setState(() => tasks = event));
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Papierkorb'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TasksList(
            layout: TasksListLayout.deleted,
            tasks: tasks,
          ),
        ],
      ),
    );
  }
}
