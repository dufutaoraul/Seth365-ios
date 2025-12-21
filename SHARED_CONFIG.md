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

### ⚠️ 文件路径规则（统一格式，所有年份一致）

```
/wallpapers/{年份后两位}/{月份两位}/{文件名}
```

**示例：**
```
# 2025年12月21日
/wallpapers/25/12/25.12.21.CS1.png

# 2026年1月15日
/wallpapers/26/01/26.1.15.CS1.png

# 2026年12月25日
/wallpapers/26/12/26.12.25.CS1.png
```

### 文件名格式
```
{年份后两位}.{月}.{日}.{语言}{方向}{序号}.png

语言: C=中文(Chinese), E=英文(English)
方向: S=竖版(Standing), H=横版(Horizontal)
序号: 1 或 2

示例:
- 25.12.21.CS1.png  → 2025年12月21日，中文竖版第1张
- 25.12.21.CH1.png  → 2025年12月21日，中文横版第1张
- 25.12.21.ES1.png  → 2025年12月21日，英文竖版第1张
- 25.12.21.EH1.png  → 2025年12月21日，英文横版第1张
- 26.1.15.CS1.png   → 2026年1月15日，中文竖版第1张
```

### 每日壁纸数量
- 每天 8 张壁纸
- 中文竖版: 2张 (CS1, CS2)
- 中文横版: 2张 (CH1, CH2)
- 英文竖版: 2张 (ES1, ES2)
- 英文横版: 2张 (EH1, EH2)

---

## R2 存储结构

```
wallpapers/
├── 25/                          # 2025年
│   └── 12/                      # 12月
│       ├── 25.12.21.CS1.png
│       ├── 25.12.21.CS2.png
│       ├── 25.12.21.CH1.png
│       ├── 25.12.21.CH2.png
│       ├── 25.12.21.ES1.png
│       ├── 25.12.21.ES2.png
│       ├── 25.12.21.EH1.png
│       ├── 25.12.21.EH2.png
│       └── ... (12月其他日期)
├── 26/                          # 2026年
│   ├── 01/                      # 1月
│   │   ├── 26.1.1.CS1.png
│   │   └── ...
│   ├── 02/                      # 2月
│   │   ├── 26.2.1.CS1.png
│   │   └── ...
│   └── 12/                      # 12月（未来）
│       ├── 26.12.1.CS1.png
│       └── ...
```

---

## 客户端实现逻辑

### 1. 获取远程配置

```python
# Python (Windows)
import time
config_url = f"https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpaper-config.json?t={int(time.time())}"
```

```swift
// Swift (macOS/iOS)
let timestamp = Int(Date().timeIntervalSince1970)
let configUrl = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpaper-config.json?t=\(timestamp)"
```

> 添加时间戳参数 `?t=xxx` 绕过 CDN 缓存

### 2. 版本比对

```python
# Python
local_version = settings.wallpaper_version  # 默认 0
if local_version == remote_config.version:
    # 版本相同，跳过同步
    return
```

### 3. 生成壁纸 URL

```python
# Python
def get_wallpaper_url(year: int, month: int, day: int, lang: str, orient: str, index: int) -> str:
    base_url = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers"
    year_short = year % 100
    month_str = str(month).zfill(2)
    file_name = f"{year_short}.{month}.{day}.{lang}{orient}{index}.png"
    return f"{base_url}/{year_short}/{month_str}/{file_name}"

# 示例
get_wallpaper_url(2025, 12, 21, "C", "S", 1)
# → https://xxx.r2.dev/wallpapers/25/12/25.12.21.CS1.png

get_wallpaper_url(2026, 1, 15, "E", "H", 2)
# → https://xxx.r2.dev/wallpapers/26/01/26.1.15.EH2.png
```

### 4. 下载壁纸

- 只下载到**今天**为止（未来日期不下载）
- 检查本地缓存，跳过已下载的
- 下载失败时使用默认配置继续

### 5. 更新本地版本号

下载完成后，保存远程 version 到本地：

```python
# Python
settings.wallpaper_version = remote_config.version
settings.wallpaper_last_sync = datetime.now().isoformat()
```

---

## 本地缓存路径

| 平台 | 缓存目录 |
|------|---------|
| Windows | `%LOCALAPPDATA%\Seth365\cache\wallpapers\{年}\{月}\` |
| macOS | `~/Library/Caches/com.xxx.Seth365Mac/wallpapers/{年}/{月}/` |
| iOS | `Documents/wallpapers/{年}/{月}/` |
| Android | `内部存储/Android/data/com.xxx.seth365/cache/wallpapers/{年}/{月}/` |

缓存结构与 R2 结构一致：
```
wallpapers/
├── 25/
│   └── 12/
│       ├── 25.12.21.CS1.png
│       └── ...
└── 26/
    ├── 01/
    └── 02/
```

---

## 完整壁纸 URL 示例

```
# 2025年12月21日壁纸（8张）
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.CS1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.CS2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.CH1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.CH2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.ES1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.ES2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.EH1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/25/12/25.12.21.EH2.png

# 2026年1月15日壁纸（8张）
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.CS1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.CS2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.CH1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.CH2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.ES1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.ES2.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.EH1.png
https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/wallpapers/26/01/26.1.15.EH2.png
```

---

## 注意事项

1. **version 必须递增**：客户端只有检测到 version 变大才会同步
2. **路径统一**：所有年份的壁纸都使用 `/{年}/{月}/{年.月.日.xx.png}` 格式
3. **只下载到今天**：不要下载未来日期的壁纸
4. **缓存策略**：本地缓存已下载的壁纸，避免重复下载
5. **错误处理**：配置获取失败时，使用默认日期范围继续工作
6. **文件大小**：正式壁纸约 1-2MB，如果只有几十KB可能是测试图

---

## 联系方式

如有问题，请联系项目负责人。
