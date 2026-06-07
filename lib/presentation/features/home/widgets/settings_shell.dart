import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'home_screen.dart';

class SettingsShell extends StatelessWidget {
  const SettingsShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsPage(),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            sliver: const SliverToBoxAdapter(
              child: PageTitleRow(title: '设置', subtitle: '应用配置和偏好'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
                shape:
                    const LiquidRoundedSuperellipse(borderRadius: 28),
                quality: GlassQuality.standard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '主题模式',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ThemeModeChip(
                          label: '系统',
                          mode: ThemeMode.system,
                          selected: themeMode.value == ThemeMode.system,
                        ),
                        _ThemeModeChip(
                          label: '浅色',
                          mode: ThemeMode.light,
                          selected: themeMode.value == ThemeMode.light,
                        ),
                        _ThemeModeChip(
                          label: '深色',
                          mode: ThemeMode.dark,
                          selected: themeMode.value == ThemeMode.dark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.label,
    required this.mode,
    required this.selected,
  });

  final String label;
  final ThemeMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? accentColorDark : accentColorLight;

    return GlassChip(
      label: label,
      selected: selected,
      selectedColor: accent.withValues(alpha: 0.22),
      labelStyle: TextStyle(
        color: selected ? accent
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      onTap: () => updateThemeMode(mode),
    );
  }
}
