//
//  ImageCacheService.swift
//  Seth365
//
//  图片缓存服务（内存 + 磁盘）
//

import Foundation
import UIKit

/// 图片缓存服务
actor ImageCacheService {
    /// 共享实例
    static let shared = ImageCacheService()

    /// 内存缓存
    private let memoryCache = NSCache<NSString, UIImage>()

    /// 磁盘缓存目录
    private let diskCacheDirectory: URL

    private init() {
        // 配置内存缓存
        memoryCache.countLimit = Constants.Cache.memoryLimit

        // 创建磁盘缓存目录
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("WallpaperCache", isDirectory: true)

        // 确保目录存在
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - 公共方法

    /// 获取壁纸图片（优先缓存）
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: UIImage（如果缓存中存在）
    func getImage(for wallpaper: Wallpaper) async -> UIImage? {
        let key = wallpaper.cacheKey

        // 1. 检查内存缓存
        if let image = getFromMemory(key: key) {
            return image
        }

        // 2. 检查磁盘缓存
        if let image = getFromDisk(key: key) {
            // 加载到内存缓存
            saveToMemory(image: image, key: key)
            return image
        }

        return nil
    }

    /// 保存图片到缓存
    /// - Parameters:
    ///   - image: 图片
    ///   - wallpaper: 壁纸模型
    func saveImage(_ image: UIImage, for wallpaper: Wallpaper) async {
        let key = wallpaper.cacheKey
        saveToMemory(image: image, key: key)
        saveToDisk(image: image, key: key)
    }

    /// 获取或下载图片
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: UIImage
    func getOrDownloadImage(for wallpaper: Wallpaper) async throws -> UIImage {
        let key = wallpaper.cacheKey

        // 1. 先检查内存缓存
        if let cachedImage = await getImage(for: wallpaper) {
            print("💾 从缓存加载: \(key)")
            return cachedImage
        }

        // 2. 检查 Bundle 内置资源
        if let bundleImage = getFromBundle(wallpaper: wallpaper) {
            print("📦 从 Bundle 加载: \(key)")
            // 保存到内存缓存以加速后续访问
            saveToMemory(image: bundleImage, key: key)
            return bundleImage
        }

        // 3. 从网络下载（仅当 Bundle 中没有时）
        print("🌐 从网络下载: \(key)")
        let image = try await NetworkService.shared.downloadWallpaper(wallpaper)

        // 保存到缓存
        await saveImage(image, for: wallpaper)

        return image
    }

    /// 从 Bundle 获取图片
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: Bundle 中的图片，如果不存在则返回 nil
    private func getFromBundle(wallpaper: Wallpaper) -> UIImage? {
        // 使用完整路径（适用于文件夹引用）
        guard let fullPath = wallpaper.bundleFullPath,
              FileManager.default.fileExists(atPath: fullPath),
              let image = UIImage(contentsOfFile: fullPath) else {
            return nil
        }
        return image
    }

    /// 清除内存缓存
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// 清除磁盘缓存
    func clearDiskCache() {
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    /// 清除所有缓存
    func clearAllCache() {
        print("🗑️ 清除所有图片缓存...")
        clearMemoryCache()
        clearDiskCache()
        print("🗑️ 缓存清除完成")
    }

    /// 获取磁盘缓存大小（字节）
    func getDiskCacheSize() -> Int64 {
        var size: Int64 = 0
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }

    /// 获取壁纸的缓存文件 URL
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: 缓存文件的 URL
    nonisolated func cacheURL(for wallpaper: Wallpaper) -> URL {
        // diskCacheDirectory 是在 init 时设置的不可变路径，可以安全地从非隔离上下文访问
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let wallpaperCacheDir = cacheDir.appendingPathComponent("WallpaperCache", isDirectory: true)
        return wallpaperCacheDir.appendingPathComponent(wallpaper.cacheKey)
    }

    /// 检查缓存是否需要更新
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: 是否需要更新（true = 需要重新下载）
    func needsUpdate(for wallpaper: Wallpaper) async -> Bool {
        // 如果图片在 Bundle 中，不需要更新
        if getFromBundle(wallpaper: wallpaper) != nil {
            return false
        }

        // 如果本地没有缓存，则需要下载
        let key = wallpaper.cacheKey
        guard getFromDisk(key: key) != nil else {
            return true
        }

        // 检查远程文件是否更新
        guard let remoteURL = wallpaper.remoteURL else {
            return false
        }

        // 添加时间戳绕过 CDN 缓存
        guard var components = URLComponents(url: remoteURL, resolvingAgainstBaseURL: false) else {
            return false
        }
        let timestamp = String(Int(Date().timeIntervalSince1970))
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "t", value: timestamp)]
        guard let bustURL = components.url else {
            return false
        }

        // 使用 HEAD 请求检查远程文件
        var request = URLRequest(url: bustURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            // 获取远程文件的 Last-Modified 或 ETag
            let etag = httpResponse.value(forHTTPHeaderField: "ETag")
            let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified")

            // 检查本地保存的 ETag/LastModified
            let savedEtag = getSavedEtag(for: key)
            let savedLastModified = getSavedLastModified(for: key)

            // 如果远程有 ETag，比较 ETag
            if let etag = etag, let savedEtag = savedEtag {
                return etag != savedEtag
            }

            // 如果远程有 Last-Modified，比较 Last-Modified
            if let lastModified = lastModified, let savedLastModified = savedLastModified {
                return lastModified != savedLastModified
            }

            // 如果之前没有保存元数据，但现在有，说明是旧缓存
            if etag != nil || lastModified != nil {
                // 保存新的元数据
                if let etag = etag {
                    saveEtag(etag, for: key)
                }
                if let lastModified = lastModified {
                    saveLastModified(lastModified, for: key)
                }
            }

            return false
        } catch {
            return false
        }
    }

    /// 强制更新缓存（忽略网络缓存，从 R2 重新下载）
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: 更新后的图片
    func forceUpdateImage(for wallpaper: Wallpaper) async throws -> UIImage {
        let key = wallpaper.cacheKey

        // 先清除本地磁盘缓存
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)

        // 清除内存缓存
        memoryCache.removeObject(forKey: key as NSString)

        // 强制从网络下载（忽略网络缓存）
        let image = try await NetworkService.shared.forceDownloadWallpaper(wallpaper)

        // 保存到缓存
        await saveImage(image, for: wallpaper)

        // 保存元数据
        if let remoteURL = wallpaper.remoteURL {
            await saveRemoteMetadata(from: remoteURL, for: key)
        }

        return image
    }

    // MARK: - 元数据存储

    private var metadataDirectory: URL {
        diskCacheDirectory.appendingPathComponent("metadata", isDirectory: true)
    }

    private func getSavedEtag(for key: String) -> String? {
        let fileURL = metadataDirectory.appendingPathComponent("\(key).etag")
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private func saveEtag(_ etag: String, for key: String) {
        try? FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        let fileURL = metadataDirectory.appendingPathComponent("\(key).etag")
        try? etag.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func getSavedLastModified(for key: String) -> String? {
        let fileURL = metadataDirectory.appendingPathComponent("\(key).lastmod")
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private func saveLastModified(_ lastModified: String, for key: String) {
        try? FileManager.default.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
        let fileURL = metadataDirectory.appendingPathComponent("\(key).lastmod")
        try? lastModified.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private func saveRemoteMetadata(from url: URL, for key: String) async {
        // 添加时间戳绕过 CDN 缓存
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let timestamp = String(Int(Date().timeIntervalSince1970))
        components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "t", value: timestamp)]
        guard let bustURL = components.url else { return }

        var request = URLRequest(url: bustURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
                saveEtag(etag, for: key)
            }
            if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
                saveLastModified(lastModified, for: key)
            }
        } catch {
            // 忽略错误
        }
    }

    // MARK: - 私有方法

    /// 从内存缓存获取
    private func getFromMemory(key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }

    /// 保存到内存缓存
    private func saveToMemory(image: UIImage, key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
    }

    /// 从磁盘缓存获取
    private func getFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    /// 保存到磁盘缓存
    private func saveToDisk(image: UIImage, key: String) {
        let fileURL = diskCacheDirectory.appendingPathComponent(key)
        guard let data = image.pngData() else { return }
        try? data.write(to: fileURL)
    }
}
