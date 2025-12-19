//
//  AppInfo.swift
//  Seth365
//
//  应用信息工具类
//

import Foundation

/// 应用信息工具类
enum AppInfo {
    /// 应用版本号（如 "1.0.0"）
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// 构建号（如 "1"）
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 完整版本字符串（如 "1.0.0 (1)"）
    static var fullVersion: String {
        "\(version) (\(build))"
    }

    /// 应用名称
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "Seth365"
    }

    /// Bundle ID
    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? "com.futuremind2075.Seth365"
    }

    /// 内置壁纸信息
    static var bundledWallpaperInfo: String {
        // 检查各月份的壁纸数量
        var info: [String] = []

        // 2025年12月
        if let path = Bundle.main.resourcePath {
            let dec2025Path = "\(path)/Wallpapers/25/12"
            if let files = try? FileManager.default.contentsOfDirectory(atPath: dec2025Path) {
                let pngCount = files.filter { $0.hasSuffix(".png") }.count
                if pngCount > 0 {
                    info.append("2025.12: \(pngCount)张")
                }
            }

            // 2026年各月
            for month in 1...12 {
                let monthPath = "\(path)/Wallpapers/\(month)"
                if let files = try? FileManager.default.contentsOfDirectory(atPath: monthPath) {
                    let pngCount = files.filter { $0.hasSuffix(".png") }.count
                    if pngCount > 0 {
                        info.append("2026.\(month): \(pngCount)张")
                    }
                }
            }
        }

        return info.isEmpty ? "暂无内置壁纸" : info.joined(separator: ", ")
    }

    /// 内置壁纸总数
    static var totalBundledWallpapers: Int {
        var total = 0

        if let path = Bundle.main.resourcePath {
            // 2025年12月
            let dec2025Path = "\(path)/Wallpapers/25/12"
            if let files = try? FileManager.default.contentsOfDirectory(atPath: dec2025Path) {
                total += files.filter { $0.hasSuffix(".png") }.count
            }

            // 2026年各月
            for month in 1...12 {
                let monthPath = "\(path)/Wallpapers/\(month)"
                if let files = try? FileManager.default.contentsOfDirectory(atPath: monthPath) {
                    total += files.filter { $0.hasSuffix(".png") }.count
                }
            }
        }

        return total
    }
}
