/// 应用常量定义
class AppConstants {
  AppConstants._();

  // 应用信息
  static const String appName = 'AdaptiveGlass';
  static const String packageName = 'adaptive_glass_flutter';
  static String get version => '1.0.8';

  // GitHub 仓库信息（用于更新检查）
  static const String githubRepoOwner = 'your-username';
  static const String githubRepoName = 'adaptive-glass-flutter';

  // 文件相关
  static const String presetExtension = 'agp';
  static const List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'bmp', 'webp', 'tif', 'tiff'];
  static const String presetMimeType = 'application/vnd.adaptiveglass.preset';

  // 预览渲染配置
  static const int previewMinDimension = 720;
  static const int previewMaxDimension = 1600;
  static const int previewDebounceMs = 120;

  // 导出配置
  static const int defaultExportQuality = 95;
  static const int thumbnailSize = 200;
  static const int thumbnailQuality = 70;

  // UI 配置
  static const double defaultSpacing = 8.0;
  static const double smallSpacing = 4.0;
  static const double largeSpacing = 16.0;
  static const double borderRadius = 18.0;
  static const double largeBorderRadius = 24.0;
  static const double superellipseRadius = 28.0;

  // 动画配置
  static const int navigationTransitionDurationMs = 600;
  static const int pageTransitionDurationMs = 300;
  static const int panelTransitionDurationMs = 220;
}
