import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/subjects/subjects_widget.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';
import 'package:school_app/util.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    this.hasAccount = true,
  }) : super(key: key);

  final bool hasAccount;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var isHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    List<Widget> children = [
      TaskListWidget(
          maxDateTime: DateTime.now().date.add(const Duration(days: 7))),
      const VerticalDivider(width: 0),
      const SubjectsWidget(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () async {
              if (widget.hasAccount) {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginPage()));
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SignUpPage(migrate: true)));
              }
            },
            icon: Icon(widget.hasAccount ? Icons.logout : Icons.login),
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
