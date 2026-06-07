# 重构计划：AdaptiveGlass Flutter 模块化重构

## 当前问题分析

### 1. 目录结构问题
```
lib/
├── app/               # 小，只有路由
├── features/          # 功能混合，职责不清晰
│   ├── home/          # 包含首页、设置页、导航、渲染器
│   └── editor/        # 编辑器相关
├── models/            # 数据模型
├── services/          # 业务逻辑混合（渲染器、处理器）
└── shared/            # 共享组件
```

**问题：**
- `features/home/painters/` 和 `features/home/widgets/` 职责混乱
- `services/frame_renderers/` 和 `services/adaptive_glass_processor.dart` 耦合严重
- 模板特定逻辑散落在各处（如 `editor_settings_panel.dart` 的 switch-case）

### 2. 代码耦合问题
- `ClassicFrameRenderer` 包含 ~1400 行代码，职责过多
- `EditorSettingsPanel` 包含所有模板的设置 UI，难以维护
- 模板配置硬编码在多个地方

---

## 新架构设计

### 目录结构

```
lib/
├── core/                      # 核心层（无业务逻辑）
│   ├── constants/            # 常量定义
│   │   ├── app_constants.dart
│   │   └── theme_constants.dart
│   ├── errors/               # 错误处理
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── utils/                # 工具类
│       ├── image_utils.dart
│       ├── exif_utils.dart
│       └── validators.dart
│
├── data/                      # 数据层
│   ├── models/               # 数据模型（与 domain 分离）
│   │   ├── template_model.dart
│   │   ├── settings_models.dart
│   │   ├── output_models.dart
│   │   └── exif_model.dart
│   ├── repositories/         # 仓库接口
│   │   └── image_repository.dart
│   └── datasources/          # 数据源
│       └── image_datasource.dart
│
├── domain/                    # 领域层（业务逻辑）
│   ├── entities/             # 实体
│   │   ├── template.dart
│   │   └── image_processing_result.dart
│   ├── repositories/         # 仓库接口（纯 Dart，无依赖）
│   │   └── image_repository.dart
│   └── usecases/             # 用例（业务操作）
│       ├── process_image.dart
│       ├── extract_palette.dart
│       └── read_exif.dart
│
├── presentation/              # 展示层（UI）
│   ├── common/               # 通用组件
│   │   ├── widgets/
│   │   │   ├── glass/
│   │   │   │   ├── glass_card.dart
│   │   │   │   ├── glass_button.dart
│   │   │   │   └── glass_slider.dart
│   │   │   └── settings/
│   │   │       ├── setting_section.dart
│   │   │       └── value_selector.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── color_schemes.dart
│   │   └── extensions/
│   │       └── context_extensions.dart
│   │
│   ├── features/             # 功能模块（独立可插拔）
│   │   ├── home/
│   │   │   ├── features/
│   │   │   │   ├── template_selection/      # 模板选择功能
│   │   │   │   │   ├── widgets/
│   │   │   │   │   │   ├── template_grid.dart
│   │   │   │   │   │   └── template_card.dart
│   │   │   │   │   └── bloc/
│   │   │   │   │       └── template_selection_bloc.dart
│   │   │   │   └── navigation/              # 导航功能
│   │   │   │       └── widgets/
│   │   │   │           └── home_navigation.dart
│   │   │   └── widgets/
│   │   │       └── backdrop.dart
│   │   │
│   │   └── editor/
│   │       ├── features/
│   │       │   ├── image_loader/            # 图片加载功能
│   │       │   ├── preview_renderer/        # 预览渲染功能
│   │       │   ├── settings_panel/          # 设置面板功能
│   │       │   │   ├── classic/            # 经典模板设置
│   │       │   │   ├── color_border/       # 彩色边框设置
│   │       │   │   └── color_walk/         # Color Walk 设置
│   │       │   └── export_manager/         # 导出管理功能
│   │       │       ├── bloc/
│   │       │       │   └── export_bloc.dart
│   │       │       └── widgets/
│   │       │           ├── export_options.dart
│   │       │           └── preset_manager.dart
│   │       └── widgets/
│   │           ├── editor_app_bar.dart
│   │           └── editor_layout.dart
│   │
│   └── routes/               # 路由配置
│       └── app_router.dart
│
├── di.dart                   # 依赖注入配置
└── main.dart
```

### 模块职责划分

#### 1. `core/` - 核心层
- **无外部依赖**（除了 Flutter 基础）
- 定义应用范围的常量、错误类型、工具函数
- **不包含任何业务逻辑**

#### 2. `data/` - 数据层
- 实现 `domain/` 中定义的仓库接口
- 处理具体的数据源（文件、网络、本地存储）
- 包含 Platform-specific 代码

#### 3. `domain/` - 领域层
- **纯 Dart 代码，无 Flutter 依赖**
- 定义业务实体和仓库接口
- 实现用例（Use Cases）- 单一职责的业务操作

#### 4. `presentation/` - 展示层
- 所有 UI 相关代码
- 功能模块化，每个功能独立文件夹
- 使用 BLoC/Cubit 管理状态

---

## 重构步骤

### Phase 1: 创建核心层和常量
1. 创建 `core/constants/` 目录
2. 提取 `app_constants.dart`（版本、包名等）
3. 提取 `theme_constants.dart`（主题颜色、间距等）

### Phase 2: 领域层重构
1. 创建 `domain/entities/` 
2. 创建 `domain/usecases/`
3. 将处理器逻辑迁移到用例类

