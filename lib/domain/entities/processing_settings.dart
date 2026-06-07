library;

import 'package:adaptive_glass_flutter/domain/entities/enums.dart';
import 'package:adaptive_glass_flutter/domain/entities/layout_info.dart';
import 'package:adaptive_glass_flutter/domain/entities/exif_data.dart';
import 'package:adaptive_glass_flutter/domain/entities/palette_entry.dart';

/// 处理设置（领域层版本）
class ProcessingSettings {
  const ProcessingSettings({
    this.template = TemplateVariant.classic,
    this.targetRatio = 0,
    this.blurMode = BlurMode.standard,
    this.blurRadius = 35,
    this.blurBrightness = 0,
    this.borderStyle = BorderStyle.rounded,
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

  final TemplateVariant template;
  final double targetRatio; // 0 表示原图比例
  final BlurMode blurMode;
  final int blurRadius;
  final int blurBrightness;
  final BorderStyle borderStyle;
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
    TemplateVariant? template,
    double? targetRatio,
    BlurMode? blurMode,
    int? blurRadius,
    int? blurBrightness,
    BorderStyle? borderStyle,
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
}

/// 水印设置
class WatermarkSettings {
  const WatermarkSettings({
    this.enabled = true,
    this.text = '',
    this.textMode = WatermarkMode.append,
    this.textColor = MonoColor.white,
    this.fontSize = 20,
    this.autoSize = true,
    this.opacity = 100,
    this.position = WatermarkPosition.bottomCenter,
    this.customX = 0,
    this.customY = 0,
    this.sizeScale = 1.0,
    this.fontFamily = WatermarkFontFamily.system,
  });

  final bool enabled;
  final String text;
  final WatermarkMode textMode;
  final MonoColor textColor;
  final int fontSize;
  final bool autoSize;
  final int opacity;
  final WatermarkPosition position;
  final int customX;
  final int customY;
  final double sizeScale;
  final WatermarkFontFamily fontFamily;

  WatermarkSettings copyWith({
    bool? enabled,
    String? text,
    WatermarkMode? textMode,
    MonoColor? textColor,
    int? fontSize,
    bool? autoSize,
    int? opacity,
    WatermarkPosition? position,
    int? customX,
    int? customY,
    double? sizeScale,
    WatermarkFontFamily? fontFamily,
  }) {
    return WatermarkSettings(
      enabled: enabled ?? this.enabled,
      text: text ?? this.text,
      textMode: textMode ?? this.textMode,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      autoSize: autoSize ?? this.autoSize,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
      customX: customX ?? this.customX,
      customY: customY ?? this.customY,
      sizeScale: sizeScale ?? this.sizeScale,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// 色彩_walk 设置
class ColorWalkSettings {
  const ColorWalkSettings({
    this.selectedColorIndex = 0,
    this.position = ColorWalkPosition.left,
    this.customText = '',
    this.customTextSize = 24,
    this.showDateTime = false,
    this.dateTimeTextSize = 14,
  });

  final int selectedColorIndex;
  final ColorWalkPosition position;
  final String customText;
  final int customTextSize;
  final bool showDateTime;
  final int dateTimeTextSize;

  ColorWalkSettings copyWith({
    int? selectedColorIndex,
    ColorWalkPosition? position,
    String? customText,
    int? customTextSize,
    bool? showDateTime,
    int? dateTimeTextSize,
  }) {
    return ColorWalkSettings(
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      position: position ?? this.position,
      customText: customText ?? this.customText,
      customTextSize: customTextSize ?? this.customTextSize,
      showDateTime: showDateTime ?? this.showDateTime,
      dateTimeTextSize: dateTimeTextSize ?? this.dateTimeTextSize,
    );
  }
}

/// 经典信息边框设置
class ClassicInfoBorderSettings {
  const ClassicInfoBorderSettings({
    this.enabled = true,
    this.logoType = ClassicInfoLogoType.camera,
  });

  final bool enabled;
  final ClassicInfoLogoType logoType;

  ClassicInfoBorderSettings copyWith({
    bool? enabled,
    ClassicInfoLogoType? logoType,
  }) {
    return ClassicInfoBorderSettings(
      enabled: enabled ?? this.enabled,
      logoType: logoType ?? this.logoType,
    );
  }
}
