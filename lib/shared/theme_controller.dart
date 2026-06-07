import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

final themeMode = signal(ThemeMode.dark);

const _themeModePreferenceKey = 'theme_mode';

Future<void> initializeThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  themeMode.value = _themeModeFromName(prefs.getString(_themeModePreferenceKey));
}

void updateThemeMode(ThemeMode mode) {
  themeMode.value = mode;
  _persistThemeMode(mode);
}

Future<void> _persistThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModePreferenceKey, mode.name);
}

ThemeMode _themeModeFromName(String? rawValue) {
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == rawValue,
    orElse: () => ThemeMode.dark,
  );
}
