import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/account_dialog.dart';
import 'package:school_app/pages/home/settings_page.dart';
import 'package:school_app/pages/home/trash_bin_page.dart';
import 'package:school_app/pages/subjects/subjects_widget.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';
import 'package:school_app/util/util.dart';

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
        isHorizontal: isHorizontal,
        maxDateTime: DateTime.now().date.add(const Duration(days: 21)),
      ),
      const VerticalDivider(width: 0),
      const SubjectsWidget(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => Get.to(() => const TrashBinPage()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsPage()),
          ),
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
            onPressed: () => showConfirmationDialog(
              context: context,
              title: 'logout'.tr,
              content: 'confirm_logout_text'.tr,
              cancelText: 'cancel_caps'.tr,
              confirmText: 'logout_caps'.tr,
              onConfirm: () async {
                if (widget.hasAccount) {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Get.off(() => const LoginPage());
                } else {
                  Get.to(() => const SignUpPage(migrate: true));
                }
              },
            ),
            label: Text(widget.hasAccount ? 'logout'.tr : 'create_account'.tr,
                style: const TextStyle(color: Colors.white)),
            icon: Icon(
              widget.hasAccount ? Icons.logout : Icons.login,
              color: Colors.white,
            ),
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
