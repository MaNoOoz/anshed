import 'package:get/get.dart';

enum ThemeMode { light, dark, system }

class SettingsController extends GetxController {
  var themeMode = ThemeMode.system.obs; // Observable theme mode

  final List<ThemeMode> themeModes = [
    ThemeMode.light,
    ThemeMode.dark,
    ThemeMode.system
  ];

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    // You can also save the theme mode to local storage here if needed.
  }
}
