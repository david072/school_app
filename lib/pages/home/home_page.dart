import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/account_dialog.dart';
import 'package:school_app/pages/split_layout_widget.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          widget.hasAccount
              ? IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AccountDialog(),
                  ),
                )
              : Container(),
          TextButton.icon(
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
            label: Text(widget.hasAccount ? 'Logout' : 'Account erstellen',
                style: const TextStyle(color: Colors.white)),
            icon: Icon(
              widget.hasAccount ? Icons.logout : Icons.login,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: SplitLayout(
        first: TaskListWidget(
            maxDateTime: DateTime.now().date.add(const Duration(days: 7))),
        second: const SubjectsWidget(),
      ),
    );
  }
}
