# Seth365 iOS 项目文档

> 此文档记录项目的核心信息、开发进度和重要决策。每次重大改动都会同步更新。
>
> 最后更新：2025-12-21

---

## 一、项目概述

**项目名称**：Seth365（Seth2026 日历壁纸 iOS 版）

**核心功能**：每天 8 张精美壁纸，全年 365 天 × 8 张 = 2920 张。用户每天只能解锁当天及之前的壁纸。

**使用期限**：仅限 2026 年（测试用 2025 年 12 月数据）

**壁纸来源**：App 内置 + Cloudflare R2 云存储
- 内置壁纸：2025年12月 + 2026年1-2月（共560张，约868MB）
- 远程备份: `https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev`
- 加载顺序：Bundle → 磁盘缓存 → 网络下载

---

## 二、技术栈

| 项目 | 选择 |
|------|------|
| 语言 | Swift 5.9+ |
| UI 框架 | SwiftUI |
| 最低 iOS 版本 | iOS 16.0 |
| 网络 | URLSession（原生） |
| 图片缓存 | NSCache + FileManager（原生） |
| 二维码检测 | Vision Framework（原生） |
| 快捷指令 | App Intents Framework |
| 第三方依赖 | 无 |

---

## 三、壁纸命名规则（核心逻辑）

### 3.1 每天 8 张壁纸

```
每天 8 张 = 2种语言 × 2种方向 × 2张
         = (中文/英文) × (竖版/横版) × (第1张/第2张)

编码：
1. CS1 = 中文竖版第1张 (Chinese Standing 1)
2. CS2 = 中文竖版第2张
3. CH1 = 中文横版第1张 (Chinese Horizontal 1)
4. CH2 = 中文横版第2张
5. ES1 = 英文竖版第1张 (English Standing 1)
6. ES2 = 英文竖版第2张
7. EH1 = 英文横版第1张
8. EH2 = 英文横版第2张
```

### 3.2 文件命名格式

```
格式: {月}.{日}.{语言}{方向}{序号}.png

示例:
  1.1.CS1.png   → 1月1日 中文竖版 第1张
  12.25.EH2.png → 12月25日 英文横版 第2张
```

### 3.3 完整 URL 示例

```
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.1.CS1.png
```

### 3.4 解锁逻辑

```swift
// 壁纸日期 <= 系统当前日期 即为解锁
func isUnlocked() -> Bool {
    return wallpaperDate <= Date()
}
```

---

## 四、文件结构

