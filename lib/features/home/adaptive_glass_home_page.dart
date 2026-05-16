import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../shared/adaptive_glass_backdrop.dart';
import 'pages/home/home_page.dart';
import 'pages/settings/settings_page.dart';
import 'package:adaptive_glass_flutter/features/home/widgets/floating_home_navigation.dart';

class AdaptiveGlassHomePage extends StatelessWidget {
  const AdaptiveGlassHomePage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScope.stack(
      background: const AdaptiveGlassBackdrop(),
      content: Positioned.fill(
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: navigationShell,
          bottomNavigationBar: FloatingHomeNavigation(
            selectedIndex: navigationShell.currentIndex,
            onSelected: _onTabSelected,
          ),
        ),
      ),
    );
  }
}

class AdaptiveGlassHomeShell extends StatelessWidget {
  const AdaptiveGlassHomeShell({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}

class AdaptiveGlassSettingsShell extends StatelessWidget {
  const AdaptiveGlassSettingsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return SettingsPage(
        themeModeValue: themeMode.value,
        onThemeModeChanged: (mode) => themeMode.value = mode,
      );
    });
  }
}

final themeMode = signal(ThemeMode.dark);
