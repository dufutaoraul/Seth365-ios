//
//  WallpaperPreloadService.swift
//  Seth365
//
//  壁纸预加载服务 - 启动时自动下载壁纸
//

import Foundation
import UIKit
import Combine

/// 壁纸预加载服务
class WallpaperPreloadService: ObservableObject {
    /// 共享实例
    @MainActor static let shared = WallpaperPreloadService()

    /// 是否正在加载
    @Published var isLoading = false

    /// 当前加载进度 (0.0 - 1.0)
    @Published var progress: Double = 0.0

    /// 加载状态消息
    @Published var statusMessage: String = ""

    /// 已下载数量
    @Published var downloadedCount: Int = 0

    /// 总数量
    @Published var totalCount: Int = 0

    /// 是否有错误
    @Published var hasError = false

    /// 错误消息
    @Published var errorMessage: String = ""

    private init() {}

    // MARK: - 预加载壁纸

    /// 根据用户设置预加载壁纸
    @MainActor
    func preloadWallpapers() async {
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""

        let settings = UserDefaultsManager.shared
        let allWallpapers = getWallpapersToPreload(range: settings.switchDateRange)

        // 调试：检查第一个壁纸的 Bundle 路径
        if let firstWallpaper = allWallpapers.first {
            appLog(.debug, "检查壁纸: \(firstWallpaper.fileName)", source: "Preload")
            appLog(.debug, "Bundle相对路径: \(firstWallpaper.bundleRelativePath)", source: "Preload")
            if let fullPath = firstWallpaper.bundleFullPath {
                appLog(.debug, "Bundle完整路径: \(fullPath)", source: "Preload")
                let exists = FileManager.default.fileExists(atPath: fullPath)
                appLog(.debug, "文件存在: \(exists)", source: "Preload")
            } else {
                appLog(.error, "无法获取 Bundle 资源路径", source: "Preload")
            }
            appLog(.debug, "isInBundle: \(firstWallpaper.isInBundle)", source: "Preload")
        }

        // 过滤出需要下载的壁纸（不在 Bundle 中的）
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle }
        let bundledCount = allWallpapers.count - wallpapersToDownload.count

        appLog(.info, "壁纸统计: 总数=\(allWallpapers.count), 内置=\(bundledCount), 需下载=\(wallpapersToDownload.count)", source: "Preload")

        totalCount = wallpapersToDownload.count

        if wallpapersToDownload.isEmpty {
            if bundledCount > 0 {
                statusMessage = "所有壁纸已内置 (\(bundledCount) 张)"
            } else {
                statusMessage = "暂无需要下载的壁纸"
            }
            isLoading = false
            return
        }

        statusMessage = bundledCount > 0
            ? "已内置 \(bundledCount) 张，正在下载 \(wallpapersToDownload.count) 张..."
            : "正在下载壁纸..."

        // 批量下载
        var successCount = 0
        var failedCount = 0

        for (index, wallpaper) in wallpapersToDownload.enumerated() {
            do {
                _ = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                successCount += 1
            } catch {
                failedCount += 1
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)
        }

        if failedCount > 0 {
            hasError = true
            errorMessage = "\(failedCount) 张壁纸下载失败"
            statusMessage = "下载完成（\(successCount)/\(totalCount) 成功）"
        } else {
            statusMessage = bundledCount > 0
                ? "已就绪（\(bundledCount) 张内置 + \(successCount) 张已下载）"
                : "下载完成"
        }