```
Seth365/
├── Seth365.xcodeproj/           # Xcode 项目文件
└── Seth365/                     # 源代码目录
    ├── Seth365App.swift         # App 入口
    ├── ContentView.swift        # 根视图（TabView）
    ├── Assets.xcassets/         # 图片资源
    │
    ├── Config/
    │   └── R2Config.swift       # Cloudflare R2 配置
    │
    ├── Models/
    │   ├── Wallpaper.swift      # 壁纸数据模型
    │   ├── WallpaperLanguage.swift
    │   └── WallpaperOrientation.swift
    │
    ├── Views/
    │   ├── Home/                        # v1.2.0 新增
    │   │   ├── HomeView.swift           # 首页视图（日历+轮播一体化）
    │   │   ├── DateHeaderView.swift     # 日期栏组件
    │   │   ├── CalendarGridView.swift   # 可折叠日历网格
    │   │   ├── FilterTabsView.swift     # 筛选标签组件
    │   │   ├── WallpaperPageView.swift  # 壁纸大图轮播
    │   │   ├── ThumbnailScrollView.swift # 缩略图滚动条
    │   │   └── ActionButtonsView.swift  # 操作按钮组件
    │   │
    │   ├── Calendar/
    │   │   ├── CalendarView.swift
    │   │   ├── MonthView.swift
    │   │   └── DayCell.swift
    │   │
    │   ├── Wallpaper/
    │   │   ├── WallpaperListView.swift
    │   │   ├── WallpaperCard.swift
    │   │   └── WallpaperDetailView.swift
    │   │
    │   ├── Poster/
    │   │   └── PosterEditorView.swift  # 海报编辑器（可调整红框）
    │   │
    │   └── Settings/
    │       ├── SettingsView.swift
    │       └── ShortcutsGuideView.swift
    │
    ├── ViewModels/
    │   ├── HomeViewModel.swift          # v1.2.0 新增
    │   ├── CalendarViewModel.swift
    │   ├── WallpaperViewModel.swift
    │   └── PosterViewModel.swift
    │
    ├── Services/
    │   ├── NetworkService.swift
    │   ├── ImageCacheService.swift          # 图片缓存（含更新检测）
    │   ├── QRCodeDetectionService.swift
    │   └── WallpaperPreloadService.swift    # 壁纸预加载服务
    │
    ├── Utils/
    │   ├── Localization.swift               # 本地化辅助工具
    │   └── AppInfo.swift                    # 应用版本信息工具
    │
    ├── Storage/
    │   ├── UserDefaultsManager.swift
    │   └── QRCodeStorage.swift
    │
    ├── Intents/
    │   ├── GetWallpaperIntent.swift      # 获取壁纸 Intent
    │   └── AppShortcuts.swift            # 预配置快捷指令
    │
    └── Resources/
        ├── zh-Hans.lproj/
        │   └── Localizable.strings       # 中文本地化
        ├── en.lproj/
        │   └── Localizable.strings       # 英文本地化
        └── Wallpapers/                   # 内置壁纸资源（需手动添加到 Xcode）
            ├── 25/12/                    # 2025年12月（88张）
            ├── 1/                        # 2026年1月（248张）
            ├── 2/                        # 2026年2月（224张）
            └── 3-12/                     # 待添加（.gitkeep 占位）
```

---

## 五、开发进度

### 阶段 1: 项目骨架 ✅ 完成
- [x] Xcode 项目创建
- [x] CLAUDE.md 文档创建
- [x] 创建目录结构
- [x] 创建数据模型 (Models)
- [x] 创建 R2 配置
- [x] 创建工具类 (DateUtils, Constants)

### 阶段 2: 日历功能 ✅ 完成
- [x] CalendarView 日历主视图
- [x] MonthView 月份视图
- [x] DayCell 日期单元格
- [x] 日期锁定逻辑
- [x] CalendarViewModel 视图模型
- [x] 锁定日期友好提示弹窗
- [x] 只显示有已解锁日期的月份

### 阶段 3: 壁纸浏览 ✅ 完成
- [x] NetworkService 网络服务
- [x] ImageCacheService 缓存服务
- [x] WallpaperListView 壁纸列表
- [x] WallpaperCard 壁纸卡片
- [x] WallpaperDetailView 详情预览（底部操作栏）
- [x] WallpaperViewModel 视图模型
- [x] 筛选功能（语言/方向）

### 阶段 4: 保存功能 ✅ 完成
- [x] 保存到相册
- [x] 权限请求处理
- [x] 引导用户设置壁纸弹窗

### 阶段 5: 设置页面 ✅ 完成
- [x] SettingsView 设置页
- [x] UserDefaultsManager 偏好存储
- [x] ShortcutsGuideView 快捷指令引导
- [x] 底部 TabBar 导航（日历/今日/设置）
- [x] 我的二维码设置入口
- [x] 壁纸切换设置（日期范围、随机序号）

### 阶段 6: Shortcuts 集成 ✅ 完成
- [x] GetWallpaperIntent 获取壁纸 Intent
- [x] SaveWallpaperToPhotosIntent 保存壁纸到相册 Intent
- [x] AppShortcuts 预配置快捷指令
- [x] 语言/方向/日期范围/随机选项参数
- [x] 使用偏好设置选项

### 阶段 7: 海报生成 ✅ 完成
- [x] QRCodeDetectionService 二维码检测（Vision Framework）
- [x] QRCodeStorage 用户二维码存储
- [x] PosterViewModel 海报视图模型
- [x] PosterEditorView 海报编辑器
- [x] 红色可调整边框 UI
- [x] 修复红框初始位置问题（等待检测完成后初始化）
- [x] 修复生成海报按钮无反应（添加底部大按钮）
- [x] 取消二维码大小限制（允许自由缩放）

