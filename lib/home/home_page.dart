import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/home/soon_tasks_widget.dart';
import 'package:school_app/home/subjects_widget.dart';

import '../auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var isHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    List<Widget> children = const [
      SoonTasksWidget(),
      SubjectsWidget(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.off(() => const LoginPage());
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: !isHorizontal
            ? Column(children: children)
            : Row(children: children),
      ),
    );
  }
}
