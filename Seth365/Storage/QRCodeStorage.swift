//
//  QRCodeStorage.swift
//  Seth365
//
//  用户二维码存储管理
//

import Foundation
import UIKit

/// 用户二维码存储管理
class QRCodeStorage {
    /// 共享实例
    static let shared = QRCodeStorage()

    /// 存储目录
    private let storageDirectory: URL

    /// 当前二维码文件名
    private let currentQRCodeFileName = "user_qrcode.png"

    private init() {
        // 创建存储目录
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageDirectory = documentsDir.appendingPathComponent("UserQRCodes", isDirectory: true)

        // 确保目录存在
        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    /// 当前用户二维码路径
    private var currentQRCodeURL: URL {
        storageDirectory.appendingPathComponent(currentQRCodeFileName)
    }

    /// 保存用户二维码
    /// - Parameter image: 二维码图片
    /// - Returns: 是否保存成功
    @discardableResult
    func saveUserQRCode(_ image: UIImage) -> Bool {
        guard let data = image.pngData() else { return false }

        do {
            try data.write(to: currentQRCodeURL)
            return true
        } catch {
            print("保存二维码失败: \(error)")
            return false
        }
    }

    /// 获取用户二维码
    /// - Returns: 用户保存的二维码图片
    func getUserQRCode() -> UIImage? {
        guard FileManager.default.fileExists(atPath: currentQRCodeURL.path) else {
            return nil
        }

        return UIImage(contentsOfFile: currentQRCodeURL.path)
    }

    /// 检查是否已保存用户二维码
    var hasUserQRCode: Bool {
        FileManager.default.fileExists(atPath: currentQRCodeURL.path)
    }

    /// 删除用户二维码
    func deleteUserQRCode() {
        try? FileManager.default.removeItem(at: currentQRCodeURL)
    }
}
