//
//  PosterViewModel.swift
//  Seth365
//
//  海报生成视图模型
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// 海报生成视图模型
class PosterViewModel: ObservableObject {
    /// 原始壁纸
    @Published var originalWallpaper: UIImage?

    /// 用户二维码
    @Published var userQRCode: UIImage?

    /// 检测到的二维码位置
    @Published var detectedQRPosition: CGRect?

    /// 调整后的二维码位置
    @Published var adjustedQRPosition: CGRect = .zero

    /// 调整后的二维码大小
    @Published var adjustedQRSize: CGSize = CGSize(width: 100, height: 100)

    /// 检测到的二维码原始大小（用于缩放基准）
    var detectedQRSize: CGSize = CGSize(width: 150, height: 150)

    /// 生成的海报
    @Published var generatedPoster: UIImage?

    /// 是否正在检测
    @Published var isDetecting = false

    /// 是否正在生成
    @Published var isGenerating = false

    /// 错误信息
    @Published var errorMessage: String?

    // MARK: - 初始化

    init() {
        // 加载用户保存的二维码
        userQRCode = QRCodeStorage.shared.getUserQRCode()
    }

    // MARK: - 设置原始壁纸

    /// 设置原始壁纸并检测二维码
    func setWallpaper(_ image: UIImage) async {
        await MainActor.run {
            originalWallpaper = image
            isDetecting = true
        }

        // 检测二维码位置
        let position = await QRCodeDetectionService.shared.detectPrimaryQRCode(in: image)

        await MainActor.run {
            isDetecting = false

            if let position = position {
                detectedQRPosition = position.rect
                adjustedQRPosition = position.rect
                adjustedQRSize = position.rect.size
                detectedQRSize = position.rect.size
            } else {
                // 如果没检测到，使用默认位置（右下角）
                let defaultSize = CGSize(width: 150, height: 150)
                let defaultPosition = CGRect(
                    x: image.size.width - defaultSize.width - 50,
                    y: image.size.height - defaultSize.height - 50,
                    width: defaultSize.width,
                    height: defaultSize.height
                )
                detectedQRPosition = nil
                adjustedQRPosition = defaultPosition
                adjustedQRSize = defaultSize
                detectedQRSize = defaultSize
            }
        }
    }

    // MARK: - 设置用户二维码

    /// 设置用户二维码
    func setUserQRCode(_ image: UIImage) {
        userQRCode = image
        QRCodeStorage.shared.saveUserQRCode(image)
    }

    // MARK: - 更新位置和大小

    /// 更新二维码位置
    func updateQRPosition(_ position: CGRect) {
        adjustedQRPosition = position
    }

    /// 更新二维码大小
    func updateQRSize(_ size: CGSize) {
        adjustedQRSize = size
        adjustedQRPosition.size = size
    }

    // MARK: - 生成海报

    /// 生成海报
    func generatePoster() -> UIImage? {
        guard let wallpaper = originalWallpaper,
              let qrCode = userQRCode else {
            errorMessage = "请先选择壁纸和二维码"
            return nil
        }

        isGenerating = true
        defer { isGenerating = false }

        // 创建画布
        let size = wallpaper.size
        UIGraphicsBeginImageContextWithOptions(size, false, wallpaper.scale)
        defer { UIGraphicsEndImageContext() }

        // 绘制原始壁纸
        wallpaper.draw(at: .zero)

        // 绘制用户二维码
        qrCode.draw(in: adjustedQRPosition)

        // 获取结果
        let result = UIGraphicsGetImageFromCurrentImageContext()
        generatedPoster = result

        return result
    }

    // MARK: - 检查状态

    /// 是否可以生成海报
    var canGenerate: Bool {
        originalWallpaper != nil && userQRCode != nil
    }

    /// 是否已检测到二维码
    var hasDetectedQRCode: Bool {
        detectedQRPosition != nil
    }
}
