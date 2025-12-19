//
//  WallpaperOrientation.swift
//  Seth365
//
//  壁纸方向枚举
//

import Foundation

/// 壁纸方向类型
enum WallpaperOrientation: String, CaseIterable, Identifiable, Codable {
    case portrait = "S"    // 竖版 (Standing)
    case landscape = "H"   // 横版 (Horizontal)

    var id: String { rawValue }

    /// 显示名称
    var displayName: String {
        switch self {
        case .portrait: return "竖版"
        case .landscape: return "横版"
        }
    }

    /// 本地化显示名称
    var localizedDisplayName: String {
        switch self {
        case .portrait: return "orientation.portrait".localized
        case .landscape: return "orientation.landscape".localized
        }
    }

    /// 简短显示名称
    var shortName: String {
        switch self {
        case .portrait: return "竖"
        case .landscape: return "横"
        }
    }

    /// 是否需要旋转（横版在手机上需要旋转90度）
    var needsRotation: Bool {
        self == .landscape
    }
}
