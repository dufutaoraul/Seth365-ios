//
//  NetworkService.swift
//  Seth365
//
//  网络服务（图片下载）
//

import Foundation
import UIKit

/// 网络服务错误
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case invalidData
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .invalidData:
            return "无效的数据"
        case .decodingFailed:
            return "数据解码失败"
        }
    }
}

/// 网络服务
actor NetworkService {
    /// 共享实例
    static let shared = NetworkService()

    /// 普通 URLSession（使用缓存）
    private let session: URLSession

    /// 强制刷新 URLSession（不使用缓存）
    private let refreshSession: URLSession

    private init() {
        // 普通配置（可使用缓存）
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)

        // 强制刷新配置（忽略缓存）
        let refreshConfig = URLSessionConfiguration.default
        refreshConfig.timeoutIntervalForRequest = 30
        refreshConfig.timeoutIntervalForResource = 60
        refreshConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.refreshSession = URLSession(configuration: refreshConfig)
    }

    /// 下载图片（使用缓存）
    /// - Parameter url: 图片 URL
    /// - Returns: UIImage
    func downloadImage(from url: URL) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        guard let image = UIImage(data: data) else {
            throw NetworkError.invalidData
        }

        return image
    }

    /// 强制从网络下载图片（忽略缓存）
    /// - Parameter url: 图片 URL
    /// - Returns: UIImage
    func forceDownloadImage(from url: URL) async throws -> UIImage {
        // 添加缓存破坏参数，强制 CDN 返回最新内容
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let cacheBuster = URLQueryItem(name: "_t", value: timestamp)
        var existingItems = components.queryItems ?? []
        existingItems.append(cacheBuster)
        components.queryItems = existingItems

        guard let bustURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: bustURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache, no-store, must-revalidate", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        print("🌐 强制下载: \(bustURL.absoluteString)")

        let (data, response) = try await refreshSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ 下载失败: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw NetworkError.invalidResponse
        }

        guard let image = UIImage(data: data) else {
            throw NetworkError.invalidData
        }

        print("✅ 下载成功: \(url.lastPathComponent) (\(data.count) bytes)")
        return image
    }

    /// 下载壁纸（添加时间戳绕过 CDN 缓存）
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: UIImage
    func downloadWallpaper(_ wallpaper: Wallpaper) async throws -> UIImage {
        guard let url = wallpaper.remoteURL else {
            throw NetworkError.invalidURL
        }

        // 添加时间戳绕过 CDN 缓存（R2 更新后 CDN 可能返回旧版本）
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let cacheBuster = URLQueryItem(name: "t", value: timestamp)
        var existingItems = components.queryItems ?? []
        existingItems.append(cacheBuster)
        components.queryItems = existingItems

        guard let bustURL = components.url else {
            throw NetworkError.invalidURL
        }

        print("🌐 下载壁纸: \(bustURL.absoluteString)")
        return try await downloadImage(from: bustURL)
    }

    /// 强制下载壁纸（忽略缓存）
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: UIImage
    func forceDownloadWallpaper(_ wallpaper: Wallpaper) async throws -> UIImage {
        guard let url = wallpaper.remoteURL else {
            throw NetworkError.invalidURL
        }

        return try await forceDownloadImage(from: url)
    }

    /// 下载数据
    /// - Parameter url: URL
    /// - Returns: Data
    func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        return data
    }
}
