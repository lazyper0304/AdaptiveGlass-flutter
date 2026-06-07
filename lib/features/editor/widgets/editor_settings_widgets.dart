import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../shared/app_theme.dart';
import 'tappable_switch_row.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class SettingsSliderRow extends StatelessWidget {
  const SettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurface.withValues(alpha: 0.82)),
        ),
        const SizedBox(height: 4),
        GlassSlider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: accent,
          inactiveColor: colors.onSurface.withValues(alpha: 0.16),
          thumbColor: colors.surface,
          quality: GlassQuality.standard,
        ),
      ],
    );
  }
}

class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return TappableSwitchRow(
      label: label,
      value: value,
      onChanged: onChanged,
      activeColor: context.accentColor,
    );
  }
}

class SettingsEnumRow<T extends Enum> extends StatelessWidget {
  const SettingsEnumRow({
    super.key,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values
            .map(
              (item) => GlassChip(
                label: labelBuilder(item),
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
      ),
    );
  }
}

class ColorWalkTextField extends StatefulWidget {
  const ColorWalkTextField({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<ColorWalkTextField> createState() => _ColorWalkTextFieldState();
}

class _ColorWalkTextFieldState extends State<ColorWalkTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(covariant ColorWalkTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    widget.onChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      controller: _controller,
      placeholder: '输入自定义文字',
      prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
      quality: GlassQuality.standard,
    );
  }
}

class ColorSelector extends StatelessWidget {
  const ColorSelector({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: context.accentColor,
                      width: 3,
                    )
                  : null,
            ),
            child: selected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
