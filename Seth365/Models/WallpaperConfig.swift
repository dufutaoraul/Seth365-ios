//
//  WallpaperConfig.swift
//  Seth365
//
//  壁纸配置模型 - 从 R2 获取的壁纸同步配置
//

import Foundation

/// 壁纸配置（从 R2 wallpaper-config.json 获取）
struct WallpaperConfig: Codable {
    /// 壁纸版本号（新增壁纸时 +1）
    let version: Int

    /// 最后更新日期
    let lastUpdated: String

    /// 壁纸起始日期（正式上线日）
    let startDate: String

    /// 壁纸结束日期（R2 上已上传的最后日期）
    let endDate: String

    /// 总壁纸数量（可选，用于显示进度）
    let totalCount: Int?

    // MARK: - 计算属性

    /// 解析起始日期
    var startDateParsed: Date? {
        Self.dateFormatter.date(from: startDate)
    }

    /// 解析结束日期
    var endDateParsed: Date? {
        Self.dateFormatter.date(from: endDate)
    }

    /// 日期格式化器
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }()

    // MARK: - 默认配置（网络不可用时使用）

    /// 默认配置（硬编码，作为后备）
    static let fallback = WallpaperConfig(
        version: 1,
        lastUpdated: "2025-12-21",
        startDate: "2025-12-21",
        endDate: "2026-02-28",
        totalCount: 560
    )
}

// MARK: - 配置获取服务

/// 壁纸配置服务
class WallpaperConfigService {
    /// 共享实例
    static let shared = WallpaperConfigService()

    /// iOS 配置文件 URL
    private let configURL = "https://pub-810d6e0711de44d396071ecfc5ae9c2a.r2.dev/ios/wallpaper-config.json"

    private init() {}

    /// 从 R2 获取壁纸配置
    /// - Returns: 壁纸配置，失败时返回默认配置
    func fetchConfig() async -> WallpaperConfig {
        // 添加时间戳绕过 CDN 缓存
        let timestamp = Int(Date().timeIntervalSince1970)
        guard let url = URL(string: "\(configURL)?t=\(timestamp)") else {
            appLog(.error, "无效的配置 URL", source: "ConfigService")
            return .fallback
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // 检查 HTTP 状态码
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    appLog(.warning, "配置请求返回 \(httpResponse.statusCode)，使用默认配置", source: "ConfigService")
                    return .fallback
                }
            }

            // 解析 JSON
            let config = try JSONDecoder().decode(WallpaperConfig.self, from: data)
            appLog(.info, "获取配置成功: version=\(config.version), range=\(config.startDate)~\(config.endDate)", source: "ConfigService")
            return config

        } catch {
            appLog(.warning, "获取配置失败: \(error.localizedDescription)，使用默认配置", source: "ConfigService")
            return .fallback
        }
    }
}
