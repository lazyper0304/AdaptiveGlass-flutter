# AdaptiveGlass Flutter

## 功能特性

### 图像处理模板

- **Classic 经典模式**
  - 画布比例调整（多种预设比例）
  - 背景模糊效果（模糊半径、亮度、模糊模式）
  - 边框样式（样式、宽度、圆角、阴影强度、颜色）
  - 文字水印（自定义文字、位置、颜色、字体、透明度、大小）
  - 多格式导出（PNG、JPG、JPEG）

- **ColorBorder 颜色边框模式**
  - 自动为图片生成白色边框
  - 从画面中提取五种主色
  - 以色点和 RGB 数值形式展示颜色

- **WatermarkBorder 水印边框模式**
  - 底部信息边框
  - 支持 EXIF 信息显示
  - 自定义水印设置

- **ColorWalk 色彩漫步模式**
  - 从图片提取五种主色
  - 选择颜色作为背景色
  - 自定义文字和拍摄时间显示
  - 灵活的排布位置设置

### 编辑功能

- 图片导入（支持 PNG、JPG、JPEG、BMP、WebP、TIF、TIFF）
- 图片导出（支持 PNG、JPG、JPEG）
- 实时预览
- 响应式布局（宽屏/窄屏自适应）

### 应用特性

- 深色/浅色主题切换
- 自定义字体（得意黑/系统字体）
- 液态玻璃 UI 效果
- 多平台支持（Android、iOS、macOS、Windows、Linux、Web）
- 自动检查更新
- 更新日志查看

## 开始

### 环境要求

- Flutter SDK >= 3.6.0
- Dart SDK >= 3.6.0

### 安装

```bash
flutter pub get
```

### 运行

```bash
flutter run
```

## 构建

```bash
# Android
flutter build apk

# iOS
flutter build ios

# macOS
flutter build macos

# Windows
flutter build windows

# Linux
flutter build linux

# Web
flutter build web
```

## 项目结构

```
lib/
├── features/
│   ├── editor/          # 图像编辑器
│   │   ├── models/      # 编辑器数据模型
│   │   └── widgets/     # 编辑器 UI 组件
│   └── home/            # 主页
│       ├── pages/       # 页面（首页、设置）
│       └── widgets/     # 主页 UI 组件
├── models/              # 核心数据模型
├── services/            # 服务层
├── shared/              # 共享工具和主题
└── main.dart            # 应用入口
```

## 版本

当前版本：1.0.11

## 许可证

私有项目，未经授权禁止发布。
