import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appearance {
  static final grey = ValueNotifier<bool>(false);
  static Future<void> load() async {
    grey.value =
        await SharedPreferencesAsync().getBool('appearance.grey') ?? false;
  }

  static Future<void> setGrey(bool value) async {
    await SharedPreferencesAsync().setBool('appearance.grey', value);
    grey.value = value;
  }
}
