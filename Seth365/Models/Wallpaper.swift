//
//  Wallpaper.swift
//  Seth365
//
//  壁纸数据模型（核心）
//

import Foundation

/// 壁纸数据模型
struct Wallpaper: Identifiable, Equatable, Hashable {
    /// 壁纸日期
    let date: Date

    /// 语言类型
    let language: WallpaperLanguage

    /// 方向类型
    let orientation: WallpaperOrientation

    /// 序号 (1 或 2)
    let index: Int

    /// 唯一标识符
    var id: String { fileName }

    // MARK: - 计算属性

    /// 年份
    var year: Int {
        Calendar.current.component(.year, from: date)
    }

    /// 月份 (1-12)
    var month: Int {
        Calendar.current.component(.month, from: date)
    }

    /// 日期 (1-31)
    var day: Int {
        Calendar.current.component(.day, from: date)
    }

    /// 文件名
    /// 统一格式: "{年后两位}.{月}.{日}.{类型}.png"
    /// 示例: "25.12.21.CS1.png", "26.1.15.EH2.png"
    var fileName: String {
        let yearPrefix = year % 100  // 25 或 26
        return "\(yearPrefix).\(month).\(day).\(language.rawValue)\(orientation.rawValue)\(index).png"
    }

    /// 本地缓存路径
    var localPath: String {
        "\(month)/\(fileName)"
    }

    /// Bundle 内的资源相对路径（含扩展名）
    /// 统一格式: Wallpapers/{年后两位}/{月两位数}/{文件名}
    var bundleRelativePath: String {
        let yearPrefix = year % 100
        let monthStr = String(format: "%02d", month)
        return "Wallpapers/\(yearPrefix)/\(monthStr)/\(fileName)"
    }

    /// Bundle 内的完整路径
    var bundleFullPath: String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        return "\(resourcePath)/\(bundleRelativePath)"
    }

    /// 检查图片是否已打包在 Bundle 中
    var isInBundle: Bool {
        guard let fullPath = bundleFullPath else { return false }
        return FileManager.default.fileExists(atPath: fullPath)
    }

    /// 兼容旧代码的 bundlePath（不含扩展名）
    var bundlePath: String {
        return fileName.replacingOccurrences(of: ".png", with: "")
    }

    /// 远程 URL
    var remoteURL: URL? {
        R2Config.wallpaperURL(year: year, month: month, fileName: fileName)
    }

    /// 缓存键
    var cacheKey: String {
        fileName
    }

    /// 显示名称，如 "12月1日 中文竖版 1"
    var displayName: String {
        "\(month)月\(day)日 \(language.displayName)\(orientation.displayName) \(index)"
    }

    /// 简短显示名称，如 "中竖1"
    var shortDisplayName: String {
        "\(language.shortName)\(orientation.shortName)\(index)"
    }

    // MARK: - 解锁逻辑

    /// 检查壁纸是否已解锁（壁纸日期 <= 当前日期）
    /// - Parameter referenceDate: 参考日期，默认为当前日期
    /// - Returns: 是否已解锁
    func isUnlocked(referenceDate: Date = Date()) -> Bool {
        // 只比较日期，忽略时间
        let calendar = Calendar.current
        let wallpaperDay = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: referenceDate)
        return wallpaperDay <= today
    }

    // MARK: - 静态工厂方法

    /// 获取指定日期的所有 8 张壁纸
    /// - Parameter date: 日期
    /// - Returns: 8 张壁纸数组
    static func allWallpapers(for date: Date) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []

        for language in WallpaperLanguage.allCases {
            for orientation in WallpaperOrientation.allCases {
                for index in 1...2 {
                    let wallpaper = Wallpaper(
                        date: date,
                        language: language,
                        orientation: orientation,
                        index: index
                    )
                    wallpapers.append(wallpaper)
                }
            }
        }

        return wallpapers
    }

    /// 获取指定日期的筛选壁纸
    /// - Parameters:
    ///   - date: 日期
    ///   - language: 语言筛选（nil 表示全部）
    ///   - orientation: 方向筛选（nil 表示全部）
    /// - Returns: 筛选后的壁纸数组
    static func filteredWallpapers(
        for date: Date,
        language: WallpaperLanguage? = nil,
        orientation: WallpaperOrientation? = nil
    ) -> [Wallpaper] {
        var wallpapers = allWallpapers(for: date)

        if let language = language {
            wallpapers = wallpapers.filter { $0.language == language }
        }

        if let orientation = orientation {
            wallpapers = wallpapers.filter { $0.orientation == orientation }
        }

        return wallpapers
    }
}

// MARK: - 日期扩展

extension Wallpaper {
    /// 检查日期是否在 2026 年内
    var isIn2026: Bool {
        let year = Calendar.current.component(.year, from: date)
        return year == 2026
    }
}
