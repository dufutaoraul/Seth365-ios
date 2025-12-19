//
//  QRCodeDetectionService.swift
//  Seth365
//
//  二维码检测服务
//

import Foundation
import UIKit
import Vision

/// 二维码位置信息
struct QRCodePosition {
    let rect: CGRect           // 在图片中的位置（像素坐标）
    let content: String?       // 二维码内容
    let confidence: Float      // 检测置信度
}

/// 二维码检测服务
class QRCodeDetectionService {
    /// 共享实例
    static let shared = QRCodeDetectionService()

    private init() {}

    /// 检测图片中的二维码
    /// - Parameter image: 要检测的图片
    /// - Returns: 检测到的二维码位置列表
    func detectQRCodes(in image: UIImage) async -> [QRCodePosition] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            // 使用 DispatchQueue 避免线程问题
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectBarcodesRequest()
                request.symbologies = [.qr]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([request])

                    guard let results = request.results as? [VNBarcodeObservation] else {
                        continuation.resume(returning: [])
                        return
                    }

                    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                    var positions: [QRCodePosition] = []

                    for result in results {
                        // Vision 返回的是归一化坐标（0-1），需要转换为像素坐标
                        // 注意：Vision 的 Y 轴是从下往上的，需要翻转
                        let boundingBox = result.boundingBox
                        let rect = CGRect(
                            x: boundingBox.origin.x * imageSize.width,
                            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
                            width: boundingBox.width * imageSize.width,
                            height: boundingBox.height * imageSize.height
                        )

                        let position = QRCodePosition(
                            rect: rect,
                            content: result.payloadStringValue,
                            confidence: result.confidence
                        )
                        positions.append(position)
                    }

                    continuation.resume(returning: positions)
                } catch {
                    print("二维码检测失败: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    /// 检测图片中最可能的二维码位置
    /// - Parameter image: 要检测的图片
    /// - Returns: 最可能的二维码位置（优先右下角）
    func detectPrimaryQRCode(in image: UIImage) async -> QRCodePosition? {
        let positions = await detectQRCodes(in: image)

        guard !positions.isEmpty else { return nil }

        // 如果只有一个，直接返回
        if positions.count == 1 {
            return positions.first
        }

        // 多个时，优先选择右下角的
        guard let cgImage = image.cgImage else { return positions.first }
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        // 按照距离右下角的距离排序
        let sorted = positions.sorted { pos1, pos2 in
            let center1 = CGPoint(x: pos1.rect.midX, y: pos1.rect.midY)
            let center2 = CGPoint(x: pos2.rect.midX, y: pos2.rect.midY)

            // 右下角坐标
            let bottomRight = CGPoint(x: imageSize.width, y: imageSize.height)

            let dist1 = hypot(center1.x - bottomRight.x, center1.y - bottomRight.y)
            let dist2 = hypot(center2.x - bottomRight.x, center2.y - bottomRight.y)

            return dist1 < dist2
        }

        return sorted.first
    }
}
