import 'package:flutter/material.dart';

import '../constants/theme_constants.dart';

/// 应用色板
class AppColors {
  AppColors._();

  // 主色
  static const Color primary = Color(0xFF79D6FF);

  // 强调色
  static Color get accentLight => accentColorLight;
  static Color get accentDark => accentColorDark;

  // 背景色
  static Color get backgroundLight => const Color(0xFFF5F5F7);
  static Color get backgroundDark => const Color(0xFF000000);

  // 表面色
  static Color get surfaceLight => const Color(0xFFFFFFFF);
  static Color get surfaceDark => const Color(0xFF1C1C1E);

  // 文本色
  static Color get textPrimaryLight => const Color(0xFF111111);
  static Color get textPrimaryDark => const Color(0xFFFCFCFF);
  static Color get textSecondaryLight => const Color(0xFF6A6A6A);
  static Color get textSecondaryDark => const Color(0xFFA1A1A6);

  // 边框色
  static Color get borderLight => const Color(0xFFE5E5E7);
  static Color get borderDark => const Color(0xFF38383A);

  // 成功/错误色
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);

  // 水印相关颜色
  static const Color watermarkTextLight = Color(0xFFFFFFFF);
  static const Color watermarkTextDark = Color(0xFF111111);
  static const Color watermarkShadowLight = Color(0x7F000000);
  static const Color watermarkShadowDark = Color(0x7FFFFFFF);
}
