library;

/// 模板变体类型
enum TemplateVariant {
  classic,
  colorBorder,
  watermarkBorder,
  colorWalk,
}

extension TemplateVariantX on TemplateVariant {
  String get storageValue => name;

  static TemplateVariant fromStorage(String? value) {
    return TemplateVariant.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => TemplateVariant.classic,
    );
  }
}
