//
//  Constants.swift
//  Seth365
//
//  全局常量定义
//

import SwiftUI

/// 全局常量
enum Constants {
    /// App 相关常量
    enum App {
        static let name = "Seth365"
        static let year = 2026
        static let wallpapersPerDay = 8
    }

    /// 缓存相关常量
    enum Cache {
        static let memoryLimit = 50  // 内存缓存图片数量限制
        static let diskLimitMB = 500 // 磁盘缓存大小限制（MB）
        static let expirationDays = 30 // 缓存过期天数
    }

    /// UI 相关常量
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardSpacing: CGFloat = 12
        static let padding: CGFloat = 16
        static let calendarDaySize: CGFloat = 40
        static let wallpaperCardHeight: CGFloat = 200
    }

    /// 颜色
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let locked = Color.gray.opacity(0.5)
        static let unlocked = Color.primary
        static let today = Color.orange
    }
}
