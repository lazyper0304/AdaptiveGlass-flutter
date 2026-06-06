import 'dart:convert';

import 'classic_info_border_settings.dart';
import 'color_walk_settings.dart';
import 'enums.dart';
import 'frame_template.dart';
import 'watermark_settings.dart';

export 'enums.dart';
export 'watermark_settings.dart';

class ProcessingSettings {
  const ProcessingSettings({
    this.template = FrameTemplate.classic,
    this.targetRatio = RatioPreset.original,
    this.blurMode = BlurModeOption.standard,
    this.blurRadius = 35,
    this.blurBrightness = 0,
    this.borderStyle = BorderStyleOption.rounded,
    this.borderColor = MonoColor.black,
    this.borderWidth = 0,
    this.cornerRadius = 20,
    this.shadowSize = 20,
    this.contentScale = 90,
    this.exportQuality = 95,
    this.watermark = const WatermarkSettings(),
    this.classicInfoBorder = const ClassicInfoBorderSettings(),
    this.colorWalk = const ColorWalkSettings(),
  });

  final FrameTemplate template;
  final RatioPreset targetRatio;
  final BlurModeOption blurMode;
  final int blurRadius;
  final int blurBrightness;
  final BorderStyleOption borderStyle;
  final MonoColor borderColor;
  final int borderWidth;
  final int cornerRadius;
  final int shadowSize;
  final int contentScale;
  final int exportQuality;
  final WatermarkSettings watermark;
  final ClassicInfoBorderSettings classicInfoBorder;
  final ColorWalkSettings colorWalk;

  ProcessingSettings copyWith({
    FrameTemplate? template,
    RatioPreset? targetRatio,
    BlurModeOption? blurMode,
    int? blurRadius,
    int? blurBrightness,
    BorderStyleOption? borderStyle,
    MonoColor? borderColor,
    int? borderWidth,
    int? cornerRadius,
    int? shadowSize,
    int? contentScale,
    int? exportQuality,
    WatermarkSettings? watermark,
    ClassicInfoBorderSettings? classicInfoBorder,
    ColorWalkSettings? colorWalk,
  }) {
    return ProcessingSettings(
      template: template ?? this.template,
      targetRatio: targetRatio ?? this.targetRatio,
      blurMode: blurMode ?? this.blurMode,
      blurRadius: blurRadius ?? this.blurRadius,
      blurBrightness: blurBrightness ?? this.blurBrightness,
      borderStyle: borderStyle ?? this.borderStyle,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      shadowSize: shadowSize ?? this.shadowSize,
      contentScale: contentScale ?? this.contentScale,
      exportQuality: exportQuality ?? this.exportQuality,
      watermark: watermark ?? this.watermark,
      classicInfoBorder: classicInfoBorder ?? this.classicInfoBorder,
      colorWalk: colorWalk ?? this.colorWalk,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'template': template.storageValue,
      'target_ratio': targetRatio.storageKey,
      'blur_mode': blurMode.storageValue,
      'blur_radius': blurRadius,
      'blur_brightness': blurBrightness,
      'border_style': borderStyle.storageValue,
      'border_color': borderColor.storageValue,
      'border_width': borderWidth,
      'corner_radius': cornerRadius,
      'shadow_size': shadowSize,
      'content_scale': contentScale,
      'export_quality': exportQuality,
      'watermark': watermark.toJson(),
      'classic_info_border': classicInfoBorder.toJson(),
      'color_walk': colorWalk.toJson(),
    };
  }

  factory ProcessingSettings.fromJson(Map<String, dynamic> json) {
    return ProcessingSettings(
      template: FrameTemplateX.fromStorage(json['template'] as String?),
      targetRatio: RatioPresetX.fromStorage(json['target_ratio'] as String?),
      blurMode: BlurModeOptionX.fromStorage(json['blur_mode'] as String?),
      blurRadius: (json['blur_radius'] as num?)?.round() ?? 35,
      blurBrightness: (json['blur_brightness'] as num?)?.round() ?? 0,
      borderStyle: BorderStyleOptionX.fromStorage(
        json['border_style'] as String?,
      ),
      borderColor: MonoColorX.fromStorage(json['border_color'] as String?),
      borderWidth: (json['border_width'] as num?)?.round() ?? 0,
      cornerRadius: (json['corner_radius'] as num?)?.round() ?? 20,
      shadowSize: (json['shadow_size'] as num?)?.round() ?? 20,
      contentScale: (json['content_scale'] as num?)?.round() ?? 90,
      exportQuality: (json['export_quality'] as num?)?.round() ?? 95,
      watermark: WatermarkSettings.fromJson(
        Map<String, dynamic>.from(json['watermark'] as Map? ?? const {}),
      ),
      classicInfoBorder: ClassicInfoBorderSettings.fromJson(
        Map<String, dynamic>.from(
          json['classic_info_border'] as Map? ?? const {},
        ),
      ),
      colorWalk: ColorWalkSettings.fromJson(
        Map<String, dynamic>.from(json['color_walk'] as Map? ?? const {}),
      ),
    );
  }

  String toPresetString() => jsonEncode(toJson());

  factory ProcessingSettings.fromPresetString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ProcessingSettings.fromJson(decoded);
  }
}
