import 'dart:convert';

enum RatioPreset {
  square,
  fourThree,
  threeTwo,
  wide,
  portrait,
  cinema,
  original,
}

extension RatioPresetX on RatioPreset {
  String get storageKey => switch (this) {
    RatioPreset.square => 'R_1_1',
    RatioPreset.fourThree => 'R_4_3',
    RatioPreset.threeTwo => 'R_3_2',
    RatioPreset.wide => 'R_16_9',
    RatioPreset.portrait => 'R_9_16',
    RatioPreset.cinema => 'R_2_35_1',
    RatioPreset.original => 'ORIGINAL',
  };

  String get label => switch (this) {
    RatioPreset.square => '1:1',
    RatioPreset.fourThree => '4:3',
    RatioPreset.threeTwo => '3:2',
    RatioPreset.wide => '16:9',
    RatioPreset.portrait => '9:16',
    RatioPreset.cinema => '2.35:1',
    RatioPreset.original => '原图比例',
  };

  ({int width, int height})? get dimensions => switch (this) {
    RatioPreset.square => (width: 1, height: 1),
    RatioPreset.fourThree => (width: 4, height: 3),
    RatioPreset.threeTwo => (width: 3, height: 2),
    RatioPreset.wide => (width: 16, height: 9),
    RatioPreset.portrait => (width: 9, height: 16),
    RatioPreset.cinema => (width: 235, height: 100),
    RatioPreset.original => null,
  };

  static RatioPreset fromStorage(String? value) {
    return RatioPreset.values.firstWhere(
      (item) => item.storageKey == value,
      orElse: () => RatioPreset.original,
    );
  }
}

enum BlurModeOption { standard, dark, light }

extension BlurModeOptionX on BlurModeOption {
  String get storageValue => name;

  String get label => switch (this) {
    BlurModeOption.standard => '标准模糊',
    BlurModeOption.dark => '深色玻璃',
    BlurModeOption.light => '浅色玻璃',
  };

  static BlurModeOption fromStorage(String? value) {
    return BlurModeOption.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => BlurModeOption.standard,
    );
  }
}

enum BorderStyleOption { none, thin, rounded }

extension BorderStyleOptionX on BorderStyleOption {
  String get storageValue => name;

  String get label => switch (this) {
    BorderStyleOption.none => '无边框',
    BorderStyleOption.thin => '细边框',
    BorderStyleOption.rounded => '圆角边框',
  };

  static BorderStyleOption fromStorage(String? value) {
    return BorderStyleOption.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => BorderStyleOption.rounded,
    );
  }
}

enum MonoColor { white, black }

extension MonoColorX on MonoColor {
  String get storageValue => name;

  String get label => switch (this) {
    MonoColor.white => '白色',
    MonoColor.black => '黑色',
  };

  static MonoColor fromStorage(String? value) {
    return MonoColor.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => MonoColor.white,
    );
  }
}

enum WatermarkModeOption { replace, fallback, append }

extension WatermarkModeOptionX on WatermarkModeOption {
  String get storageValue => name;

  String get label => switch (this) {
    WatermarkModeOption.replace => '仅自定义',
    WatermarkModeOption.fallback => '缺省补充',
    WatermarkModeOption.append => '追加文本',
  };

  static WatermarkModeOption fromStorage(String? value) {
    return WatermarkModeOption.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => WatermarkModeOption.append,
    );
  }
}

enum WatermarkPosition {
  bottomCenter,
  bottomRight,
  bottomLeft,
  topCenter,
  topRight,
  topLeft,
  center,
  centerRight,
  centerLeft,
  manual,
}

extension WatermarkPositionX on WatermarkPosition {
  String get storageValue => switch (this) {
    WatermarkPosition.bottomCenter => 'bottom_center',
    WatermarkPosition.bottomRight => 'bottom_right',
    WatermarkPosition.bottomLeft => 'bottom_left',
    WatermarkPosition.topCenter => 'top_center',
    WatermarkPosition.topRight => 'top_right',
    WatermarkPosition.topLeft => 'top_left',
    WatermarkPosition.center => 'center',
    WatermarkPosition.centerRight => 'center_right',
    WatermarkPosition.centerLeft => 'center_left',
    WatermarkPosition.manual => 'manual',
  };

  String get label => switch (this) {
    WatermarkPosition.bottomCenter => '底部居中',
    WatermarkPosition.bottomRight => '右下角',
    WatermarkPosition.bottomLeft => '左下角',
    WatermarkPosition.topCenter => '顶部居中',
    WatermarkPosition.topRight => '右上角',
    WatermarkPosition.topLeft => '左上角',
    WatermarkPosition.center => '居中',
    WatermarkPosition.centerRight => '右侧居中',
    WatermarkPosition.centerLeft => '左侧居中',
    WatermarkPosition.manual => '手动偏移',
  };

  static WatermarkPosition fromStorage(String? value) {
    return WatermarkPosition.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => WatermarkPosition.bottomCenter,
    );
  }
}

enum WatermarkFontFamily { system, smileySans }

extension WatermarkFontFamilyX on WatermarkFontFamily {
  String get storageValue => name;

  String get label => switch (this) {
    WatermarkFontFamily.system => '系统字体',
    WatermarkFontFamily.smileySans => '得意黑',
  };

  static WatermarkFontFamily fromStorage(String? value) {
    return WatermarkFontFamily.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => WatermarkFontFamily.system,
    );
  }
}

class WatermarkSettings {
  const WatermarkSettings({
    this.enabled = true,
    this.text = '',
    this.textMode = WatermarkModeOption.append,
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
  final WatermarkModeOption textMode;
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
    WatermarkModeOption? textMode,
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'text': text,
      'text_mode': textMode.storageValue,
      'text_color': textColor.storageValue,
      'font_size': fontSize,
      'auto_size': autoSize,
      'opacity': opacity,
      'position': position.storageValue,
      'custom_x': customX,
      'custom_y': customY,
      'size_scale': sizeScale,
      'font_family': fontFamily.storageValue,
    };
  }

  factory WatermarkSettings.fromJson(Map<String, dynamic> json) {
    return WatermarkSettings(
      enabled: json['enabled'] as bool? ?? true,
      text: json['text'] as String? ?? '',
      textMode: WatermarkModeOptionX.fromStorage(json['text_mode'] as String?),
      textColor: MonoColorX.fromStorage(json['text_color'] as String?),
      fontSize: (json['font_size'] as num?)?.round() ?? 20,
      autoSize: json['auto_size'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.round() ?? 100,
      position: WatermarkPositionX.fromStorage(json['position'] as String?),
      customX: (json['custom_x'] as num?)?.round() ?? 0,
      customY: (json['custom_y'] as num?)?.round() ?? 0,
      sizeScale: (json['size_scale'] as num?)?.toDouble() ?? 1.0,
      fontFamily: WatermarkFontFamilyX.fromStorage(
        json['font_family'] as String?,
      ),
    );
  }
}

class ProcessingSettings {
  const ProcessingSettings({
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
  });

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

  ProcessingSettings copyWith({
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
  }) {
    return ProcessingSettings(
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
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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
    };
  }

  factory ProcessingSettings.fromJson(Map<String, dynamic> json) {
    return ProcessingSettings(
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
    );
  }

  String toPresetString() => jsonEncode(toJson());

  factory ProcessingSettings.fromPresetString(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return ProcessingSettings.fromJson(decoded);
  }
}
