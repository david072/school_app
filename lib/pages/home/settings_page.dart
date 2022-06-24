import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_app/main.dart';
import 'package:school_app/util/util.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode mode = Get.isDarkMode ? ThemeMode.dark : ThemeMode.light;

  String modeString([ThemeMode? m]) {
    switch (m ?? mode) {
      case ThemeMode.system:
        return 'system'.tr;
      case ThemeMode.light:
        return 'light'.tr;
      case ThemeMode.dark:
        return 'dark'.tr;
    }
  }

  @override
  void initState() {
    super.initState();
    getThemeMode().then((value) => setState(() => mode = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr),
      ),
      body: SettingsList(
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            title: Text('appearance'.tr),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text('theme'.tr),
                onPressed: (context) => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('select_theme'.tr),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ThemeMode.values.map((value) {
                        return RadioListTile<ThemeMode>(
                          value: value,
                          groupValue: mode,
                          title: Text(modeString(value)),
                          onChanged: (newValue) {
                            setState(() => mode = newValue ?? mode);
                            Get.changeThemeMode(mode);
                            SharedPreferences.getInstance().then(
                                (sp) => sp.setInt(themeModeKey, mode.value));
                            Get.back();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                value: Text(modeString()),
              ),
            ],
          )
        ],
      ),
    );
  }
}
