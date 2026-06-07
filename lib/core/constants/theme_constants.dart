library;

import 'package:flutter/material.dart';

/// 主题常量定义
class ThemeConstants {
  ThemeConstants._();

  // 主色调
  static const Color primaryColor = Color(0xFF79D6FF);
  static const Color accentColorLight = Color(0xFF238E54);
  static const Color accentColorDark = Color(0xFFC7FF12);

  // Glass 主题配置
  static const double glassBlur = 12;
  static const double glassThicknessLight = 28;
  static const double glassThicknessDark = 36;
  static const Color glassColorLight = Color(0xB8FFFFFF);
  static const Color glassColorDark = Color(0x4A111820);
  static const double lightIntensityDark = 1.2;
  static const double lightIntensityLight = 0.82;

  // 阴影配置
  static const List<BoxShadow> smallShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> largeShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // 文本样式常量
  static const double textLineHeight = 1.5;
  static const double letterSpacing = 0;

  // 色板预览配置
  static const int paletteCount = 5;
  static const double paletteDotSize = 52.0;
  static const double paletteDotSelectedSize = 56.0;

  // 水印字体
  static const String systemFontFamily = '';
  static const String customFontFamily = 'SmileySans';
}
