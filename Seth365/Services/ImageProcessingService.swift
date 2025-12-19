//
//  ImageProcessingService.swift
//  Seth365
//
//  图片处理服务（显示模式处理）
//

import UIKit

/// 图片处理服务
class ImageProcessingService {
    static let shared = ImageProcessingService()
    private init() {}

    /// 根据显示模式处理图片
    /// - Parameters:
    ///   - image: 原始图片
    ///   - mode: 显示模式
    ///   - targetSize: 目标尺寸（屏幕尺寸）
    /// - Returns: 处理后的图片
    func processImage(_ image: UIImage, mode: WallpaperDisplayMode, targetSize: CGSize) -> UIImage {
        switch mode {
        case .fitBlack:
            return fitImage(image, targetSize: targetSize, backgroundColor: .black)
        case .fitWhite:
            return fitImage(image, targetSize: targetSize, backgroundColor: .white)
        case .stretch:
            return stretchImage(image, targetSize: targetSize)
        case .cropCenter:
            return cropImage(image, targetSize: targetSize, alignment: .center)
        case .cropTop:
            return cropImage(image, targetSize: targetSize, alignment: .top)
        case .blurBackground:
            return blurBackgroundImage(image, targetSize: targetSize)
        }
    }

    // MARK: - 适配模式（黑边/白边）

    private func fitImage(_ image: UIImage, targetSize: CGSize, backgroundColor: UIColor) -> UIImage {
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)

        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)
        defer { UIGraphicsEndImageContext() }

        backgroundColor.setFill()
        UIRectFill(CGRect(origin: .zero, size: targetSize))

        image.draw(in: CGRect(origin: origin, size: scaledSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - 拉伸模式

    private func stretchImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: targetSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - 裁切模式

    private func cropImage(_ image: UIImage, targetSize: CGSize, alignment: CropAlignment) -> UIImage {
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = max(widthRatio, heightRatio)

        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)

        let origin: CGPoint
        switch alignment {
        case .center:
            origin = CGPoint(
                x: (targetSize.width - scaledSize.width) / 2,
                y: (targetSize.height - scaledSize.height) / 2
            )
        case .top:
            origin = CGPoint(
                x: (targetSize.width - scaledSize.width) / 2,
                y: 0
            )
        }

        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: origin, size: scaledSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private enum CropAlignment {
        case center
        case top
    }

    // MARK: - 模糊背景模式

    private func blurBackgroundImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        // 1. 创建模糊的背景（放大并模糊）
        let blurredBackground = createBlurredBackground(image, targetSize: targetSize)

        // 2. 计算前景图片的尺寸和位置（适配显示）
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)

        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        // 3. 合成
        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)
        defer { UIGraphicsEndImageContext() }

        // 绘制模糊背景
        blurredBackground.draw(in: CGRect(origin: .zero, size: targetSize))

        // 绘制前景图片
        image.draw(in: CGRect(origin: origin, size: scaledSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private func createBlurredBackground(_ image: UIImage, targetSize: CGSize) -> UIImage {
        // 放大图片以覆盖整个目标区域
        let imageSize = image.size
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let ratio = max(widthRatio, heightRatio) * 1.1 // 稍微放大一点

        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        let origin = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        UIGraphicsBeginImageContextWithOptions(targetSize, true, image.scale)

        image.draw(in: CGRect(origin: origin, size: scaledSize))

        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()

        // 应用模糊效果
        guard let ciImage = CIImage(image: scaledImage) else { return scaledImage }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(30.0, forKey: kCIInputRadiusKey) // 模糊半径

        guard let outputImage = filter?.outputImage else { return scaledImage }

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
            return scaledImage
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// 获取屏幕尺寸
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
}
