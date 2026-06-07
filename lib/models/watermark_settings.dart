import 'enums.dart';

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
