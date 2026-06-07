import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_colors.dart';

/// 值选择器（单选 Chips）
class ValueSelector<T extends Enum> extends StatelessWidget {
  const ValueSelector({
    super.key,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelBuilder,
    this.vertical = false,
  });

  final T value;
  final List<T> values;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? accentColorDark : accentColorLight;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (item) => GlassChip(
              label: (labelBuilder ?? ((e) => e.name))(item),
              selected: value == item,
              selectedColor: accent.withValues(alpha: 0.22),
              labelStyle: TextStyle(
                color: value == item
                    ? accent
                    : colors.onSurface.withValues(alpha: 0.82),
                fontWeight: value == item ? FontWeight.w800 : FontWeight.w600,
              ),
              onTap: () => onChanged(item),
            ),
          )
          .toList(),
    );
  }
}

/// 开关选择器
class ToggleSelector extends StatelessWidget {
  const ToggleSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final accent = activeColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? accentColorDark
            : accentColorLight);

    return TappableSwitchRow(
      label: label,
      value: value,
      onChanged: onChanged,
      activeColor: accent,
    );
  }
}
