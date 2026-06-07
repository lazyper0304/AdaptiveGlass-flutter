import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 应用主题数据
class AppTheme {
  AppTheme._();

  static GlassThemeData lightTheme = GlassThemeData(
    panelColor: Colors.white,
    cardColor: Colors.white,
    buttonColor: Colors.white,
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF6A6A6A),
    dividerColor: Color(0x14000000),
  );

  static GlassThemeData darkTheme = GlassThemeData(
    panelColor: Color(0xFF1C1C1E),
    cardColor: Color(0xFF2C2C2E),
    buttonColor: Color(0xFF3A3A3C),
    textPrimary: Color(0xFFFCFCFF),
    textSecondary: Color(0xFFA1A1A6),
    dividerColor: Color(0x1FFFFFFF),
  );
}
