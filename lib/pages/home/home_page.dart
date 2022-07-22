import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/data/app_state.dart';
import 'package:school_app/pages/auth/login_page.dart';
import 'package:school_app/pages/auth/signup_page.dart';
import 'package:school_app/pages/home/account_dialog.dart';
import 'package:school_app/pages/home/settings_page.dart';
import 'package:school_app/pages/home/trash_bin_page.dart';
import 'package:school_app/pages/link_page.dart';
import 'package:school_app/pages/subjects/subjects_widget.dart';
import 'package:school_app/pages/tasks/soon_tasks_widget.dart';
import 'package:school_app/util/util.dart';
import 'package:uni_links/uni_links.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AfterLayoutMixin {
  late StreamSubscription<Uri?> subscription;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    final initialUri = await getInitialUri();
    if (initialUri != null) handleUri(initialUri);

    subscription = uriLinkStream.listen((uri) {
      if (uri != null) handleUri(uri);
    });
  }

  void handleUri(Uri uri) {
    if (uri.pathSegments.length > 1) return;
    if (uri.pathSegments[0].toLowerCase() != "link") return;
    if (uri.queryParameters['id'] == null) return;

    Get.to(() => LinkPage(uri: uri));
  }

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
          AppState.I.hasAccount
              ? IconButton(
                  icon: const Icon(Icons.account_circle),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AccountDialog(),
                  ),
                )
              : Container(),
          TextButton.icon(
            onPressed: () {
              if (!AppState.I.hasAccount) {
                Get.to(() => const SignUpPage(migrate: true));
                return;
              }

              showConfirmationDialog(
                context: context,
                title: 'logout'.tr,
                content: 'confirm_logout_text'.tr,
                cancelText: 'cancel_caps'.tr,
                confirmText: 'logout_caps'.tr,
                onConfirm: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Get.off(() => const LoginPage());
                },
              );
            },
            label: Text(
                AppState.I.hasAccount ? 'logout'.tr : 'create_account'.tr,
                style: const TextStyle(color: Colors.white)),
            icon: Icon(
              AppState.I.hasAccount ? Icons.logout : Icons.login,
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