### 阶段 8: 缓存与自动下载 ✅ 完成
- [x] 启动时自动下载壁纸（WallpaperPreloadService）
- [x] 根据切换范围设置下载相应壁纸
- [x] 显示下载进度提示（设置页面）
- [x] R2 缓存更新检测（ETag/Last-Modified 比较）
- [x] 手动下载和检查更新按钮

### 阶段 9: 国际化 ✅ 完成
- [x] 创建 Localizable.strings 文件（中/英）
- [x] 创建 Localization.swift 本地化辅助工具
- [x] 应用本地化字符串到主要视图（ContentView、SettingsView）
- [x] 枚举类型添加 localizedDisplayName 属性

### 阶段 10: 壁纸内置与版本管理 ✅ 完成
- [x] 创建 Resources/Wallpapers 目录结构
- [x] 内置 2025年12月壁纸（88张）
- [x] 内置 2026年1月壁纸（248张）
- [x] 内置 2026年2月壁纸（224张）
- [x] 创建 3-12 月空占位文件夹
- [x] 修改 Wallpaper 模型添加 bundlePath 属性
- [x] 修改 ImageCacheService 支持 Bundle 加载
- [x] 修改 WallpaperPreloadService 跳过内置壁纸
- [x] 创建 AppInfo 工具类（版本号读取）
- [x] 更新 SettingsView 显示动态版本和内置壁纸数

### 阶段 11: App Store 版本更新检测 ✅ 完成
- [x] 创建 AppUpdateService 服务（iTunes Lookup API）
- [x] 版本号比较逻辑
- [x] 设置页面添加版本更新 UI
- [x] 检查更新按钮
- [x] 显示最新版本号
- [x] "前往 App Store 更新" 按钮

### 阶段 12: v1.2.0 首页重构 ✅ 完成
- [x] DateCellState 枚举（test/unlocked/locked 三种状态）
- [x] HomeView 首页视图（日历+轮播一体化）
- [x] HomeViewModel 首页视图模型
- [x] DateHeaderView 日期栏组件（带折叠按钮）
- [x] CalendarGridView 可折叠日历网格
- [x] FilterTabsView 筛选标签组件
- [x] WallpaperPageView 壁纸大图轮播
- [x] ThumbnailScrollView 缩略图滚动条
- [x] ActionButtonsView 操作按钮（保存/海报/设置壁纸）
- [x] 点击大图进入全屏详情视图
- [x] 保存成功后显示"去设置壁纸"按钮
- [x] 月份导航限制（不能超出已解锁范围）
- [x] 下载逻辑优化（仅下载 12/21 - 2/28 共 560 张）

---

## 六、iOS 特殊限制

### 6.1 无法程序化设置壁纸

iOS **没有公开 API** 允许 App 直接设置壁纸。解决方案：
1. 保存图片到相册
2. 引导用户手动设置
3. 或使用 Shortcuts 自动化

### 6.2 Shortcuts 自动化方案

用户可配置快捷指令实现每日自动换壁纸：
```
触发器: 每天早上 7:00 / 打开微信时
动作 1: 获取 Seth365 壁纸
动作 2: 设置壁纸（系统动作）
设置: 立即运行，关闭运行时通知
```

**支持的触发条件**：
- ✅ 特定时间
- ✅ 打开 App 时
- ✅ 充电器断开时
- ✅ 连接 WiFi 时
- ❌ 解锁屏幕时（iOS 限制）
- ❌ 每隔 X 分钟（不支持高频率）

---

## 七、待解决问题

