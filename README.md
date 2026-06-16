# Novel Hub Mobile

离线优先的小说元数据浏览应用，与 [Novel Hub](https://github.com/light-nook-labs/novel_hub) Web 版功能对齐。

## 特性

- 📱 **离线优先**: 本地 SQLite 数据库，无需网络即可浏览
- 🔄 **自动同步**: 从 GitHub Releases 下载最新数据
- 🌙 **深色模式**: 完整支持深色/浅色主题
- 🔍 **全文搜索**: 支持标题、作者搜索
- 📊 **排行榜**: 6 个维度（点击/字数/收藏/点赞/长评/短评）
- 🏷️ **多维度筛选**: 按分类、状态、类型、年份筛选

## 截图

| 首页 | 小说列表 | 排行榜 | 详情页 |
|------|----------|--------|--------|
| Hero 轮播 | 4 列网格 | 标签页切换 | 封面+信息 |

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter | UI 框架 |
| Riverpod | 状态管理 |
| drift | SQLite ORM |
| dio | HTTP 客户端 |
| go_router | 路由管理 |
| cached_network_image | 图片缓存 |

## 快速开始

### 环境要求

- Flutter 3.11+
- Dart 3.11+

### 安装依赖

```bash
flutter pub get
```

### 代码生成

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行

```bash
# Linux 桌面
flutter run -d linux

# Android
flutter run -d android

# iOS
flutter run -d ios
```

### 构建

```bash
# Linux
flutter build linux --debug

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app/
│   ├── router.dart             # 路由配置
│   └── theme.dart              # 主题配置
├── data/
│   ├── models/database.dart    # 数据库模型
│   ├── repositories/providers.dart  # Riverpod providers
│   └── services/
│       ├── jsonl_parser.dart   # JSONL 解析
│       └── sync_service.dart   # 同步服务
├── features/
│   ├── home/                   # 首页
│   ├── novels/                 # 小说列表/详情
│   ├── authors/                # 作者列表/详情
│   ├── tags/                   # 标签列表/详情
│   ├── contests/               # 比赛列表/详情
│   ├── banner/                 # 背投标签页
│   ├── browse/                 # 枚举列表页
│   ├── rankings/               # 排行榜
│   ├── search/                 # 搜索
│   └── settings/               # 设置
└── shared/
    ├── widgets/
    │   ├── novel_card.dart     # 小说卡片
    │   └── novel_rank_list.dart # 可复用排行列表
    └── utils/mappings.dart     # 枚举映射
```

## 数据来源

数据来自 [Novel Hub](https://github.com/light-nook-labs/novel_hub) 的 GitHub Releases：

- 每月自动发布 `release.tar.gz`
- 包含 JSONL 格式的小说元数据
- 应用首次启动时自动下载并导入

## 开发指南

### 添加新页面

1. 在 `lib/features/` 下创建新目录
2. 创建页面文件
3. 在 `lib/app/router.dart` 中添加路由
4. 运行 `dart run build_runner build` 生成代码

### 修改数据库

1. 编辑 `lib/data/models/database.dart`
2. 运行 `dart run build_runner build`
3. 更新 `lib/data/repositories/providers.dart`

### 添加新筛选条件

1. 在 `lib/shared/widgets/novel_rank_list.dart` 中添加筛选选项
2. 更新数据库查询方法
3. 更新对应的页面

## 常见问题

### build_runner 失败

```bash
# 清理并重新生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### 数据库损坏

1. 进入设置页面
2. 点击"重置数据"
3. 重新同步

### 图片不显示

- 检查网络连接
- 确认 URL 格式正确（以 `https://` 开头）
- 尝试清除图片缓存

## 许可证

MIT License
