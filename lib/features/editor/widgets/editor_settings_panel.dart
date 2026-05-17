import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/frame_template.dart';
import '../../../models/processing_settings.dart';
import '../models/export_format_option.dart';

class EditorSettingsPanel extends StatelessWidget {
  const EditorSettingsPanel({
    super.key,
    required this.template,
    required this.settings,
    required this.exportFormat,
    required this.watermarkController,
    required this.onSettingsChanged,
    required this.onExportFormatChanged,
  });

  final FrameTemplate template;
  final ProcessingSettings settings;
  final ExportFormatOption exportFormat;
  final TextEditingController watermarkController;
  final ValueChanged<ProcessingSettings> onSettingsChanged;
  final ValueChanged<ExportFormatOption> onExportFormatChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassPanel(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      shape: const LiquidRoundedSuperellipse(borderRadius: 28),
      quality: GlassQuality.standard,
      settings: LiquidGlassSettings(
        blur: 12,
        thickness: isDark ? 36 : 28,
        glassColor: isDark ? const Color(0x4A111820) : const Color(0xB8FFFFFF),
        lightIntensity: isDark ? 1.2 : 0.82,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.88)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (template) {
            FrameTemplate.classic => _buildClassicSections(),
            FrameTemplate.colorBorder => _buildColorBorderSections(context),
          },
        ),
      ),
    );
  }

  List<Widget> _buildClassicSections() {
    return [
      _SectionTitle(text: '画布比例'),
      _EnumRow<RatioPreset>(
        value: settings.targetRatio,
        values: RatioPreset.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) =>
            onSettingsChanged(settings.copyWith(targetRatio: value)),
      ),
      _SliderRow(
        label: '内容缩放 ${settings.contentScale}%',
        value: settings.contentScale.toDouble(),
        min: 50,
        max: 100,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(contentScale: value.round()),
        ),
      ),
      _SectionTitle(text: '背景'),
      _SliderRow(
        label: '模糊半径 ${settings.blurRadius}',
        value: settings.blurRadius.toDouble(),
        min: 0,
        max: 100,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(blurRadius: value.round()),
        ),
      ),
      _SliderRow(
        label: '背景亮度 ${settings.blurBrightness}',
        value: settings.blurBrightness.toDouble(),
        min: -100,
        max: 100,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(blurBrightness: value.round()),
        ),
      ),
      _EnumRow<BlurModeOption>(
        value: settings.blurMode,
        values: BlurModeOption.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) =>
            onSettingsChanged(settings.copyWith(blurMode: value)),
      ),
      _SectionTitle(text: '边框'),
      _EnumRow<BorderStyleOption>(
        value: settings.borderStyle,
        values: BorderStyleOption.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) =>
            onSettingsChanged(settings.copyWith(borderStyle: value)),
      ),
      _SectionTitle(text: '导出'),
      _EnumRow<ExportFormatOption>(
        value: exportFormat,
        values: ExportFormatOption.values,
        labelBuilder: (item) => item.label,
        onChanged: onExportFormatChanged,
      ),
      _SliderRow(
        label: '边框宽度 ${settings.borderWidth}',
        value: settings.borderWidth.toDouble(),
        min: 0,
        max: 50,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(borderWidth: value.round()),
        ),
      ),
      _SliderRow(
        label: '圆角半径 ${settings.cornerRadius}',
        value: settings.cornerRadius.toDouble(),
        min: 0,
        max: 100,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(cornerRadius: value.round()),
        ),
      ),
      _SliderRow(
        label: '阴影强度 ${settings.shadowSize}',
        value: settings.shadowSize.toDouble(),
        min: 0,
        max: 50,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(shadowSize: value.round()),
        ),
      ),
      _EnumRow<MonoColor>(
        value: settings.borderColor,
        values: MonoColor.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) =>
            onSettingsChanged(settings.copyWith(borderColor: value)),
      ),
      _SectionTitle(text: '水印'),
      _SwitchRow(
        label: '启用水印',
        value: settings.watermark.enabled,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(enabled: value),
          ),
        ),
      ),
      const SizedBox(height: 12),
      GlassTextField(
        controller: watermarkController,
        placeholder: '自定义文字',
        prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
        quality: GlassQuality.standard,
      ),
      const SizedBox(height: 12),
      _EnumRow<WatermarkModeOption>(
        value: settings.watermark.textMode,
        values: WatermarkModeOption.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(textMode: value),
          ),
        ),
      ),
      _EnumRow<WatermarkPosition>(
        value: settings.watermark.position,
        values: WatermarkPosition.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(position: value),
          ),
        ),
      ),
      _EnumRow<MonoColor>(
        value: settings.watermark.textColor,
        values: MonoColor.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(textColor: value),
          ),
        ),
      ),
      _EnumRow<WatermarkFontFamily>(
        value: settings.watermark.fontFamily,
        values: WatermarkFontFamily.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(fontFamily: value),
          ),
        ),
      ),
      _SliderRow(
        label: '透明度 ${settings.watermark.opacity}',
        value: settings.watermark.opacity.toDouble(),
        min: 0,
        max: 100,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(opacity: value.round()),
          ),
        ),
      ),
      _SliderRow(
        label: '字体缩放 ${(settings.watermark.sizeScale * 100).round()}%',
        value: settings.watermark.sizeScale * 100,
        min: 25,
        max: 250,
        onChanged: (value) => onSettingsChanged(
          settings.copyWith(
            watermark: settings.watermark.copyWith(sizeScale: value / 100),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildColorBorderSections(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return [
      _SectionTitle(text: '模式说明'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
        ),
        child: Text(
          '该模式会自动为导入图片生成白色留边，并从画面中提取 5 种主色，展示为底部圆点和 RGB 编号。',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.76),
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      _SectionTitle(text: '导出'),
      _EnumRow<ExportFormatOption>(
        value: exportFormat,
        values: ExportFormatOption.values,
        labelBuilder: (item) => item.label,
        onChanged: onExportFormatChanged,
      ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
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
    final accent = _editorAccentColor(context);

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
    final colors = Theme.of(context).colorScheme;
    final accent = _editorAccentColor(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        GlassSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: accent,
          quality: GlassQuality.standard,
        ),
      ],
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
    final accent = _editorAccentColor(context);

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

Color _editorAccentColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFFC7FF12) : const Color(0xFF238E54);
}