| 问题 | 优先级 | 状态 |
|------|--------|------|
| ~~海报红框初始位置在左上角~~ | 高 | ✅ 已修复 |
| ~~生成海报按钮点击无反应~~ | 高 | ✅ 已修复 |
| ~~二维码大小限制太严格~~ | 中 | ✅ 已修复 |
| ~~启动时未自动下载今日壁纸~~ | 中 | ✅ 已完成 |
| ~~R2 图片更新后本地缓存未同步~~ | 中 | ✅ 已完成 |
| ~~国际化字符串未应用到视图~~ | 中 | ✅ 已完成 |
| 完善其他视图的国际化 | 低 | 待完成 |

---

## 八、重要决策记录

| 日期 | 决策 | 原因 |
|------|------|------|
| 2025-12-11 | 最低支持 iOS 16 | App Intents 框架需要 iOS 16+ |
| 2025-12-11 | 不使用第三方库 | 减少依赖，App 体积更小 |
| 2025-12-11 | 横版壁纸旋转90° | 适配手机竖屏使用 |
| 2025-12-11 | 添加2025年12月测试数据 | 测试阶段需要，R2已有12月壁纸 |
| 2025-12-12 | 使用 onChange iOS 16 语法 | 兼容 iOS 16，避免 iOS 17+ API |
| 2025-12-13 | 海报编辑器支持拖动缩放 | 用户需要调整二维码位置和大小 |
| 2025-12-13 | 启动时自动预加载壁纸 | 提升用户体验，离线可用 |
| 2025-12-13 | 使用 ETag/Last-Modified 检测更新 | 减少不必要的下载 |
| 2025-12-13 | 创建 L10n 命名空间 | 统一管理本地化字符串 |
| 2025-12-17 | 壁纸内置到 Bundle | 减少网络依赖，离线可用 |
| 2025-12-17 | 版本号使用语义化版本 | MARKETING_VERSION = 1.0.0 |
| 2025-12-17 | 图片加载优先级 | Bundle → 磁盘缓存 → 网络 |
| 2025-12-21 | v1.2.0 首页重构 | 日历+轮播一体化设计，提升用户体验 |
| 2025-12-21 | 下载范围限制 | 仅下载 12/21 - 2/28（R2 实际存在的壁纸） |
| 2025-12-21 | DateCellState 三态设计 | test/unlocked/locked 区分不同日期状态 |
| 2025-12-21 | TabBar 简化为两个 | 首页（日历+壁纸）+ 设置 |

---

## 九、添加壁纸到 Xcode

**重要**：Resources/Wallpapers 文件夹需要手动添加到 Xcode 项目：

1. 打开 Xcode 项目
2. 在左侧导航栏右键点击 `Seth365` 文件夹
3. 选择 "Add Files to Seth365..."
4. 选择 `Resources/Wallpapers` 文件夹
5. **重要设置**：
   - ✅ 勾选 "Copy items if needed"
   - 选择 "Create folder references"（蓝色文件夹）
   - ✅ 勾选 "Add to targets: Seth365"
6. 点击 "Add"

验证添加成功：
- Wallpapers 文件夹显示为蓝色图标
- Build Phases → Copy Bundle Resources 中包含 Wallpapers

---

## 十、常用命令

```bash
# 在 Xcode 中打开项目
open /Users/liuwenjun/Desktop/taozi/Seth365/Seth365.xcodeproj

# 清理构建缓存
xcodebuild clean -project Seth365.xcodeproj -scheme Seth365

# 清理 Xcode 派生数据
rm -rf ~/Library/Developer/Xcode/DerivedData/Seth365-*

# 查看内置壁纸数量
find Seth365/Resources/Wallpapers -name "*.png" | wc -l
```

---

## 十一、版本更新流程

当需要添加新月份的壁纸时：

1. 将新壁纸复制到 `Resources/Wallpapers/{月份}/` 目录
2. 在 Xcode 中刷新文件夹引用（右键 → Add Files 或直接拖入）
3. 更新版本号：
   - `MARKETING_VERSION`：主版本.次版本.修订号（如 1.1.0）
   - `CURRENT_PROJECT_VERSION`：构建号递增（如 2, 3, 4...）
4. 测试验证 Bundle 加载正常
5. 归档并分发

---

