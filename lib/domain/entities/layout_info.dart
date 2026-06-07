library;

/// 布局信息
class LayoutInfo {
  const LayoutInfo({
    required this.targetWidth,
    required this.targetHeight,
    required this.contentX,
    required this.contentY,
    required this.contentWidth,
    required this.contentHeight,
    this.infoPanelTop = 0,
    this.infoPanelHeight = 0,
  });

  final int targetWidth;
  final int targetHeight;
  final int contentX;
  final int contentY;
  final int contentWidth;
  final int contentHeight;
  final int infoPanelTop;
  final int infoPanelHeight;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'target_width': targetWidth,
      'target_height': targetHeight,
      'content_x': contentX,
      'content_y': contentY,
      'content_width': contentWidth,
      'content_height': contentHeight,
      'info_panel_top': infoPanelTop,
      'info_panel_height': infoPanelHeight,
    };
  }

  factory LayoutInfo.fromJson(Map<String, dynamic> json) {
    return LayoutInfo(
      targetWidth: (json['target_width'] as num).round(),
      targetHeight: (json['target_height'] as num).round(),
      contentX: (json['content_x'] as num).round(),
      contentY: (json['content_y'] as num).round(),
      contentWidth: (json['content_width'] as num).round(),
      contentHeight: (json['content_height'] as num).round(),
      infoPanelTop: (json['info_panel_top'] as num?)?.round() ?? 0,
      infoPanelHeight: (json['info_panel_height'] as num?)?.round() ?? 0,
    );
  }
}
