import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

final themeMode = signal(ThemeMode.dark);
final fontFamily = signal<String>('SmileySans');

const _themeModePreferenceKey = 'theme_mode';
const _fontFamilyPreferenceKey = 'font_family';

Future<void> initializeThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  themeMode.value = _themeModeFromName(prefs.getString(_themeModePreferenceKey));
  fontFamily.value = prefs.getString(_fontFamilyPreferenceKey) ?? 'SmileySans';
}

void updateThemeMode(ThemeMode mode) {
  themeMode.value = mode;
  _persistThemeMode(mode);
}

void updateFontFamily(String family) {
  fontFamily.value = family;
  _persistFontFamily(family);
}

Future<void> _persistThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModePreferenceKey, mode.name);
}

Future<void> _persistFontFamily(String family) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_fontFamilyPreferenceKey, family);
}

ThemeMode _themeModeFromName(String? rawValue) {
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == rawValue,
    orElse: () => ThemeMode.dark,
  );
}
