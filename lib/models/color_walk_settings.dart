enum ColorWalkPosition {
  top,
  bottom,
  left,
  right,
}

extension ColorWalkPositionX on ColorWalkPosition {
  String get storageValue => name;

  String get label => switch (this) {
        ColorWalkPosition.top => '顶部',
        ColorWalkPosition.bottom => '底部',
        ColorWalkPosition.left => '左侧',
        ColorWalkPosition.right => '右侧',
      };

  static ColorWalkPosition fromStorage(String? value) {
    return ColorWalkPosition.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => ColorWalkPosition.bottom,
    );
  }
}

class ColorWalkSettings {
  const ColorWalkSettings({
    this.enabled = true,
    this.selectedColorIndex = 0,
    this.customText = '',
    this.customTextSize = 16,
    this.showDateTime = true,
    this.dateTimeTextSize = 12,
    this.position = ColorWalkPosition.bottom,
    this.contentScale = 60,
  });

  final bool enabled;
  final int selectedColorIndex;
  final String customText;
  final int customTextSize;
  final bool showDateTime;
  final int dateTimeTextSize;
  final ColorWalkPosition position;
  final int contentScale;

  ColorWalkSettings copyWith({
    bool? enabled,
    int? selectedColorIndex,
    String? customText,
    int? customTextSize,
    bool? showDateTime,
    int? dateTimeTextSize,
    ColorWalkPosition? position,
    int? contentScale,
  }) {
    return ColorWalkSettings(
      enabled: enabled ?? this.enabled,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      customText: customText ?? this.customText,
      customTextSize: customTextSize ?? this.customTextSize,
      showDateTime: showDateTime ?? this.showDateTime,
      dateTimeTextSize: dateTimeTextSize ?? this.dateTimeTextSize,
      position: position ?? this.position,
      contentScale: contentScale ?? this.contentScale,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'selected_color_index': selectedColorIndex,
      'custom_text': customText,
      'custom_text_size': customTextSize,
      'show_date_time': showDateTime,
      'date_time_text_size': dateTimeTextSize,
      'position': position.storageValue,
      'content_scale': contentScale,
    };
  }

  factory ColorWalkSettings.fromJson(Map<String, dynamic> json) {
    return ColorWalkSettings(
      enabled: json['enabled'] as bool? ?? true,
      selectedColorIndex: (json['selected_color_index'] as num?)?.round() ?? 0,
      customText: json['custom_text'] as String? ?? '',
      customTextSize: (json['custom_text_size'] as num?)?.round() ?? 16,
      showDateTime: json['show_date_time'] as bool? ?? true,
      dateTimeTextSize: (json['date_time_text_size'] as num?)?.round() ?? 12,
      position: ColorWalkPositionX.fromStorage(json['position'] as String?),
      contentScale: (json['content_scale'] as num?)?.round() ?? 60,
    );
  }
}