## 十二、从 GitHub 获取代码（同事使用指南）

**GitHub 仓库地址**：https://github.com/dufutaoraul/Seth365-ios

### 12.1 方式一：下载 ZIP（推荐新手）

1. 打开浏览器访问：https://github.com/dufutaoraul/Seth365-ios
2. 点击绿色按钮 **「Code」** → **「Download ZIP」**
3. 下载完成后解压 ZIP 文件
4. 用 Xcode 打开 `Seth365.xcodeproj`
5. 直接编译运行即可（所有壁纸图片都已包含）

### 12.2 方式二：Git 克隆

```bash
git clone https://github.com/dufutaoraul/Seth365-ios.git
cd Seth365-ios
open Seth365.xcodeproj
```

### 12.3 壁纸说明

✅ **所有壁纸图片（560张，868MB）已包含在仓库中**，无需单独下载。

目录结构：
```
Seth365/Resources/Wallpapers/
├── 1/               # 2026年1月壁纸（248张）
└── 2/               # 2026年2月壁纸（224张 + 88张12月测试数据）
```

在 Xcode 中 Wallpapers 文件夹应显示为**蓝色图标**（文件夹引用）。

---

## 十三、App Store 上架流程

### 13.1 准备工作

上架 App Store 需要：
1. **Apple Developer 账号**（¥688/年）
2. **App Store Connect 账号**
3. **有效的开发者证书和描述文件**

### 13.2 创建 Archive（归档）

在 Xcode 中创建可提交的归档包：

1. 连接 iOS 设备或选择 "Any iOS Device (arm64)"
2. 菜单：**Product → Archive**
3. 等待归档完成（约 1-3 分钟）
4. 归档完成后会自动打开 Organizer 窗口

### 13.3 上传到 App Store Connect

**方式一：通过 Xcode 直接上传**
1. 在 Organizer 窗口选择刚创建的 Archive
2. 点击 "Distribute App"
3. 选择 "App Store Connect"
4. 选择 "Upload"
5. 按提示完成上传

**方式二：导出 IPA 后手动上传**
1. 在 Organizer 窗口点击 "Distribute App"
2. 选择 "App Store Connect"
3. 选择 "Export"
4. 保存 IPA 文件
5. 使用 Transporter（macOS App Store 免费下载）上传

### 13.4 在 App Store Connect 中提交审核

1. 登录 https://appstoreconnect.apple.com
2. 创建新 App（如果首次提交）
3. 填写 App 信息：
   - App 名称：Seth365
   - 主要语言：简体中文
   - 套装 ID：com.futuremind2075.Seth365
   - SKU：Seth365
4. 上传截图（需要多种尺寸）
5. 填写描述、关键词、隐私政策
6. 选择已上传的构建版本
7. 提交审核

### 13.5 给同事上架的步骤

由于你没有 Developer 账号，需要同事帮忙，步骤如下：

1. **将整个项目文件夹发送给同事**
   ```bash
   # 压缩项目（排除 DerivedData 等）
   cd /Users/liuwenjun/Desktop/taozi
   zip -r Seth365-project.zip Seth365 \
     -x "*.DS_Store" \
     -x "*DerivedData*" \
     -x "*.git/*"
   ```

2. **同事在他的 Mac 上操作**
   - 解压项目
   - 用 Xcode 打开 `Seth365.xcodeproj`
   - 在项目设置中配置他的开发者证书和 Team
   - 执行 Archive 并上传

3. **需要同事提供的信息**
   - Apple Developer Team ID
   - Bundle ID 是否需要修改
   - 描述文件配置

---

## 十四、联系与参考

- Android 版参考文档: `/Users/liuwenjun/Downloads/CROSS_PLATFORM_REFERENCE.md`
- Cloudflare R2 控制台: https://dash.cloudflare.com/
- GitHub 仓库: https://github.com/dufutaoraul/Seth365-ios

---

*文档创建于 2025-12-11，最后更新于 2025-12-19（修复 Bundle 加载、添加调试日志、GitHub 支持）*
