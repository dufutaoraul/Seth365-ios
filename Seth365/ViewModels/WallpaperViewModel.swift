//
//  WallpaperViewModel.swift
//  Seth365
//
//  壁纸视图模型
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// 壁纸视图模型
class WallpaperViewModel: ObservableObject {
    /// 当前日期
    let date: Date

    /// 所有壁纸
    @Published var allWallpapers: [Wallpaper] = []

    /// 筛选后的壁纸
    @Published var filteredWallpapers: [Wallpaper] = []

    /// 已加载的图片缓存
    @Published var loadedImages: [String: UIImage] = [:]

    /// 加载状态
    @Published var loadingStates: [String: Bool] = [:]

    /// 语言筛选
    @Published var selectedLanguage: WallpaperLanguage? = nil {
        didSet { applyFilter() }
    }

    /// 方向筛选
    @Published var selectedOrientation: WallpaperOrientation? = nil {
        didSet { applyFilter() }
    }

    /// 错误信息
    @Published var errorMessage: String?

    init(date: Date) {
        self.date = date
        loadWallpapers()
    }

    /// 加载壁纸列表
    private func loadWallpapers() {
        allWallpapers = Wallpaper.allWallpapers(for: date)
        applyFilter()
    }

    /// 应用筛选
    private func applyFilter() {
        filteredWallpapers = Wallpaper.filteredWallpapers(
            for: date,
            language: selectedLanguage,
            orientation: selectedOrientation
        )
    }

    /// 获取壁纸图片
    /// - Parameter wallpaper: 壁纸模型
    /// - Returns: UIImage（如果已加载）
    func getImage(for wallpaper: Wallpaper) -> UIImage? {
        return loadedImages[wallpaper.cacheKey]
    }

    /// 检查是否正在加载
    func isLoading(_ wallpaper: Wallpaper) -> Bool {
        return loadingStates[wallpaper.cacheKey] == true
    }

    /// 加载壁纸图片
    /// - Parameter wallpaper: 壁纸模型
    func loadImage(for wallpaper: Wallpaper) async {
        let key = wallpaper.cacheKey

        // 已经加载过或正在加载
        guard loadedImages[key] == nil, loadingStates[key] != true else {
            print("🖼️ 跳过加载 \(key): 已加载=\(loadedImages[key] != nil) 正在加载=\(loadingStates[key] == true)")
            return
        }

        loadingStates[key] = true
        print("🖼️ 开始加载: \(key)")

        do {
            let image = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
            print("🖼️ 加载成功: \(key) 尺寸=\(image.size)")

            // 如果是横版，需要旋转
            let finalImage: UIImage
            if wallpaper.orientation.needsRotation {
                finalImage = image.rotated(by: .pi / 2) ?? image
            } else {
                finalImage = image
            }

            loadedImages[key] = finalImage
            loadingStates[key] = false
        } catch {
            loadingStates[key] = false
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
    }

    /// 加载所有壁纸图片
    func loadAllImages() async {
        for wallpaper in filteredWallpapers {
            await loadImage(for: wallpaper)
        }
    }

    /// 获取日期显示文本
    var dateDisplayText: String {
        DateUtils.formatMonthDay(date)
    }

    /// 重置筛选
    func resetFilter() {
        selectedLanguage = nil
        selectedOrientation = nil
    }
}

// MARK: - UIImage 旋转扩展

extension UIImage {
    /// 旋转图片
    /// - Parameter radians: 旋转角度（弧度）
    /// - Returns: 旋转后的图片
    func rotated(by radians: CGFloat) -> UIImage? {
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        draw(in: CGRect(
            x: -size.width / 2,
            y: -size.height / 2,
            width: size.width,
            height: size.height
        ))

        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return rotatedImage
    }
}
