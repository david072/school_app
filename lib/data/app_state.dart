import 'package:get/get.dart';

class AppState {
  bool hasAccount;

  AppState.init({
    required this.hasAccount,
  }) {
    Get.delete<AppState>(force: true);
    Get.put(this, permanent: true);
  }

  static AppState get I => Get.find<AppState>();
}
