import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common_home_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.themeModeValue,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeModeValue;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 150),
        children: [
          PageTitleRow(title: '设置', subtitle: '管理预设和偏好'),
          const SizedBox(height: 28),
          FrostedPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '外观',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                ThemeModeSelector(
                  themeMode: themeModeValue,
                  onChanged: onThemeModeChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