### Phase 3: 数据层重构
1. 创建 `data/models/`（数据模型）
2. 创建 `data/repositories/`（仓库实现）
3. 实现依赖注入

### Phase 4: UI 模块化
1. 创建 `presentation/common/widgets/`
2. 创建 `presentation/features/` 下的各个功能模块
3. 每个模板独立的设置面板

### Phase 5: 迁移和测试
1. 逐步迁移现有代码
2. 为每个模块添加单元测试
3. 集成测试

---

## 关键设计决策

### 1. 状态管理
- 使用 `Bloc/Cubit` 统一状态管理
- 优点：可测试、可预测、支持时间旅行调试

### 2. 模板扩展性
```dart
// 新增模板只需：
// 1. 实现 TemplateConfig 接口
class NewTemplateConfig extends TemplateConfig {
  @override
  String get name => '新模板';
  
  @override
  List<SettingCategory> get categories => [...];
  
  @override
  FrameRenderer get renderer => NewFrameRenderer();
}
```

### 3. 依赖注入
- 使用 `get_it` + `flutter_modular`
- 支持依赖注入和模拟测试

---

## 预期收益

| 项目 | 重构前 | 重构后 |
|------|--------|--------|
| 新增模板工作量 | 修改多处 | 单一文件 |
| 单元测试覆盖率 | ~0% | >80% |
| 代码耦合度 | 高 | 低 |
| 文件行数(最大) | 1400+ | <300 |
| 可维护性 | 难 | 易 |

---

## 重构进度

### 已完成

#### 1. 核心层 (core/)
- `core/constants/app_constants.dart` - 应用常量
- `core/constants/theme_constants.dart` - 主题常量
- `core/errors/exceptions.dart` - 异常定义
- `core/errors/failures.dart` - 失败类型
- `core/utils/image_utils.dart` - 图像工具
- `core/utils/exif_utils.dart` - EXIF 工具

#### 2. 领域层 (domain/)
- `domain/entities/template.dart` - 模板实体
- `domain/entities/template_variant.dart` - 模板变体
- `domain/entities/image_processing_result.dart` - 处理结果
- `domain/entities/processing_settings.dart` - 处理设置
- `domain/usecases/usecases.dart` - 用例接口

#### 3. 数据层 (data/)
- `data/models/exif_model.dart` - EXIF 模型
- `data/models/palette_model.dart` - 调色板模型
- `data/repositories/image_repository_impl.dart` - 仓库实现
- `data/datasources/image_datasource.dart` - 数据源

#### 4. 展示层 (presentation/)
- `presentation/common/` - 通用组件
  - `common/widgets/glass/` - Glass 组件封装
  - `common/widgets/settings/` - 设置组件
  - `common/theme/` - 主题定义
  - `common/extensions/` - 扩展
- `presentation/features/home/` - 主页功能
  - `home_screen.dart` - 主页
  - `widgets/home_shell.dart` - 首页壳
  - `widgets/settings_shell.dart` - 设置页
  - `features/template_selection/` - 模板选择
  - `features/navigation/` - 导航
- `presentation/features/editor/` - 编辑器功能
  - `editor.dart` - 编辑器入口
  - `widgets/editor_app_bar.dart` - 编辑器应用栏
  - `features/image_loader/` - 图片加载
  - `features/preview_renderer/` - 预览渲染
  - `features/settings_panel/` - 设置面板
    - `classic/` - 经典模板设置
    - `color_border/` - 彩色边框设置
    - `color_walk/` - Color Walk 设置
  - `features/export_manager/` - 导出管理

#### 5. 配置文件
- `di.dart` - 依赖注入配置
- `all.dart` - 全局导出

### 待完成

#### Phase 2: 领域层实现
- [ ] 实现 `ProcessImageUseCase`
- [ ] 实现 `ExtractPaletteUseCase`
- [ ] 实现 `ReadExifUseCase`

#### Phase 3: 数据层完善
- [ ] 完善 `ImageDatasource` 实现
- [ ] 实现本地存储数据源

#### Phase 4: UI 实现
- [ ] 完成模板预览组件（复用原 painters）
- [ ] 完成编辑器设置面板（复用原逻辑）
- [ ] 完成渲染器实现

#### Phase 5: 路由和导航
- [ ] 迁移现有路由配置
- [ ] 实现完整的导航逻辑

---

## 迁移指南

### 步骤 1: 添加依赖
```bash
flutter pub add get_it either_dart
```

### 步骤 2: 更新 pubspec.yaml
```yaml
environment:
  sdk: ^3.11.5
  flutter: ">=3.24.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  exif: ^3.3.0
  file_picker: ^11.0.2
  flutter_svg: ^2.2.1
  flutter_sficon: ^1.3.0
  go_router: ^17.2.3
  go_transitions: ^0.8.3
  image: ^4.8.0
  liquid_glass_widgets: ^0.11.0
  http: ^1.2.0
  url_launcher: ^6.3.0
  package_info_plus: ^8.0.0
  path: ^1.9.1
  shared_preferences: ^2.5.3
  signals: ^6.3.0
  signals_flutter: ^6.3.0
  get_it: ^7.6.0
  either_dart: ^1.0.0
```

### 步骤 3: 运行分析检查
```bash
flutter analyze
```

### 步骤 4: 逐步迁移
1. 先确保新架构编译通过
2. 逐步替换旧代码
3. 每个模块添加单元测试
