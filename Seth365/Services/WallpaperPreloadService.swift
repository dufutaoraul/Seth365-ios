//
//  WallpaperPreloadService.swift
//  Seth365
//
//  壁纸预加载服务 - 基于 R2 配置的智能同步
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

    // MARK: - 主同步方法

    /// 预加载壁纸（基于 R2 配置的智能同步）
    @MainActor
    func preloadWallpapers() async {
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""
        statusMessage = "正在获取配置..."

        // 1. 获取远程配置
        let config = await WallpaperConfigService.shared.fetchConfig()

        // 2. 检查版本号
        let localVersion = UserDefaultsManager.shared.wallpaperVersion

        // ========== 关键调试信息 ==========
        print("==============================================")
        print("🔴 壁纸同步诊断信息")
        print("==============================================")
        print("🔴 本地版本号: \(localVersion)")
        print("🔴 远程版本号: \(config.version)")
        print("🔴 日期范围: \(config.startDate) ~ \(config.endDate)")

        // 检查缓存目录
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let wallpaperCacheDir = cacheDir.appendingPathComponent("WallpaperCache")
        print("🔴 缓存目录: \(wallpaperCacheDir.path)")

        // 检查缓存目录是否存在及文件数量
        if FileManager.default.fileExists(atPath: wallpaperCacheDir.path) {
            let files = (try? FileManager.default.contentsOfDirectory(atPath: wallpaperCacheDir.path)) ?? []
            print("🔴 缓存目录存在，包含 \(files.count) 个文件")
            if files.count > 0 && files.count <= 10 {
                print("🔴 文件列表: \(files)")
            } else if files.count > 10 {
                print("🔴 前10个文件: \(Array(files.prefix(10)))")
            }
        } else {
            print("🔴 缓存目录不存在!")
        }
        print("==============================================")

        if config.version == localVersion && localVersion > 0 {
            print("🟢 版本相同，跳过同步")
            statusMessage = "壁纸已是最新版本"
            isLoading = false
            return
        }

        print("🟡 版本不同，开始检查缓存...")

        // 3. 根据配置生成壁纸列表
        let allWallpapers = generateWallpaperList(from: config)
        appLog(.info, "配置日期范围: \(config.startDate) ~ \(config.endDate)，共 \(allWallpapers.count) 张", source: "Preload")

        // 4. 检查哪些需要下载
        // 先打印缓存目录路径（调试用）
        let sampleWallpaper = allWallpapers.first!
        let cachePath = ImageCacheService.shared.cacheURL(for: sampleWallpaper).deletingLastPathComponent().path
        appLog(.debug, "缓存目录: \(cachePath)", source: "Preload")

        let bundledWallpapers = allWallpapers.filter { $0.isInBundle }
        let cachedWallpapers = allWallpapers.filter { !$0.isInBundle && isCached($0) }
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle && !isCached($0) }

        appLog(.info, "壁纸统计: 内置=\(bundledWallpapers.count), 已缓存=\(cachedWallpapers.count), 需下载=\(wallpapersToDownload.count)", source: "Preload")

        totalCount = wallpapersToDownload.count

        if wallpapersToDownload.isEmpty {
            statusMessage = "所有壁纸已准备就绪 (\(allWallpapers.count) 张)"
            // 更新本地版本号
            UserDefaultsManager.shared.wallpaperVersion = config.version
            isLoading = false
            return
        }

        statusMessage = "正在同步壁纸 (0/\(wallpapersToDownload.count))..."

        // 5. 下载缺失的壁纸
        var successCount = 0
        var failedCount = 0

        for (index, wallpaper) in wallpapersToDownload.enumerated() {
            do {
                _ = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                successCount += 1
            } catch {
                failedCount += 1
                appLog(.error, "下载失败: \(wallpaper.fileName) - \(error.localizedDescription)", source: "Preload")
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)

            // 每10张更新一次状态消息
            if downloadedCount % 10 == 0 || downloadedCount == totalCount {
                statusMessage = "正在同步壁纸 (\(downloadedCount)/\(totalCount))..."
            }
        }

        // 6. 更新本地版本号
        UserDefaultsManager.shared.wallpaperVersion = config.version

        if failedCount > 0 {
            hasError = true
            errorMessage = "\(failedCount) 张壁纸下载失败"
            statusMessage = "同步完成（\(successCount) 成功，\(failedCount) 失败）"
        } else {
            statusMessage = "同步完成（\(bundledWallpapers.count + cachedWallpapers.count) 张已有 + \(successCount) 张新下载）"
        }

        isLoading = false
    }

    // MARK: - 辅助方法

    /// 根据配置生成壁纸列表
    private func generateWallpaperList(from config: WallpaperConfig) -> [Wallpaper] {
        guard let startDate = config.startDateParsed,
              let endDate = config.endDateParsed else {
            appLog(.error, "配置日期解析失败，使用默认范围", source: "Preload")
            return generateFallbackWallpaperList()
        }

        var wallpapers: [Wallpaper] = []
        var currentDate = startDate

        while currentDate <= endDate {
            wallpapers.append(contentsOf: Wallpaper.allWallpapers(for: currentDate))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }

        return wallpapers
    }

    /// 生成默认壁纸列表（网络不可用时）
    private func generateFallbackWallpaperList() -> [Wallpaper] {
        let calendar = Calendar.current
        var wallpapers: [Wallpaper] = []

        // 2025年12月（12月21日 - 12月31日）
        var dec2025Components = DateComponents()
        dec2025Components.year = 2025
        dec2025Components.month = 12
        for day in 21...31 {
            dec2025Components.day = day
            if let date = calendar.date(from: dec2025Components) {
                wallpapers.append(contentsOf: Wallpaper.allWallpapers(for: date))
            }
        }

        // 2026年1月（1日 - 31日）
        var jan2026Components = DateComponents()
        jan2026Components.year = 2026
        jan2026Components.month = 1
        for day in 1...31 {
            jan2026Components.day = day
            if let date = calendar.date(from: jan2026Components) {
                wallpapers.append(contentsOf: Wallpaper.allWallpapers(for: date))
            }
        }

        // 2026年2月（1日 - 28日）
        var feb2026Components = DateComponents()
        feb2026Components.year = 2026
        feb2026Components.month = 2
        for day in 1...28 {
            feb2026Components.day = day
            if let date = calendar.date(from: feb2026Components) {
                wallpapers.append(contentsOf: Wallpaper.allWallpapers(for: date))
            }
        }

        return wallpapers
    }

    /// 检查壁纸是否已缓存
    private func isCached(_ wallpaper: Wallpaper) -> Bool {
        let cacheURL = ImageCacheService.shared.cacheURL(for: wallpaper)
        let exists = FileManager.default.fileExists(atPath: cacheURL.path)
        // 调试：检查缓存状态
        if !exists {
            appLog(.debug, "未缓存: \(wallpaper.cacheKey) -> \(cacheURL.path)", source: "Preload")
        }
        return exists
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

    /// 检查是否需要预加载
    func shouldPreload() -> Bool {
        // 简单检查：版本号为0表示从未同步过
        return UserDefaultsManager.shared.wallpaperVersion == 0
    }

    // MARK: - 强制更新

    /// 清除缓存并重新下载
    @MainActor
    func clearAndRedownload() async {
        appLog(.info, "开始强制更新...", source: "Preload")

        // 1. 清除图片缓存
        appLog(.info, "清除图片缓存...", source: "Preload")
        await ImageCacheService.shared.clearAllCache()

        // 2. 清除 URLSession 缓存
        appLog(.info, "清除网络缓存...", source: "Preload")
        URLCache.shared.removeAllCachedResponses()

        // 3. 清除壁纸版本号（强制重新同步）
        UserDefaultsManager.shared.clearWallpaperVersion()

        // 4. 重新同步
        appLog(.info, "开始重新同步...", source: "Preload")
        await preloadWallpapers()
    }

    // MARK: - 检查更新

    /// 检查是否有新壁纸（不下载，只检查）
    @MainActor
    func checkForUpdates() async -> Bool {
        let config = await WallpaperConfigService.shared.fetchConfig()
        let localVersion = UserDefaultsManager.shared.wallpaperVersion
        return config.version > localVersion
    }
}
