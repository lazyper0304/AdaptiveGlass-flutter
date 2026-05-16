import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FloatingHomeNavigation extends StatelessWidget {
  const FloatingHomeNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(26, 0, 26, 18),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: GlassBottomBar(
            selectedIndex: selectedIndex,
            onTabSelected: onSelected,
            interactionGlowColor: _homeAccentColor(context),
            selectedIconColor: Colors.black,
            unselectedIconColor: Colors.black,
            quality: GlassQuality.premium,
            tabs: const [
              GlassBottomBarTab(
                icon: Icon(Icons.home_rounded),
                label: '首页',
              ),
              GlassBottomBarTab(
                icon: Icon(Icons.settings_rounded),
                label: '设置',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _homeAccentColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);
}
