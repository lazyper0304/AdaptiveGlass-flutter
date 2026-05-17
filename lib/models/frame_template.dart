enum FrameTemplate { classic, colorBorder }

extension FrameTemplateX on FrameTemplate {
  String get storageValue => name;

  String get heroTag => 'editor-title-$storageValue';

  static FrameTemplate fromStorage(String? value) {
    return FrameTemplate.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => FrameTemplate.classic,
    );
  }
}
