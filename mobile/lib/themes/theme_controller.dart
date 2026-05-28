import 'package:flutter/material.dart';

enum AppAppearanceMode { light, dark, auto }

class ThemeController {
  ThemeController._();

  static final ValueNotifier<AppAppearanceMode> appearanceMode =
      ValueNotifier<AppAppearanceMode>(AppAppearanceMode.dark);

  static ThemeMode get themeMode {
    switch (appearanceMode.value) {
      case AppAppearanceMode.light:
        return ThemeMode.light;
      case AppAppearanceMode.dark:
        return ThemeMode.dark;
      case AppAppearanceMode.auto:
        return ThemeMode.system;
    }
  }

  static void setAppearanceMode(AppAppearanceMode mode) {
    appearanceMode.value = mode;
  }
}
