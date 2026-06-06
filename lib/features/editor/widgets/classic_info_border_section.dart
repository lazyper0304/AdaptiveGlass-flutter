import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/classic_info_border_settings.dart';
import '../../../shared/app_theme.dart';
import 'tappable_switch_row.dart';

class ClassicInfoBorderSection extends StatefulWidget {
  const ClassicInfoBorderSection({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final ClassicInfoBorderSettings settings;
  final ValueChanged<ClassicInfoBorderSettings> onChanged;

  @override
  State<ClassicInfoBorderSection> createState() =>
      _ClassicInfoBorderSectionState();
}

class _ClassicInfoBorderSectionState extends State<ClassicInfoBorderSection> {
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.settings.manualTitle);
    _detailsController = TextEditingController(
      text: widget.settings.manualDetails,
    );
    _titleController.addListener(_handleTitleChanged);
    _detailsController.addListener(_handleDetailsChanged);
  }

  @override
  void didUpdateWidget(covariant ClassicInfoBorderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_titleController.text != widget.settings.manualTitle) {
      _titleController.value = TextEditingValue(
        text: widget.settings.manualTitle,
        selection: TextSelection.collapsed(
          offset: widget.settings.manualTitle.length,
        ),
      );
    }
    if (_detailsController.text != widget.settings.manualDetails) {
      _detailsController.value = TextEditingValue(
        text: widget.settings.manualDetails,
        selection: TextSelection.collapsed(
          offset: widget.settings.manualDetails.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTitleChanged);
    _detailsController.removeListener(_handleDetailsChanged);
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _handleTitleChanged() {
    if (_titleController.text == widget.settings.manualTitle) {
      return;
    }
    widget.onChanged(
      widget.settings.copyWith(manualTitle: _titleController.text),
    );
  }

  void _handleDetailsChanged() {
    if (_detailsController.text == widget.settings.manualDetails) {
      return;
    }
    widget.onChanged(
      widget.settings.copyWith(manualDetails: _detailsController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = context.accentColor;
    final settings = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SwitchRow(
          label: '启用底部信息边框',
          value: settings.enabled,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(enabled: value)),
        ),
        const SizedBox(height: 12),
        _EnumRow<ClassicInfoSource>(
          value: settings.metadataSource,
          values: ClassicInfoSource.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(metadataSource: value)),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.14)),
          ),
          child: Text(
            settings.metadataSource == ClassicInfoSource.auto
                ? '自动模式会优先读取 EXIF；如果机型或参数缺失，会回退到下面的手动内容。'
                : '手动模式会直接使用下面填写的标题和参数，不再读取 EXIF。',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.78),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(text: '机型标题'),
        GlassTextField(
          controller: _titleController,
          placeholder: '例如 Sony A7R V / Leica Q3',
          prefixIcon: const Icon(Icons.camera_alt_rounded, size: 18),
          quality: GlassQuality.standard,
        ),
        const SizedBox(height: 12),
        const _FieldLabel(text: '参数详情'),
        GlassTextField(
          controller: _detailsController,
          placeholder: '例如 ISO 200   f/2.8   1/125s   35mm',
          prefixIcon: const Icon(Icons.tune_rounded, size: 18),
          quality: GlassQuality.standard,
        ),
        const SizedBox(height: 12),
        _EnumRow<CameraLogoOption>(
          value: settings.logo,
          values: CameraLogoOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(logo: value)),
        ),
        _SliderRow(
          label: '厂商标志大小 ${(settings.logoScale * 100).round()}%',
          value: settings.logoScale * 100,
          min: 60,
          max: 220,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(logoScale: value / 100)),
          accent: accent,
        ),
        _SliderRow(
          label: 'EXIF文字大小 ${(settings.fontSizeScale * 100).round()}%',
          value: settings.fontSizeScale * 100,
          min: 50,
          max: 200,
          onChanged: (value) =>
              widget.onChanged(settings.copyWith(fontSizeScale: value / 100)),
          accent: accent,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: colors.onSurface.withValues(alpha: 0.82),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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

class _EnumRow<T extends Enum> extends StatelessWidget {
  const _EnumRow({
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
