enum ClassicInfoSource { auto, manual }

extension ClassicInfoSourceX on ClassicInfoSource {
  String get storageValue => name;

  String get label => switch (this) {
    ClassicInfoSource.auto => '自动读取',
    ClassicInfoSource.manual => '手动输入',
  };

  static ClassicInfoSource fromStorage(String? value) {
    return ClassicInfoSource.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => ClassicInfoSource.auto,
    );
  }
}

enum CameraLogoOption { auto, none, canon, sony, nikon, leica, hasselblad, dji }

extension CameraLogoOptionX on CameraLogoOption {
  String get storageValue => name;

  String get label => switch (this) {
    CameraLogoOption.auto => '自动匹配',
    CameraLogoOption.none => '不显示',
    CameraLogoOption.canon => 'Canon',
    CameraLogoOption.sony => 'Sony',
    CameraLogoOption.nikon => 'Nikon',
    CameraLogoOption.leica => 'Leica',
    CameraLogoOption.hasselblad => 'Hasselblad',
    CameraLogoOption.dji => 'DJI',
  };

  String? get assetPath => switch (this) {
    CameraLogoOption.auto || CameraLogoOption.none => null,
    CameraLogoOption.canon => 'lib/CameraLogos/Canon.svg',
    CameraLogoOption.sony => 'lib/CameraLogos/Sony.svg',
    CameraLogoOption.nikon => 'lib/CameraLogos/Nikon.svg',
    CameraLogoOption.leica => 'lib/CameraLogos/Leica.svg',
    CameraLogoOption.hasselblad => 'lib/CameraLogos/hasselblad.svg',
    CameraLogoOption.dji => 'lib/CameraLogos/DJI.svg',
  };

  static CameraLogoOption fromStorage(String? value) {
    return CameraLogoOption.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => CameraLogoOption.auto,
    );
  }
}

class ClassicInfoBorderSettings {
  const ClassicInfoBorderSettings({
    this.enabled = false,
    this.metadataSource = ClassicInfoSource.auto,
    this.manualTitle = '',
    this.manualDetails = '',
    this.logo = CameraLogoOption.auto,
    this.logoScale = 1.0,
  });

  final bool enabled;
  final ClassicInfoSource metadataSource;
  final String manualTitle;
  final String manualDetails;
  final CameraLogoOption logo;
  final double logoScale;

  ClassicInfoBorderSettings copyWith({
    bool? enabled,
    ClassicInfoSource? metadataSource,
    String? manualTitle,
    String? manualDetails,
    CameraLogoOption? logo,
    double? logoScale,
  }) {
    return ClassicInfoBorderSettings(
      enabled: enabled ?? this.enabled,
      metadataSource: metadataSource ?? this.metadataSource,
      manualTitle: manualTitle ?? this.manualTitle,
      manualDetails: manualDetails ?? this.manualDetails,
      logo: logo ?? this.logo,
      logoScale: logoScale ?? this.logoScale,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'metadata_source': metadataSource.storageValue,
      'manual_title': manualTitle,
      'manual_details': manualDetails,
      'logo': logo.storageValue,
      'logo_scale': logoScale,
    };
  }

  factory ClassicInfoBorderSettings.fromJson(Map<String, dynamic> json) {
    return ClassicInfoBorderSettings(
      enabled: json['enabled'] as bool? ?? false,
      metadataSource: ClassicInfoSourceX.fromStorage(
        json['metadata_source'] as String?,
      ),
      manualTitle: json['manual_title'] as String? ?? '',
      manualDetails: json['manual_details'] as String? ?? '',
      logo: CameraLogoOptionX.fromStorage(json['logo'] as String?),
      logoScale: (json['logo_scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
