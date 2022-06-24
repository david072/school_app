import 'package:get/get.dart';
import 'package:school_app/util/translations/english.dart';
import 'package:school_app/util/translations/german.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys =>
      {
        'de': German.translations,
        'en': English.translations,
      };
}
