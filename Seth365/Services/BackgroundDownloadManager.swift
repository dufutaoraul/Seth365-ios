//
//  BackgroundDownloadManager.swift
//  Seth365
//
//  后台下载管理器 - 支持 App 在后台时继续下载
//

import Foundation
import UIKit
import Combine

/// 后台下载管理器
class BackgroundDownloadManager: NSObject, ObservableObject {
    /// 共享实例
    static let shared = BackgroundDownloadManager()

    /// 后台会话标识符
    static let backgroundSessionIdentifier = "com.seth365.backgroundDownload"

    /// 后台 URLSession
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundSessionIdentifier)
        config.isDiscretionary = false  // 立即开始下载，不等待最佳时机
        config.sessionSendsLaunchEvents = true  // 下载完成时唤醒 App
        config.allowsCellularAccess = true  // 允许使用蜂窝网络
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60 * 60  // 1 小时超时
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// 后台完成回调（AppDelegate 使用）
    var backgroundCompletionHandler: (() -> Void)?

    /// 下载进度 (0.0 - 1.0)
    @Published var progress: Double = 0.0

    /// 已完成数量
    @Published var completedCount: Int = 0

    /// 总数量
    @Published var totalCount: Int = 0

    /// 是否正在下载
    @Published var isDownloading: Bool = false

    /// 错误信息
    @Published var errorMessage: String?

    /// 待下载任务（URL -> 本地保存路径）
    private var pendingDownloads: [URL: URL] = [:]

    /// 活跃的下载任务
    private var activeTasksMap: [Int: URL] = [:]  // taskIdentifier -> remoteURL

    /// 下载完成的 URL
    private var completedURLs: Set<URL> = []

    /// 下载完成回调
    var onAllDownloadsComplete: (() -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - 公共方法

    /// 开始批量下载壁纸
    /// - Parameter wallpapers: 要下载的壁纸列表
    func startDownloading(wallpapers: [Wallpaper]) {
        guard !wallpapers.isEmpty else {
            appLog(.info, "没有需要下载的壁纸", source: "BackgroundDownload")
            return
        }

        DispatchQueue.main.async {
            self.isDownloading = true
            self.totalCount = wallpapers.count
            self.completedCount = 0
            self.progress = 0.0
            self.errorMessage = nil
            self.completedURLs.removeAll()
        }

        appLog(.info, "开始后台下载 \(wallpapers.count) 张壁纸", source: "BackgroundDownload")

        // 创建下载任务
        for wallpaper in wallpapers {
            guard let remoteURL = wallpaper.remoteURL else { continue }

            // 计算本地保存路径
            let localURL = cacheURL(for: wallpaper)
            pendingDownloads[remoteURL] = localURL

            // 创建下载任务
            let task = backgroundSession.downloadTask(with: remoteURL)
            activeTasksMap[task.taskIdentifier] = remoteURL
            task.resume()
        }
    }

    /// 取消所有下载
    func cancelAllDownloads() {
        backgroundSession.getAllTasks { tasks in
            for task in tasks {
                task.cancel()
            }
        }

        DispatchQueue.main.async {
            self.isDownloading = false
            self.pendingDownloads.removeAll()
            self.activeTasksMap.removeAll()
        }

        appLog(.info, "已取消所有后台下载", source: "BackgroundDownload")
    }

    /// 恢复之前的下载任务（App 重新启动时调用）
    func resumePendingDownloads() {
        backgroundSession.getAllTasks { [weak self] tasks in
            guard let self = self else { return }

            let activeTasks = tasks.filter { $0.state == .running || $0.state == .suspended }

            if !activeTasks.isEmpty {
                appLog(.info, "恢复 \(activeTasks.count) 个后台下载任务", source: "BackgroundDownload")

                DispatchQueue.main.async {
                    self.isDownloading = true
                    self.totalCount = activeTasks.count
                }

                for task in activeTasks {
                    if task.state == .suspended {
                        task.resume()
                    }
                }
            }
        }
    }

    // MARK: - 私有方法

    /// 获取壁纸的缓存路径
    private func cacheURL(for wallpaper: Wallpaper) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let wallpaperCacheDir = cacheDir.appendingPathComponent("WallpaperCache", isDirectory: true)

        // 确保目录存在
        try? FileManager.default.createDirectory(at: wallpaperCacheDir, withIntermediateDirectories: true)

        return wallpaperCacheDir.appendingPathComponent(wallpaper.cacheKey)
    }

    /// 更新进度
    private func updateProgress() {
        DispatchQueue.main.async {
            self.completedCount = self.completedURLs.count
            if self.totalCount > 0 {
                self.progress = Double(self.completedCount) / Double(self.totalCount)
            }

            // 检查是否全部完成
            if self.completedCount >= self.totalCount && self.totalCount > 0 {
                self.isDownloading = false
                appLog(.info, "后台下载完成: \(self.completedCount)/\(self.totalCount)", source: "BackgroundDownload")
                self.onAllDownloadsComplete?()
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadManager: URLSessionDownloadDelegate {

    /// 下载完成
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let remoteURL = activeTasksMap[downloadTask.taskIdentifier],
              let localURL = pendingDownloads[remoteURL] else {
            appLog(.warning, "下载完成但找不到对应任务", source: "BackgroundDownload")
            return
        }

        do {
            // 如果文件已存在，先删除
            if FileManager.default.fileExists(atPath: localURL.path) {
                try FileManager.default.removeItem(at: localURL)
            }

            // 移动下载的文件到缓存目录
            try FileManager.default.moveItem(at: location, to: localURL)

            completedURLs.insert(remoteURL)
            appLog(.debug, "下载成功: \(remoteURL.lastPathComponent)", source: "BackgroundDownload")

        } catch {
            appLog(.error, "保存下载文件失败: \(error.localizedDescription)", source: "BackgroundDownload")
        }

        // 清理
        activeTasksMap.removeValue(forKey: downloadTask.taskIdentifier)
        pendingDownloads.removeValue(forKey: remoteURL)

        updateProgress()
    }

    /// 下载出错
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError

            // 忽略取消错误
            if nsError.code == NSURLErrorCancelled {
                return
            }

            appLog(.error, "下载失败: \(error.localizedDescription)", source: "BackgroundDownload")

            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }

        // 即使出错也要更新进度（计入已处理）
        if let remoteURL = activeTasksMap[task.taskIdentifier] {
            completedURLs.insert(remoteURL)
            activeTasksMap.removeValue(forKey: task.taskIdentifier)
            pendingDownloads.removeValue(forKey: remoteURL)
            updateProgress()
        }
    }

    /// 后台会话完成所有事件
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            // 调用 AppDelegate 保存的完成回调
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil

            appLog(.info, "后台会话事件处理完成", source: "BackgroundDownload")
        }
    }
}
