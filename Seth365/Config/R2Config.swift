//
//  R2Config.swift
//  Seth365
//
//  Cloudflare R2 云存储配置
//

import Foundation

/// Cloudflare R2 云存储配置
enum R2Config {
    /// R2 公开访问的基础 URL
    static let baseURL = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev"

    /// 壁纸存储路径前缀
    static let wallpaperPath = "wallpapers"

    /// 构建壁纸完整 URL
    /// - Parameters:
    ///   - year: 年份 (如 2025, 2026)
    ///   - month: 月份 (1-12)
    ///   - fileName: 文件名，如 "25.12.21.CS1.png", "26.1.15.EH2.png"
    /// - Returns: 完整的壁纸 URL
    /// 统一格式: /wallpapers/{年后两位}/{月两位数}/{文件名}
    static func wallpaperURL(year: Int, month: Int, fileName: String) -> URL? {
        let yearFolder = year % 100  // 25 或 26
        let monthStr = String(format: "%02d", month)  // 01-12
        let urlString = "\(baseURL)/\(wallpaperPath)/\(yearFolder)/\(monthStr)/\(fileName)"
        return URL(string: urlString)
    }
}
