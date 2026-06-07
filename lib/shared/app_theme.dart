import 'package:flutter/material.dart';

extension AppThemeX on BuildContext {
  Color get accentColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);
  }
}
