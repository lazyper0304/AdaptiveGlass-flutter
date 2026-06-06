import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../models/color_walk_settings.dart';
import '../../../models/frame_template.dart';
import '../../../models/processing_settings.dart';
import '../../../services/frame_processing_models.dart';
import '../../../shared/app_theme.dart';
import '../models/export_format_option.dart';
import 'classic_info_border_section.dart';
import 'editor_settings_widgets.dart';

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
    this.palette = const [],
  });

  final FrameTemplate template;
  final ProcessingSettings settings;
  final ExportFormatOption exportFormat;
  final TextEditingController watermarkController;
  final ValueChanged<ProcessingSettings> onSettingsChanged;
  final ValueChanged<ExportFormatOption> onExportFormatChanged;
  final List<PaletteSwatch> palette;

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
            FrameTemplate.colorWalk => _buildColorWalkSections(context),
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
        _ClassicSettingsCategory.watermark,
        _ClassicSettingsCategory.export,
      ],
      FrameTemplate.colorBorder => const [_ClassicSettingsCategory.export],
      FrameTemplate.colorWalk => const [_ClassicSettingsCategory.export],
    };
  }

  List<Widget> _buildClassicSections(BuildContext context) {
    final categories = _categoriesForTemplate();
    final activeCategory = categories.contains(_category)
        ? _category
        : categories.first;

    return [
      const SectionTitle(text: '参数分类'),
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
                    selectedColor: context.accentColor.withValues(alpha: 0.22),
                    labelStyle: TextStyle(
                      color: activeCategory == item
                          ? context.accentColor
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
        const SectionTitle(text: '画布比例'),
        SettingsEnumRow<RatioPreset>(
          value: settings.targetRatio,
          values: RatioPreset.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(targetRatio: value)),
        ),
        SettingsSliderRow(
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
        const SectionTitle(text: '背景'),
        SettingsSliderRow(
          label: '模糊半径 ${settings.blurRadius}',
          value: settings.blurRadius.toDouble(),
          min: 0,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(blurRadius: value.round()),
          ),
        ),
        SettingsSliderRow(
          label: '背景亮度 ${settings.blurBrightness}',
          value: settings.blurBrightness.toDouble(),
          min: -100,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(blurBrightness: value.round()),
          ),
        ),
        SettingsEnumRow<BlurModeOption>(
          value: settings.blurMode,
          values: BlurModeOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(blurMode: value)),
        ),
      ],
      _ClassicSettingsCategory.frame => [
        const SectionTitle(text: '边框'),
        SettingsEnumRow<BorderStyleOption>(
          value: settings.borderStyle,
          values: BorderStyleOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(borderStyle: value)),
        ),
        SettingsSliderRow(
          label: '边框宽度 ${settings.borderWidth}',
          value: settings.borderWidth.toDouble(),
          min: 0,
          max: 50,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(borderWidth: value.round()),
          ),
        ),
        SettingsSliderRow(
          label: '圆角半径 ${settings.cornerRadius}',
          value: settings.cornerRadius.toDouble(),
          min: 0,
          max: 100,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(cornerRadius: value.round()),
          ),
        ),
        SettingsSliderRow(
          label: '阴影强度 ${settings.shadowSize}',
          value: settings.shadowSize.toDouble(),
          min: 0,
          max: 50,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(shadowSize: value.round()),
          ),
        ),
        SettingsEnumRow<MonoColor>(
          value: settings.borderColor,
          values: MonoColor.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) =>
              widget.onSettingsChanged(settings.copyWith(borderColor: value)),
        ),
      ],
      _ClassicSettingsCategory.infoBorder => [
        const SectionTitle(text: '底部信息边框'),
        ClassicInfoBorderSection(
          settings: settings.classicInfoBorder,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(classicInfoBorder: value),
          ),
        ),
      ],
      _ClassicSettingsCategory.watermark => [
        const SectionTitle(text: '文字水印'),
        SettingsSwitchRow(
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
        SettingsEnumRow<WatermarkModeOption>(
          value: settings.watermark.textMode,
          values: WatermarkModeOption.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(textMode: value),
            ),
          ),
        ),
        SettingsEnumRow<WatermarkPosition>(
          value: settings.watermark.position,
          values: WatermarkPosition.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(position: value),
            ),
          ),
        ),
        if (settings.watermark.position == WatermarkPosition.manual) ...[
          SettingsSliderRow(
            label: '水平偏移 ${settings.watermark.customX}',
            value: settings.watermark.customX.toDouble(),
            min: -500,
            max: 500,
            onChanged: (value) => widget.onSettingsChanged(
              settings.copyWith(
                watermark: settings.watermark.copyWith(customX: value.round()),
              ),
            ),
          ),
          SettingsSliderRow(
            label: '垂直偏移 ${settings.watermark.customY}',
            value: settings.watermark.customY.toDouble(),
            min: -500,
            max: 500,
            onChanged: (value) => widget.onSettingsChanged(
              settings.copyWith(
                watermark: settings.watermark.copyWith(customY: value.round()),
              ),
            ),
          ),
        ],
        SettingsEnumRow<MonoColor>(
          value: settings.watermark.textColor,
          values: MonoColor.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(textColor: value),
            ),
          ),
        ),
        SettingsEnumRow<WatermarkFontFamily>(
          value: settings.watermark.fontFamily,
          values: WatermarkFontFamily.values,
          labelBuilder: (item) => item.label,
          onChanged: (value) => widget.onSettingsChanged(
            settings.copyWith(
              watermark: settings.watermark.copyWith(fontFamily: value),
            ),
          ),
        ),
        SettingsSliderRow(
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
        SettingsSliderRow(
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
        const SectionTitle(text: '导出'),
        SettingsEnumRow<ExportFormatOption>(
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
      const SectionTitle(text: '模式说明'),
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
      const SectionTitle(text: '导出'),
      SettingsEnumRow<ExportFormatOption>(
        value: widget.exportFormat,
        values: ExportFormatOption.values,
        labelBuilder: (item) => item.label,
        onChanged: widget.onExportFormatChanged,
      ),
    ];
  }

  List<Widget> _buildColorWalkSections(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settings = widget.settings.colorWalk;
    final palette = widget.palette;

    return [
      const SectionTitle(text: '模式说明'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
        ),
        child: Text(
          'Color Walk 模式：从图片取色作为背景，显示上传的图片。从图片中提取五种主色，选择一种作为背景色。',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.76),
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SectionTitle(text: '选择背景色'),
      if (palette.isEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '请先导入图片以提取颜色',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        )
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: palette
              .asMap()
              .entries
              .map(
                (entry) => ColorSelector(
                  color: entry.value.toColor(),
                  selected: settings.selectedColorIndex == entry.key,
                  onTap: () => widget.onSettingsChanged(
                    widget.settings.copyWith(
                      colorWalk: settings.copyWith(selectedColorIndex: entry.key),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      const SizedBox(height: 8),
      const SectionTitle(text: '排布位置'),
      SettingsEnumRow<ColorWalkPosition>(
        value: settings.position,
        values: ColorWalkPosition.values,
        labelBuilder: (item) => item.label,
        onChanged: (value) => widget.onSettingsChanged(
          widget.settings.copyWith(
            colorWalk: settings.copyWith(position: value),
          ),
        ),
      ),
      const SectionTitle(text: '自定义文字'),
      ColorWalkTextField(
        initialText: settings.customText,
        onChanged: (value) => widget.onSettingsChanged(
          widget.settings.copyWith(
            colorWalk: settings.copyWith(customText: value),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SettingsSliderRow(
        label: '文字大小 ${settings.customTextSize}px',
        value: settings.customTextSize.toDouble(),
        min: 12,
        max: 32,
        onChanged: (value) => widget.onSettingsChanged(
          widget.settings.copyWith(
            colorWalk: settings.copyWith(customTextSize: value.round()),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SettingsSwitchRow(
        label: '显示拍摄时间',
        value: settings.showDateTime,
        onChanged: (value) => widget.onSettingsChanged(
          widget.settings.copyWith(
            colorWalk: settings.copyWith(showDateTime: value),
          ),
        ),
      ),
      if (settings.showDateTime)
        SettingsSliderRow(
          label: '时间文字大小 ${settings.dateTimeTextSize}px',
          value: settings.dateTimeTextSize.toDouble(),
          min: 10,
          max: 24,
          onChanged: (value) => widget.onSettingsChanged(
            widget.settings.copyWith(
              colorWalk: settings.copyWith(dateTimeTextSize: value.round()),
            ),
          ),
        ),
      const SectionTitle(text: '导出'),
      SettingsEnumRow<ExportFormatOption>(
        value: widget.exportFormat,
        values: ExportFormatOption.values,
        labelBuilder: (item) => item.label,
        onChanged: widget.onExportFormatChanged,
      ),
    ];
  }
}
