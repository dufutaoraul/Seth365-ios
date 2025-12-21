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

    /// 预加载所有壁纸（不在 Bundle 中的自动下载，已下载的检查更新）
    @MainActor
    func preloadWallpapers() async {
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""

        // 获取全年所有壁纸（2025年12月测试 + 2026年全年）
        let allWallpapers = getAllYearWallpapers()

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

        // 分类壁纸
        let bundledWallpapers = allWallpapers.filter { $0.isInBundle }
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle }

        appLog(.info, "壁纸统计: 总数=\(allWallpapers.count), 内置=\(bundledWallpapers.count), 需下载=\(wallpapersToDownload.count)", source: "Preload")

        totalCount = wallpapersToDownload.count

        if wallpapersToDownload.isEmpty {
            statusMessage = "所有壁纸已内置 (\(bundledWallpapers.count) 张)"
            isLoading = false
            return
        }

        statusMessage = "正在同步壁纸 (0/\(wallpapersToDownload.count))..."

        // 批量下载（检查是否需要更新）
        var successCount = 0
        var failedCount = 0
        var updatedCount = 0

        for (index, wallpaper) in wallpapersToDownload.enumerated() {
            do {
                // 检查是否需要更新（比较 ETag/Last-Modified）
                let needsUpdate = await ImageCacheService.shared.needsUpdate(for: wallpaper)

                if needsUpdate {
                    // 需要更新，强制重新下载
                    _ = try await ImageCacheService.shared.forceUpdateImage(for: wallpaper)
                    updatedCount += 1
                } else {
                    // 不需要更新，使用缓存或下载新的
                    _ = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                }
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

        if failedCount > 0 {
            hasError = true
            errorMessage = "\(failedCount) 张壁纸下载失败"
            statusMessage = "同步完成（\(successCount) 成功，\(failedCount) 失败）"
        } else {
            let updateInfo = updatedCount > 0 ? "，\(updatedCount) 张已更新" : ""
            statusMessage = "同步完成（\(bundledWallpapers.count) 张内置 + \(successCount) 张已下载\(updateInfo)）"
        }

        isLoading = false
    }

    /// 获取所有可用壁纸（仅 R2 上有的：2025年12月21日 - 2026年2月28日）
    /// 注意：当 R2 添加更多月份时，需要更新此方法
    private func getAllYearWallpapers() -> [Wallpaper] {
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

        // 总计：11天 × 8 + 31天 × 8 + 28天 × 8 = 88 + 248 + 224 = 560 张壁纸

        return wallpapers
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
        // 获取全年壁纸
        let allWallpapers = getAllYearWallpapers()

        // 检查是否有不在 Bundle 中的壁纸需要下载
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle }
        return !wallpapersToDownload.isEmpty
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

        let allWallpapers = getAllYearWallpapers()

        // 只检查不在 Bundle 中的壁纸
        let wallpapersToCheck = allWallpapers.filter { !$0.isInBundle }
        let bundledCount = allWallpapers.count - wallpapersToCheck.count

        totalCount = wallpapersToCheck.count

        if wallpapersToCheck.isEmpty {
            statusMessage = "所有壁纸已内置，无需更新"
            isLoading = false
            return
        }

        statusMessage = "正在检查更新 (0/\(wallpapersToCheck.count))..."

        var updatedCount = 0

        for (index, wallpaper) in wallpapersToCheck.enumerated() {
            // 检查是否需要更新
            let needsUpdate = await ImageCacheService.shared.needsUpdate(for: wallpaper)

            if needsUpdate {
                do {
                    _ = try await ImageCacheService.shared.forceUpdateImage(for: wallpaper)
                    updatedCount += 1
                } catch {
                    // 忽略单个错误，继续检查其他
                }
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)

            if downloadedCount % 10 == 0 || downloadedCount == totalCount {
                statusMessage = "正在检查更新 (\(downloadedCount)/\(totalCount))..."
            }
        }

        statusMessage = updatedCount > 0
            ? "检查完成，已更新 \(updatedCount) 张壁纸"
            : "检查完成，所有壁纸均为最新"
        isLoading = false
    }

    /// 清除缓存并重新下载
    @MainActor
    func clearAndRedownload() async {
        appLog(.info, "开始强制更新...", source: "Preload")

        // 1. 清除 ImageCacheService 的缓存
        appLog(.info, "清除图片缓存...", source: "Preload")
        await ImageCacheService.shared.clearAllCache()

        // 2. 清除 URLSession 的缓存
        appLog(.info, "清除网络缓存...", source: "Preload")
        URLCache.shared.removeAllCachedResponses()

        // 3. 重新下载所有图片（不包括 Bundle 内置的）
        appLog(.info, "开始重新下载...", source: "Preload")
        isLoading = true
        progress = 0.0
        downloadedCount = 0
        hasError = false
        errorMessage = ""

        let allWallpapers = getAllYearWallpapers()

        // 过滤出需要下载的壁纸（不在 Bundle 中的）
        let wallpapersToDownload = allWallpapers.filter { !$0.isInBundle }
        let bundledCount = allWallpapers.count - wallpapersToDownload.count

        totalCount = wallpapersToDownload.count

        if wallpapersToDownload.isEmpty {
            statusMessage = "所有壁纸已内置，无需下载"
            isLoading = false
            return
        }

        statusMessage = "正在重新下载 (0/\(totalCount))..."
        appLog(.info, "需要下载 \(totalCount) 张图片（\(bundledCount) 张已内置）", source: "Preload")

        var successCount = 0
        var failedCount = 0

        for (index, wallpaper) in wallpapersToDownload.enumerated() {
            do {
                // 使用强制下载（忽略缓存）
                _ = try await ImageCacheService.shared.forceUpdateImage(for: wallpaper)
                successCount += 1
            } catch {
                failedCount += 1
                appLog(.error, "下载失败: \(wallpaper.fileName) - \(error.localizedDescription)", source: "Preload")
            }

            downloadedCount = index + 1
            progress = Double(downloadedCount) / Double(totalCount)

            if downloadedCount % 10 == 0 || downloadedCount == totalCount {
                statusMessage = "正在重新下载 (\(downloadedCount)/\(totalCount))..."
            }
        }

        if failedCount > 0 {
            hasError = true
            errorMessage = "\(failedCount) 张壁纸下载失败"
            statusMessage = "下载完成（\(successCount) 成功，\(failedCount) 失败）"
        } else {
            statusMessage = "更新完成（\(bundledCount) 张内置 + \(successCount) 张已下载）"
        }

        appLog(.info, "强制更新完成: \(successCount) 成功, \(failedCount) 失败", source: "Preload")
        isLoading = false
    }
}
