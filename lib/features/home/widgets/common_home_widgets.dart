import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Color homeAccentColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);
}

class PageTitleRow extends StatelessWidget {
  const PageTitleRow({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'SmileySans',
                  color: colors.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassPanel(
      padding: padding,
      shape: const LiquidRoundedSuperellipse(borderRadius: 26),
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        blur: 12,
        thickness: isDark ? 34 : 26,
        glassColor: isDark ? const Color(0x551C2026) : const Color(0xB8FFFFFF),
        lightIntensity: isDark ? 1.2 : 0.82,
      ),
      child: child,
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);
    const options = [
      (
        mode: ThemeMode.system,
        icon: Icons.phone_android_rounded,
        label: '\u8ddf\u968f\u7cfb\u7edf',
      ),
      (
        mode: ThemeMode.light,
        icon: Icons.light_mode_rounded,
        label: '\u6d45\u8272\u6a21\u5f0f',
      ),
      (
        mode: ThemeMode.dark,
        icon: Icons.dark_mode_rounded,
        label: '\u6df1\u8272\u6a21\u5f0f',
      ),
    ];

    return SizedBox(
      height: 44,
      child: GlassPanel(
        padding: const EdgeInsets.all(3),
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        quality: GlassQuality.standard,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: options.map((option) {
            final isSelected = themeMode == option.mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: InkWell(
                  onTap: () => onChanged(option.mode),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: isSelected
                          ? accent.withValues(alpha: 0.24)
                          : Colors.transparent,
                      border: isSelected
                          ? Border.all(color: accent.withValues(alpha: 0.62))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option.icon,
                          size: 16,
                          color: isSelected
                              ? accent
                              : colors.onSurface.withValues(alpha: 0.62),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            option.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? accent
                                  : colors.onSurface.withValues(alpha: 0.72),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProfileAction extends StatelessWidget {
  const ProfileAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = homeAccentColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurface.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}
