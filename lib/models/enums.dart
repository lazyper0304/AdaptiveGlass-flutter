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
