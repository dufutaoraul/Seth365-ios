//
//  WallpaperDisplayMode.swift
//  Seth365
//
//  壁纸显示模式
//

import Foundation

/// 壁纸显示模式
enum WallpaperDisplayMode: String, CaseIterable, Identifiable {
    case fitBlack = "fitBlack"          // 适配（黑边）
    case fitWhite = "fitWhite"          // 适配（白边）
    case stretch = "stretch"            // 拉伸
    case cropCenter = "cropCenter"      // 裁切（居中）
    case cropTop = "cropTop"            // 裁切（顶部）
    case blurBackground = "blurBackground"  // 模糊背景

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fitBlack: return "适配（黑边）"
        case .fitWhite: return "适配（白边）"
        case .stretch: return "拉伸"
        case .cropCenter: return "裁切（居中）"
        case .cropTop: return "裁切（顶部）"
        case .blurBackground: return "模糊背景"
        }
    }

    var description: String {
        switch self {
        case .fitBlack: return "完整显示图片，空白处用黑色填充"
        case .fitWhite: return "完整显示图片，空白处用白色填充"
        case .stretch: return "拉伸图片铺满全屏，可能变形"
        case .cropCenter: return "铺满全屏，居中裁切超出部分"
        case .cropTop: return "铺满全屏，保留顶部内容"
        case .blurBackground: return "完整显示图片，用模糊图作为背景"
        }
    }
}
