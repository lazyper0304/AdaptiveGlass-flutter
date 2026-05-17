import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/frame_template.dart';
import '../../../models/processing_settings.dart';
import '../models/export_format_option.dart';
import 'classic_info_border_section.dart';
import 'tappable_switch_row.dart';

enum _ClassicSettingsCategory {
  canvas('画布'),
  background('背景'),
  frame('边框'),
  infoBorder('信息边框'),
  watermark('水印'),
  export('导出');

  const _ClassicSettingsCategory(this.label);

  final String label;
}

class EditorSettingsPanel extends StatefulWidget {
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
  State<EditorSettingsPanel> createState() => _EditorSettingsPanelState();
}

class _EditorSettingsPanelState extends State<EditorSettingsPanel> {
  _ClassicSettingsCategory _category = _ClassicSettingsCategory.canvas;

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
          children: switch (widget.template) {
            FrameTemplate.classic => _buildClassicSections(context),
            FrameTemplate.watermarkBorder => _buildClassicSections(context),
            FrameTemplate.colorBorder => _buildColorBorderSections(context),
          },
        ),
      ),
    );
  }

  List<_ClassicSettingsCategory> _categoriesForTemplate() {
    return switch (widget.template) {
      FrameTemplate.classic => const [
        _ClassicSettingsCategory.canvas,
        _ClassicSettingsCategory.background,
        _ClassicSettingsCategory.frame,
        _ClassicSettingsCategory.watermark,
        _ClassicSettingsCategory.export,
      ],
      FrameTemplate.watermarkBorder => const [
        _ClassicSettingsCategory.canvas,
        _ClassicSettingsCategory.frame,
        _ClassicSettingsCategory.infoBorder,
        _ClassicSettingsCategory.export,
      ],
      FrameTemplate.colorBorder => const [_ClassicSettingsCategory.export],
    };
  }

  List<Widget> _buildClassicSections(BuildContext context) {
    final categories = _categoriesForTemplate();
    final activeCategory = categories.contains(_category)
        ? _category
        : categories.first;

    return [
      const _SectionTitle(text: '参数分类'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: categories
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GlassChip(
                    label: item.label,
                    selected: activeCategory == item,
                    selectedColor: _editorAccentColor(
                      context,
                    ).withValues(alpha: 0.22),
                    labelStyle: TextStyle(
                      color: activeCategory == item
                          ? _editorAccentColor(context)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.82),
                      fontWeight: activeCategory == item
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                    onTap: () => setState(() {
                      _category = item;
                    }),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 10),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(activeCategory),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _classicCategoryContent(activeCategory),
          ),
        ),
      ),
    ];
  }

  List<Widget> _classicCategoryContent(_ClassicSettingsCategory category) {
    final settings = widget.settings;

    return switch (category) {
      _ClassicSettingsCategory.canvas => [
        const _SectionTitle(text: '画布比例'),
        _EnumRow<RatioPreset>(
          value: settings.targetRatio,
          values: RatioPreset.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(targetRatio: value)),
        ),
        _SliderRow(
          label: '内容缩放 ${settings.contentScale}%',
          value: settings.contentScale.toDouble(),
          min: 50,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(contentScale: value.round()),
          ),
        ),
      ],
      _ClassicSettingsCategory.background => [
        const _SectionTitle(text: '背景'),
        _SliderRow(
          label: '模糊半径 ${settings.blurRadius}',
          value: settings.blurRadius.toDouble(),
          min: 0,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(blurRadius: value.round()),
          ),
        ),
        _SliderRow(
          label: '背景亮度 ${settings.blurBrightness}',
          value: settings.blurBrightness.toDouble(),
          min: -100,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(blurBrightness: value.round()),
          ),
        ),
        _EnumRow<BlurModeOption>(
          value: settings.blurMode,
          values: BlurModeOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(blurMode: value)),
        ),
      ],
      _ClassicSettingsCategory.frame => [
        const _SectionTitle(text: '边框'),
        _EnumRow<BorderStyleOption>(
          value: settings.borderStyle,
          values: BorderStyleOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(borderStyle: value)),
        ),
        _SliderRow(
          label: '边框宽度 ${settings.borderWidth}',
          value: settings.borderWidth.toDouble(),
          min: 0,
          max: 50,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(borderWidth: value.round()),
          ),
        ),
        _SliderRow(
          label: '圆角半径 ${settings.cornerRadius}',
          value: settings.cornerRadius.toDouble(),
          min: 0,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(cornerRadius: value.round()),
          ),
        ),
        _SliderRow(
          label: '阴影强度 ${settings.shadowSize}',
          value: settings.shadowSize.toDouble(),
          min: 0,
          max: 50,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(shadowSize: value.round()),
          ),
        ),
        _EnumRow<MonoColor>(
          value: settings.borderColor,
          values: MonoColor.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(borderColor: value)),
        ),
      ],
      _ClassicSettingsCategory.infoBorder => [
        const _SectionTitle(text: '底部信息边框'),
        ClassicInfoBorderSection(
          settings: settings.classicInfoBorder,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(classicInfoBorder: value),
          ),
        ),
      ],
      _ClassicSettingsCategory.watermark => [
        const _SectionTitle(text: '文字水印'),
        _SwitchRow(
          label: '启用水印',
          value: settings.watermark.enabled,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(enabled: value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: widget.watermarkController,
          placeholder: '自定义水印文字',
          prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
          quality: GlassQuality.standard,
        ),
        const SizedBox(height: 12),
        _EnumRow<WatermarkModeOption>(
          value: settings.watermark.textMode,
          values: WatermarkModeOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(textMode: value),
            ),
          ),
        ),
        _EnumRow<WatermarkPosition>(
          value: settings.watermark.position == WatermarkPosition.manual
              ? WatermarkPosition.bottomCenter
              : settings.watermark.position,
          values: WatermarkPosition.values
              .where((item) => item != WatermarkPosition.manual)
              .toList(),
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(position: value),
            ),
          ),
        ),
        _EnumRow<MonoColor>(
          value: settings.watermark.textColor,
          values: MonoColor.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(textColor: value),
            ),
          ),
        ),
        _EnumRow<WatermarkFontFamily>(
          value: settings.watermark.fontFamily,
          values: WatermarkFontFamily.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
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
          onChanged: (value) => widget.onSettingsChanged(
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
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(sizeScale: value / 100),
            ),
          ),
        ),
      ],
      _ClassicSettingsCategory.export => [
        const _SectionTitle(text: '导出'),
        _EnumRow<ExportFormatOption>(
          value: widget.exportFormat,
          values: ExportFormatOption.values,
          labelBuilder: (item) => item.label,
          onChanged: widget.onExportFormatChanged,
        ),
      ],
    };
  }

  List<Widget> _buildColorBorderSections(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return [
      const _SectionTitle(text: '模式说明'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
        ),
        child: Text(
          '该模式会自动为导入图片生成白色边框，并从画面中提取五种主色，以下方色点和 RGB 数值的形式展示。',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.76),
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const _SectionTitle(text: '导出'),
      _EnumRow<ExportFormatOption>(
        value: widget.exportFormat,
        values: ExportFormatOption.values,
        labelBuilder: (item) => item.label,
        onChanged: widget.onExportFormatChanged,
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
    final accent = _editorAccentColor(context);

    return TappableSwitchRow(
      label: label,
      value: value,
      onChanged: onChanged,
      activeColor: accent,
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
