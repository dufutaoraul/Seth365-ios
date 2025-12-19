//
//  AppUpdateService.swift
//  Seth365
//
//  App Store 版本检测服务
//

import Foundation
import UIKit
import Combine

/// App Store 版本检测服务
class AppUpdateService: ObservableObject {
    /// 共享实例
    static let shared = AppUpdateService()

    /// 是否正在检查
    @Published var isChecking = false

    /// 最新版本号
    @Published var latestVersion: String?

    /// 是否有新版本
    @Published var hasUpdate = false

    /// 检查错误信息
    @Published var errorMessage: String?

    /// App Store 链接
    @Published var appStoreURL: URL?

    /// 上次检查时间
    @Published var lastCheckTime: Date?

    private init() {}

    // MARK: - iTunes Lookup API

    /// iTunes Lookup API 响应结构
    private struct iTunesLookupResponse: Decodable {
        let resultCount: Int
        let results: [AppInfo]

        struct AppInfo: Decodable {
            let version: String
            let trackViewUrl: String
            let trackId: Int
        }
    }

    // MARK: - 检查更新

    /// 检查 App Store 是否有新版本
    @MainActor
    func checkForUpdate() async {
        isChecking = true
        errorMessage = nil

        // 获取 Bundle ID
        let bundleID = AppInfo.bundleID

        // iTunes Lookup API URL
        // 使用中国区 App Store
        guard let url = URL(string: "https://itunes.apple.com/cn/lookup?bundleId=\(bundleID)") else {
            errorMessage = "无法构建请求 URL"
            isChecking = false
            return
        }

        do {
            // 创建不使用缓存的请求
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

            let (data, response) = try await URLSession.shared.data(for: request)

            // 检查 HTTP 响应
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                errorMessage = "服务器响应错误"
                isChecking = false
                return
            }

            // 解析响应
            let decoder = JSONDecoder()
            let lookupResponse = try decoder.decode(iTunesLookupResponse.self, from: data)

            if lookupResponse.resultCount > 0,
               let appInfo = lookupResponse.results.first {
                latestVersion = appInfo.version
                appStoreURL = URL(string: appInfo.trackViewUrl)

                // 比较版本号
                let currentVersion = AppInfo.version
                hasUpdate = isVersion(appInfo.version, newerThan: currentVersion)

                lastCheckTime = Date()
            } else {
                // App 尚未上架 App Store
                latestVersion = nil
                hasUpdate = false
                errorMessage = "App 尚未上架 App Store"
            }
        } catch {
            errorMessage = "检查更新失败: \(error.localizedDescription)"
        }

        isChecking = false
    }

    // MARK: - 版本比较

    /// 比较两个版本号，判断 version1 是否比 version2 更新
    private func isVersion(_ version1: String, newerThan version2: String) -> Bool {
        let v1Components = version1.split(separator: ".").compactMap { Int($0) }
        let v2Components = version2.split(separator: ".").compactMap { Int($0) }

        // 补齐版本号位数
        let maxCount = max(v1Components.count, v2Components.count)
        var v1 = v1Components
        var v2 = v2Components

        while v1.count < maxCount { v1.append(0) }
        while v2.count < maxCount { v2.append(0) }

        // 逐位比较
        for i in 0..<maxCount {
            if v1[i] > v2[i] {
                return true
            } else if v1[i] < v2[i] {
                return false
            }
        }

        return false
    }

    // MARK: - 打开 App Store

    /// 打开 App Store 页面
    func openAppStore() {
        // 如果有检测到的 URL，使用它
        if let url = appStoreURL {
            UIApplication.shared.open(url)
            return
        }

        // 否则使用 App ID 构建 URL（需要在上架后填入真实 App ID）
        // 格式: https://apps.apple.com/cn/app/idXXXXXXXXXX
        // 目前使用通用搜索链接
        let bundleID = AppInfo.bundleID
        if let searchURL = URL(string: "https://apps.apple.com/cn/app/\(bundleID)") {
            UIApplication.shared.open(searchURL)
        }
    }
}
