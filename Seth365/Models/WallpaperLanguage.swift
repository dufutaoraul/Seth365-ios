//
//  WallpaperLanguage.swift
//  Seth365
//
//  壁纸语言枚举
//

import Foundation

/// 壁纸语言类型
enum WallpaperLanguage: String, CaseIterable, Identifiable, Codable {
    case chinese = "C"   // 中文
    case english = "E"   // 英文

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }

    /// 本地化显示名称
    var localizedDisplayName: String {
        switch self {
        case .chinese: return "language.chinese".localized
        case .english: return "language.english".localized
        }
    }

    /// 简短显示名称
    var shortName: String {
        switch self {
        case .chinese: return "中"
        case .english: return "英"
        }
    }
}
