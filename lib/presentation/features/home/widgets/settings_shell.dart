import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../shared/app_theme.dart';
import '../../../../shared/theme_controller.dart';
import 'home_shell.dart';

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
                      '外观',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '主题模式',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      '字体',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FontChip(
                          label: '得意黑',
                          family: 'SmileySans',
                          selected: fontFamily.value == 'SmileySans',
                        ),
                        _FontChip(
                          label: '系统字体',
                          family: '',
                          selected: fontFamily.value == '',
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
    final accent = context.accentColor;

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

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.label,
    required this.family,
    required this.selected,
  });

  final String label;
  final String family;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return GlassChip(
      label: label,
      selected: selected,
      selectedColor: accent.withValues(alpha: 0.22),
      labelStyle: TextStyle(
        fontFamily: family.isEmpty ? null : family,
        color: selected ? accent
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.82),
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      onTap: () => updateFontFamily(family),
    );
  }
}
