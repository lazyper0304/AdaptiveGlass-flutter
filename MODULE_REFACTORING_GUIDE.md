# 代码模块化重构指南

## 架构原则

### 1. 分层架构
```
┌─────────────────────────────────────────────┐
│         presentation (UI 层)                │
│  - widgets, screens, controllers, blocs     │
├─────────────────────────────────────────────┤
│            domain (领域层)                  │
│  - entities, usecases, repositories         │
│  - 纯 Dart，无 Flutter 依赖                 │
├─────────────────────────────────────────────┤
│            data (数据层)                    │
│  - repositories impl, datasources           │
│  - Platform-specific 代码                   │
├─────────────────────────────────────────────┤
│           core (核心层)                     │
│  - constants, errors, utils                 │
│  - 无业务逻辑                               │
└─────────────────────────────────────────────┘
```

### 2. 依赖方向
- presentation → domain → data → core
- 依赖抽象，不依赖具体实现
- 使用依赖注入解耦

### 3. 单一职责原则
每个文件/类只做一件事

## 新模块说明

### `core/` - 核心层

**作用**: 定义应用范围的常量、错误、工具函数

**特点**:
- 无业务逻辑
- 无外部依赖（除了 Flutter 基础）

**文件结构**:
```
core/
├── constants/      # 常量定义
│   ├── app_constants.dart
│   └── theme_constants.dart
├── errors/         # 错误处理
│   ├── exceptions.dart
│   └── failures.dart
└── utils/          # 工具类
    ├── image_utils.dart
    └── exif_utils.dart
```

### `domain/` - 领域层

**作用**: 定义业务实体和业务操作

**特点**:
- 纯 Dart 代码，无 Flutter 依赖
- 定义仓库接口（不实现）
- 实现用例（Use Cases）

**文件结构**:
```
domain/
├── entities/       # 业务实体
│   ├── template.dart
│   └── image_processing_result.dart
├── repositories/   # 仓库接口
│   └── image_repository.dart
└── usecases/       # 用例（业务操作）
    └── usecases.dart
```

### `data/` - 数据层

**作用**: 实现领域层定义的接口

**特点**:
- 实现 domain 中的仓库接口
- 处理具体的数据源（文件、网络、本地存储）

**文件结构**:
```
data/
├── models/         # 数据模型
│   ├── exif_model.dart
│   └── palette_model.dart
├── repositories/   # 仓库实现
│   └── image_repository_impl.dart
└── datasources/    # 数据源
    └── image_datasource.dart
```

### `presentation/` - 展示层

**作用**: 所有 UI 相关代码

**文件结构**:
```
presentation/
├── common/          # 通用组件
│   ├── widgets/     # UI 组件
│   ├── theme/       # 主题定义
│   └── extensions/  # 扩展
├── features/        # 功能模块
│   ├── home/        # 主页功能
│   └── editor/      # 编辑器功能
└── routes/          # 路由配置
```

## 代码组织规则

### 1. 导入规则
```dart
// 1. Dart 标准库
import 'dart:async';
import 'dart:math';

// 2. Flutter 框架
import 'package:flutter/material.dart';

// 3. 第三方包
import 'package:go_router/go_router.dart';

// 4. 项目内部模块（按依赖顺序）
import 'package:app/core/constants/app_constants.dart';
import 'package:app/domain/domain.dart';
import 'package:app/data/data.dart';
import 'package:app/presentation/presentation.dart';
```

### 2. 文件命名
- 类名：`PascalCase`（如 `TemplateCard`）
- 文件名：`snake_case`（如 `template_card.dart`）
- 目录名：`snake_case`（如 `template_selection`）

### 3. 包结构
```
features/
└── home/
    ├── features/    # 功能特性
    │   ├── template_selection/
    │   └── navigation/
    ├── widgets/     # 共享 UI 组件
    ├── bloc/        # 状态管理（如需要）
    └── home.dart    # 主入口
```

## 迁移检查清单

### [ ] Phase 1: 核心层
- [x] 创建目录结构
- [x] 定义常量
- [x] 定义错误类型
- [x] 实现工具函数

### [ ] Phase 2: 领域层
- [ ] 定义实体
- [ ] 定义仓库接口
- [ ] 实现用例

### [ ] Phase 3: 数据层
- [ ] 实现仓库
- [ ] 实现数据源
- [ ] 实现依赖注入

### [ ] Phase 4: UI 层
- [ ] 通用组件
- [ ] 主页功能
- [ ] 编辑器功能

### [ ] Phase 5: 整合
- [ ] 迁移路由
- [ ] 更新主入口
- [ ] 删除旧代码

## 注意事项

1. **逐步迁移**: 不要一次性重写所有代码
2. **测试先行**: 为每个模块添加单元测试
3. **保持兼容**: 迁移期间保持新旧代码并存
4. **文档同步**: 更新相关文档和注释
5. **性能监控**: 迁移后检查性能指标