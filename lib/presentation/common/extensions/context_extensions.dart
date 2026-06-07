import 'package:flutter/material.dart';

/// 上下文扩展
extension ContextExtensions on BuildContext {
  /// 获取主题色
  Color get primaryColor => Theme.of(this).colorScheme.primary;

  /// 获取强调色
  Color get accentColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ColorsAccent.accentDark : ColorsAccent.accentLight;
  }

  /// 获取文本颜色
  Color get textColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ColorsAccent.textPrimaryDark : ColorsAccent.textPrimaryLight;
  }

  /// 获取二级文本颜色
  Color get secondaryTextColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ColorsAccent.textSecondaryDark : ColorsAccent.textSecondaryLight;
  }

  /// 获取背景色
  Color get backgroundColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? ColorsAccent.backgroundDark : ColorsAccent.backgroundLight;
  }

  /// 是否为深色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// 颜色扩展
class ColorsAccent {
  ColorsAccent._();

  static Color get accentLight => const Color(0xFF238E54);
  static Color get accentDark => const Color(0xFFC7FF12);
  static Color get textPrimaryLight => const Color(0xFF111111);
  static Color get textPrimaryDark => const Color(0xFFFCFCFF);
  static Color get textSecondaryLight => const Color(0xFF6A6A6A);
  static Color get textSecondaryDark => const Color(0xFFA1A1A6);
  static Color get backgroundLight => const Color(0xFFF5F5F7);
  static Color get backgroundDark => const Color(0xFF000000);
}
