import 'package:flutter/material.dart';

class FloatingHomeNavigation extends StatelessWidget {
  const FloatingHomeNavigation({
    super.key,
    this.selectedIndex = 0,
    this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? accentColorDark : accentColorLight;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? colorDark : colorLight,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: GlassBottomBar(
        selectedIndex: selectedIndex,
        onTap: onSelected ?? ((index) {}),
        items: [
          GlassBottomBarItem(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: '首页',
            backgroundColor: isDark ? colorDark : colorLight,
          ),
          GlassBottomBarItem(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: '设置',
            backgroundColor: isDark ? colorDark : colorLight,
          ),
        ],
      ),
    );
  }
}

// 临时颜色定义
final colorLight = const Color(0xB8FFFFFF);
final colorDark = const Color(0x4A111820);
final accentColorLight = Color(0xFF238E54);
final accentColorDark = Color(0xFFC7FF12);
