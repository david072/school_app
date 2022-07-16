import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/database/database.dart';
import 'package:school_app/data/tasks/abstract_task.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';

class TrashBinPage extends StatefulWidget {
  const TrashBinPage({Key? key}) : super(key: key);

  @override
  State<TrashBinPage> createState() => _TrashBinPageState();
}

class _TrashBinPageState extends State<TrashBinPage> {
  late StreamSubscription<List<AbstractTask>> subscription;

  List<AbstractTask> tasks = [];

  @override
  void initState() {
    super.initState();
    subscription = Database.queryTasksAndClassTests(areDeleted: true)
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
        title: Text('trash_bin_title'.tr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TasksList(
            mode: TasksListMode.deleted,
            items: tasks,
          ),
        ],
      ),
    );
  }
}
