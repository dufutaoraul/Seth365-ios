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
    ///   - fileName: 文件名，如 "25.12.1.CS1.png" 或 "12.1.CS1.png"
    /// - Returns: 完整的壁纸 URL
    static func wallpaperURL(year: Int, month: Int, fileName: String) -> URL? {
        if year == 2025 {
            // 2025年测试期间，路径包含年份文件夹
            // 格式: /wallpapers/25/12/25.12.15.CS1.png
            let yearFolder = year % 100  // 25
            let urlString = "\(baseURL)/\(wallpaperPath)/\(yearFolder)/\(month)/\(fileName)"
            return URL(string: urlString)
        } else {
            // 2026年正式版，路径只有月份
            // 格式: /wallpapers/12/12.15.CS1.png
            let urlString = "\(baseURL)/\(wallpaperPath)/\(month)/\(fileName)"
            return URL(string: urlString)
        }
    }
}
