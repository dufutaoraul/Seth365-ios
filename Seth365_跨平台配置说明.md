# Seth365 跨平台壁纸配置说明

## 共享配置文件

**所有平台（iOS、macOS、Android、Windows）都使用同一个配置文件：**

```
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpaper-config.json
```

---

## 配置文件格式

```json
{
  "version": 1,
  "lastUpdated": "2025-12-21",
  "startDate": "2025-12-21",
  "endDate": "2026-02-28",
  "totalCount": 560
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `version` | int | 配置版本号，每次新增壁纸时递增 |
| `lastUpdated` | string | 最后更新日期 (yyyy-MM-dd) |
| `startDate` | string | 壁纸起始日期 |
| `endDate` | string | 壁纸结束日期 |
| `totalCount` | int | 壁纸总数 |

---

## 壁纸 URL 规则

### 基础 URL
```
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/
```

### 文件路径规则

**所有壁纸统一格式：**
```
/wallpapers/{月份两位数}/{文件名}
示例: /wallpapers/12/12.21.CS1.png
```

### 文件名格式
```
{月}.{日}.{语言}{方向}{序号}.png

语言: E=中文, C=英文 (注意：文件命名与实际内容相反)
方向: H=竖版, S=横版 (注意：文件命名与实际内容相反)
序号: 1-2

示例:
- 12.21.EH1.png  → 12月21日，中文竖版第1张
- 12.21.ES1.png  → 12月21日，中文横版第1张
- 12.21.CH1.png  → 12月21日，英文竖版第1张
- 12.21.CS1.png  → 12月21日，英文横版第1张
```

### 每日壁纸数量
- 每天 8 张壁纸
- 中文竖版: 2张 (EH1, EH2)
- 中文横版: 2张 (ES1, ES2)
- 英文竖版: 2张 (CH1, CH2)
- 英文横版: 2张 (CS1, CS2)

---

## 客户端实现逻辑

### 1. 获取远程配置

```kotlin
// Android (Kotlin)
val configUrl = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpaper-config.json?t=${System.currentTimeMillis()}"
```

```csharp
// Windows (C#)
var configUrl = $"https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpaper-config.json?t={DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
```

> 添加时间戳参数 `?t=xxx` 绕过 CDN 缓存

### 2. 版本比对

```kotlin
// Android
val localVersion = sharedPreferences.getInt("wallpaperVersion", 0)
if (localVersion == remoteConfig.version) {
    // 版本相同，跳过同步
    return
}
```

```csharp
// Windows
var localVersion = Settings.Default.WallpaperVersion;
if (localVersion == remoteConfig.Version) {
    // 版本相同，跳过同步
    return;
}
```

### 3. 生成壁纸列表

根据 `startDate` 和 `endDate` 生成日期范围内的所有壁纸 URL：

```kotlin
// Android 伪代码
fun getWallpaperUrl(month: Int, day: Int, lang: String, orient: String, index: Int): String {
    val baseUrl = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers"
    val monthStr = month.toString().padStart(2, '0')
    // 统一格式: /wallpapers/12/12.21.EH1.png
    return "$baseUrl/$monthStr/$month.$day.$lang$orient$index.png"
}

// 语言/方向映射（文件名与实际内容相反）
// 中文 -> "E", 英文 -> "C"
// 竖版 -> "H", 横版 -> "S"
```

### 4. 下载壁纸

- 只下载到**今天**为止（未来日期不下载）
- 检查本地缓存，跳过已下载的
- 支持断点续传（可选）

### 5. 更新本地版本号

下载完成后，保存远程 version 到本地：

```kotlin
// Android
sharedPreferences.edit().putInt("wallpaperVersion", remoteConfig.version).apply()
```

```csharp
// Windows
Settings.Default.WallpaperVersion = remoteConfig.Version;
Settings.Default.Save();
```

---

## 完整壁纸 URL 示例

```
# 12月21日壁纸（8张）
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.EH1.png  # 中文竖版1
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.EH2.png  # 中文竖版2
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.ES1.png  # 中文横版1
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.ES2.png  # 中文横版2
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.CH1.png  # 英文竖版1
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.CH2.png  # 英文竖版2
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.CS1.png  # 英文横版1
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/12/12.21.CS2.png  # 英文横版2

# 1月15日壁纸
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/01/1.15.EH1.png
...
```

---

## 注意事项

1. **version 必须递增**：客户端只有检测到 version 变大才会同步
2. **语言代码反转**：文件名中 E=中文内容，C=英文内容（历史原因）
3. **只下载到今天**：不要下载未来日期的壁纸
4. **缓存策略**：建议本地缓存已下载的壁纸，避免重复下载
5. **错误处理**：配置获取失败时，使用默认日期范围继续工作

---

## 联系方式

如有问题，请联系项目负责人。
