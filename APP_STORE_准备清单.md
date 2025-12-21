# Seth365 App Store 上架准备清单

> 最后更新：2025-12-21

---

## 一、截图要求

App Store 需要以下尺寸的截图（至少需要 6.7 英寸和 6.5 英寸两种）：

### 1.1 必需截图尺寸

| 设备 | 尺寸（像素） | 说明 |
|------|-------------|------|
| iPhone 6.7" | 1290 × 2796 | iPhone 15 Pro Max, 14 Pro Max |
| iPhone 6.5" | 1284 × 2778 | iPhone 14 Plus, 13 Pro Max |
| iPhone 5.5" | 1242 × 2208 | iPhone 8 Plus（可选） |
| iPad 12.9" | 2048 × 2732 | iPad Pro（如支持 iPad） |

### 1.2 建议截图内容（3-5 张）

1. **首页日历视图** - 展示日历和当天壁纸
2. **壁纸大图展示** - 展示壁纸轮播效果
3. **设置页面** - 展示显示模式、语言选择等
4. **快捷指令引导** - 展示自动换壁纸功能
5. **海报生成** - 展示二维码海报功能（可选）

### 1.3 截图方法

在 Xcode 模拟器中截图：
1. 选择 iPhone 15 Pro Max 模拟器运行 App
2. 菜单：**File → Save Screen** 或按 **Cmd + S**
3. 保存为 PNG 格式

或者用真机截图后传到电脑。

---

## 二、App 信息（需填写到 App Store Connect）

### 2.1 基本信息

| 项目 | 内容 |
|------|------|
| **App 名称** | Seth365 - 2026日历壁纸 |
| **副标题** | 每天8张精美壁纸，自动换壁纸 |
| **套装 ID** | com.futuremind2075.Seth365 |
| **SKU** | Seth365 |
| **主要语言** | 简体中文 |
| **类别** | 生活（主）/ 摄影与录像（次） |
| **内容分级** | 4+ |
| **价格** | 免费 |

### 2.2 App 描述（简体中文）

```
Seth365 - 2026年日历壁纸

每天8张精美壁纸，全年365天 × 8张 = 2920张精选壁纸。

【主要功能】
• 每日壁纸 - 每天解锁8张新壁纸，中英文双语，竖版横版随心选
• 日历浏览 - 直观的日历界面，轻松查看每一天的壁纸
• 多种显示模式 - 适配黑边、白边、拉伸、裁切等6种显示方式
• 自动换壁纸 - 配合快捷指令，实现每天自动更换壁纸
• 海报生成 - 为壁纸添加个人二维码，制作专属海报
• 离线可用 - 内置壁纸，无需网络也能使用

【快捷指令自动化】
支持通过iOS快捷指令实现自动换壁纸：
- 每天定时自动换壁纸
- 打开微信时自动换壁纸
- 断开充电器时自动换壁纸

【使用说明】
1. 打开App查看今日壁纸
2. 选择喜欢的壁纸保存到相册
3. 在设置中设为壁纸，或配置快捷指令自动更换

让每一天都有新的视觉体验！
```

### 2.3 关键词（100字符以内，用英文逗号分隔）

```
壁纸,日历,2026,每日壁纸,自动换壁纸,快捷指令,Wallpaper,Calendar,锁屏壁纸,桌面壁纸
```

### 2.4 App 描述（英文）

```
Seth365 - 2026 Calendar Wallpaper

8 beautiful wallpapers every day, 365 days × 8 = 2920 curated wallpapers for the year.

【Features】
• Daily Wallpapers - Unlock 8 new wallpapers daily, in Chinese & English, portrait & landscape
• Calendar View - Browse wallpapers by date with intuitive calendar interface
• Display Modes - 6 display modes including fit, stretch, crop, and blur background
• Auto Change - Use Shortcuts to automatically change wallpaper daily
• Poster Generator - Create custom posters with your QR code
• Offline Ready - Built-in wallpapers work without internet

【Shortcuts Automation】
Set up automatic wallpaper changes:
- Change wallpaper at scheduled times
- Change when opening specific apps
- Change when disconnecting charger

Enjoy a fresh new look every day!
```

---

## 三、隐私政策

App Store 要求所有 App 提供隐私政策链接。

### 3.1 简单方案：使用 GitHub Pages

在 GitHub 仓库创建 `docs/privacy.html` 或 `privacy.md`，然后启用 GitHub Pages。

隐私政策 URL 示例：`https://dufutaoraul.github.io/Seth365-ios/privacy`

### 3.2 隐私政策模板

```markdown
# Seth365 隐私政策

最后更新：2025年12月21日

## 信息收集

Seth365 不收集任何个人信息。

## 数据存储

- 壁纸图片存储在您的设备本地
- 用户偏好设置存储在设备本地
- 我们不会将任何数据上传到服务器

## 网络请求

App 可能会连接到 Cloudflare R2 服务器下载壁纸更新，但不会发送任何个人信息。

## 第三方服务

本 App 不使用任何第三方分析或广告服务。

## 联系我们

如有疑问，请联系：[您的邮箱]
```

---

## 四、版本号设置

在 Xcode 项目设置中确认：

| 项目 | 当前值 | 说明 |
|------|--------|------|
| MARKETING_VERSION | 1.2.0 | 用户看到的版本号 |
| CURRENT_PROJECT_VERSION | 1 | 构建号，每次提交递增 |

**注意**：每次提交新版本到 App Store，CURRENT_PROJECT_VERSION 必须递增。

---

## 五、App 图标

确保项目中已配置 App 图标（Assets.xcassets/AppIcon）：

| 尺寸 | 用途 |
|------|------|
| 1024 × 1024 | App Store 展示 |
| 180 × 180 | iPhone @3x |
| 120 × 120 | iPhone @2x |
| 167 × 167 | iPad Pro |
| 152 × 152 | iPad @2x |

---

## 六、同事上架步骤

### 6.1 你需要提供给同事的

1. **GitHub 仓库地址**：https://github.com/dufutaoraul/Seth365-ios
2. **本文档**（APP_STORE_准备清单.md）
3. **截图文件**（你截好后发给他）
4. **隐私政策链接**（你创建后发给他）

### 6.2 同事需要做的

1. 克隆 GitHub 仓库
2. 用 Xcode 打开项目
3. 配置开发者证书和 Team ID
4. 修改 Bundle ID（如果需要）
5. 执行 **Product → Archive**
6. 上传到 App Store Connect
7. 在 App Store Connect 填写信息并提交审核

### 6.3 审核时间

- 首次提交：通常 24-48 小时
- 更新版本：通常 24 小时内

---

## 七、常见审核问题

| 问题 | 解决方案 |
|------|----------|
| 缺少隐私政策 | 创建隐私政策页面并填写链接 |
| 截图不符合要求 | 使用正确尺寸的模拟器截图 |
| App 崩溃 | 确保在真机上测试通过 |
| 功能描述不清 | 在描述中详细说明快捷指令使用方法 |
| 内容分级不正确 | Seth365 应选择 4+ |

---

## 八、提交前检查清单

- [ ] 截图已准备（6.7寸 + 6.5寸，3-5张）
- [ ] App 图标已配置
- [ ] 隐私政策链接已创建
- [ ] 版本号已设置（1.2.0）
- [ ] App 描述已准备（中英文）
- [ ] 关键词已准备
- [ ] 在真机上测试通过
- [ ] 快捷指令功能正常
- [ ] 壁纸加载正常

---

*文档创建于 2025-12-21*