        isLoading = false
    }

    /// 仅预加载今日壁纸
    @MainActor
    func preloadTodayWallpapers() async {
        isLoading = true
        progress = 0.0
        downloadedCount = 0

        let wallpapers = Wallpaper.allWallpapers(for: Date())
        totalCount = wallpapers.count
        statusMessage = "正在下载今日壁纸..."

        for (index, wallpaper) in wallpapers.enumerated() {
            do {
                _ = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
            } catch {
                // 忽略错误，继续下载
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)
        }

        statusMessage = "今日壁纸已准备就绪"
        isLoading = false
    }

    // MARK: - 私有方法

    /// 根据日期范围获取需要预加载的壁纸
    private func getWallpapersToPreload(range: SwitchDateRange) -> [Wallpaper] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var wallpapers: [Wallpaper] = []

        switch range {
        case .today:
            // 只下载今天的8张
            wallpapers = Wallpaper.allWallpapers(for: today)

        case .lastThreeDays:
            // 下载最近3天的24张
            for dayOffset in 0..<3 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    let dayWallpapers = Wallpaper.allWallpapers(for: date)
                    wallpapers.append(contentsOf: dayWallpapers.filter { $0.isUnlocked() })
                }
            }

        case .lastSevenDays:
            // 下载最近7天的56张
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                    let dayWallpapers = Wallpaper.allWallpapers(for: date)
                    wallpapers.append(contentsOf: dayWallpapers.filter { $0.isUnlocked() })
                }
            }

        case .allUnlocked:
            // 下载所有已解锁的壁纸（从2025年12月1日或2026年1月1日开始）
            // 计算从起始日期到今天的所有日期
            let startYear = calendar.component(.year, from: today)
            let startMonth = calendar.component(.month, from: today)

            // 2025年12月测试数据 或 2026年数据
            var startDate: Date
            if startYear == 2025 && startMonth == 12 {
                // 测试模式：从2025年12月1日开始
                var components = DateComponents()
                components.year = 2025
                components.month = 12
                components.day = 1
                startDate = calendar.date(from: components) ?? today
            } else if startYear == 2026 {
                // 正式模式：从2026年1月1日开始
                var components = DateComponents()
                components.year = 2026
                components.month = 1
                components.day = 1
                startDate = calendar.date(from: components) ?? today
            } else {
                // 其他情况，只下载今天
                wallpapers = Wallpaper.allWallpapers(for: today)
                return wallpapers
            }

            // 生成从起始日期到今天的所有壁纸
            var currentDate = startDate
            while currentDate <= today {
                let dayWallpapers = Wallpaper.allWallpapers(for: currentDate)
                wallpapers.append(contentsOf: dayWallpapers)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today.addingTimeInterval(86400)
            }

        case .custom:
            // 使用用户自定义选择的日期
            let customDates = UserDefaultsManager.shared.customSelectedDates
            for date in customDates {
                let dayWallpapers = Wallpaper.allWallpapers(for: date)
                wallpapers.append(contentsOf: dayWallpapers.filter { $0.isUnlocked() })
            }
        }

        return wallpapers
    }

    /// 检查是否需要预加载
    func shouldPreload() -> Bool {
        let settings = UserDefaultsManager.shared

        // 获取需要预加载的壁纸
        let wallpapers = getWallpapersToPreload(range: settings.switchDateRange)

        // 检查有多少壁纸还没有缓存
        // 这里简单返回 true，实际使用时可以检查缓存
        return !wallpapers.isEmpty
    }

    // MARK: - 检查缓存更新

    /// 检查并更新过期的缓存（强制从服务器重新下载）
    @MainActor
    func checkAndUpdateCache() async {
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""

        let settings = UserDefaultsManager.shared
        let allWallpapers = getWallpapersToPreload(range: settings.switchDateRange)

        // 只检查不在 Bundle 中的壁纸
        let wallpapersToCheck = allWallpapers.filter { !$0.isInBundle }
        let bundledCount = allWallpapers.count - wallpapersToCheck.count

        totalCount = wallpapersToCheck.count

        if wallpapersToCheck.isEmpty {
            statusMessage = bundledCount > 0
                ? "所有壁纸已内置，无需更新"
                : "没有需要检查的壁纸"
            isLoading = false
            return
        }

        statusMessage = "正在检查更新..."

        var updatedCount = 0

        for (index, wallpaper) in wallpapersToCheck.enumerated() {
            // 强制重新下载（不使用缓存）
            do {
                _ = try await ImageCacheService.shared.forceUpdateImage(for: wallpaper)
                updatedCount += 1
            } catch {
                // 忽略单个错误，继续下载其他
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)
        }

        statusMessage = "已更新 \(updatedCount) 张壁纸"
        isLoading = false
    }

    /// 清除缓存并重新下载
    @MainActor
    func clearAndRedownload() async {
        print("🔄 开始强制更新...")

        // 1. 清除 ImageCacheService 的缓存
        print("🗑️ 清除图片缓存...")
        await ImageCacheService.shared.clearAllCache()

        // 2. 清除 URLSession 的缓存
        print("🗑️ 清除网络缓存...")
        URLCache.shared.removeAllCachedResponses()

        // 3. 重新下载所有图片（不包括 Bundle 内置的）
        print("📥 开始重新下载...")
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""

        let settings = UserDefaultsManager.shared
        let allWallpapers = getWallpapersToPreload(range: settings.switchDateRange)

        // 过滤出需要下载的壁纸（不在 Bundle 中的）
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle }
        let bundledCount = allWallpapers.count - wallpapersToDownload.count

        totalCount = wallpapersToDownload.count

        if wallpapersToDownload.isEmpty {
            statusMessage = bundledCount > 0
                ? "所有壁纸已内置，无需下载"
                : "没有需要下载的壁纸"
            isLoading = false
            return
        }

        statusMessage = "正在重新下载..."
        print("📥 需要下载 \(totalCount) 张图片（\(bundledCount) 张已内置）")

        var successCount = 0
        var failedCount = 0

        for (index, wallpaper) in wallpapersToDownload.enumerated() {
            do {
                // 使用强制下载（忽略缓存）
                _ = try await ImageCacheService.shared.forceUpdateImage(for: wallpaper)
                successCount += 1
            } catch {
                failedCount += 1
                print("❌ 下载失败: \(wallpaper.fileName) - \(error)")
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)
        }

        if failedCount > 0 {
            hasError = true
            errorMessage = "\(failedCount) 张壁纸下载失败"
            statusMessage = "下载完成（\(successCount)/\(totalCount) 成功）"
        } else {
            statusMessage = bundledCount > 0
                ? "更新完成（\(bundledCount) 张内置 + \(successCount) 张已下载）"
                : "更新完成，请重新进入壁纸页面查看"
        }

        print("✅ 强制更新完成: \(successCount) 成功, \(failedCount) 失败")
        isLoading = false
    }
}
