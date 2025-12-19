//
//  GetWallpaperIntent.swift
//  Seth365
//
//  获取壁纸的 App Intent（用于快捷指令）
//

import AppIntents
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 语言选项（用于 Shortcuts）
enum LanguageOption: String, AppEnum {
    case chinese = "chinese"
    case english = "english"
    case preferred = "preferred"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "语言"
    }

    static var caseDisplayRepresentations: [LanguageOption: DisplayRepresentation] {
        [
            .chinese: "中文",
            .english: "English",
            .preferred: "使用偏好设置"
        ]
    }

    var toWallpaperLanguage: WallpaperLanguage? {
        switch self {
        case .chinese: return .chinese
        case .english: return .english
        case .preferred: return nil
        }
    }
}

/// 方向选项（用于 Shortcuts）
enum OrientationOption: String, AppEnum {
    case portrait = "portrait"
    case landscape = "landscape"
    case preferred = "preferred"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "方向"
    }

    static var caseDisplayRepresentations: [OrientationOption: DisplayRepresentation] {
        [
            .portrait: "竖版",
            .landscape: "横版",
            .preferred: "使用偏好设置"
        ]
    }

    var toWallpaperOrientation: WallpaperOrientation? {
        switch self {
        case .portrait: return .portrait
        case .landscape: return .landscape
        case .preferred: return nil
        }
    }
}

/// 日期范围选项（用于 Shortcuts）
enum DateRangeOption: String, AppEnum {
    case preferred = "preferred"            // 使用偏好设置
    case today = "today"                    // 仅今天
    case lastThreeDays = "lastThreeDays"    // 最近3天
    case lastSevenDays = "lastSevenDays"    // 最近7天
    case allUnlocked = "allUnlocked"        // 所有已解锁

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "日期范围"
    }

    static var caseDisplayRepresentations: [DateRangeOption: DisplayRepresentation] {
        [
            .preferred: DisplayRepresentation(title: "使用偏好设置", subtitle: "使用App设置中的默认范围"),
            .today: DisplayRepresentation(title: "仅今天", subtitle: "只从今天的8张壁纸中选择"),
            .lastThreeDays: DisplayRepresentation(title: "最近3天", subtitle: "从最近3天的壁纸中随机选择"),
            .lastSevenDays: DisplayRepresentation(title: "最近7天", subtitle: "从最近7天的壁纸中随机选择"),
            .allUnlocked: DisplayRepresentation(title: "所有已解锁", subtitle: "从所有已解锁的壁纸中随机选择")
        ]
    }

    /// 转换为实际的日期范围
    func toActualRange(preferredRange: SwitchDateRange? = nil) -> DateRangeOption {
        if self == .preferred {
            // 从传入的偏好设置获取
            if let userRange = preferredRange {
                switch userRange {
                case .today: return .today
                case .lastThreeDays: return .lastThreeDays
                case .lastSevenDays: return .lastSevenDays
                case .allUnlocked: return .allUnlocked
                case .custom: return .allUnlocked // 自定义模式在快捷指令中使用全部已解锁
                }
            }
            return .today // 默认值
        }
        return self
    }
}

/// 获取今日壁纸的 Intent
struct GetTodayWallpaperIntent: AppIntent {
    static var title: LocalizedStringResource = "获取 Seth365 壁纸"
    static var description = IntentDescription("获取 Seth365 壁纸，可配合系统「设置壁纸」动作实现自动换壁纸")

    /// 日期范围参数
    @Parameter(title: "日期范围", default: .preferred)
    var dateRange: DateRangeOption

    /// 语言参数
    @Parameter(title: "语言", default: .preferred)
    var language: LanguageOption

    /// 方向参数
    @Parameter(title: "方向", default: .preferred)
    var orientation: OrientationOption

    /// 是否随机选择
    @Parameter(title: "随机选择序号", default: true)
    var randomSelect: Bool

    /// 执行 Intent
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let logSource = "Shortcuts"
        appLog(.info, "快捷指令开始执行: 获取壁纸", source: logSource)
        appLog(.debug, "参数: 日期范围=\(dateRange.rawValue), 语言=\(language.rawValue), 方向=\(orientation.rawValue), 随机=\(randomSelect)", source: logSource)

        // 在主线程获取用户偏好设置
        let (preferredLang, preferredOrient, preferredRange, displayMode) = await MainActor.run {
            (
                UserDefaultsManager.shared.preferredLanguage,
                UserDefaultsManager.shared.preferredOrientation,
                UserDefaultsManager.shared.switchDateRange,
                UserDefaultsManager.shared.displayMode
            )
        }
        appLog(.debug, "用户偏好: 语言=\(preferredLang?.rawValue ?? "全部"), 方向=\(preferredOrient?.rawValue ?? "全部"), 范围=\(preferredRange.rawValue)", source: logSource)

        // 根据日期范围获取可选日期（转换为实际范围）
        let actualRange = dateRange.toActualRange(preferredRange: preferredRange)
        let selectedDate = getRandomDate(for: actualRange)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        appLog(.debug, "选择日期: \(dateFormatter.string(from: selectedDate))", source: logSource)

        // 确定语言（nil 表示全部，随机选择）
        let finalLanguage: WallpaperLanguage
        if let lang = language.toWallpaperLanguage {
            finalLanguage = lang
        } else if let userLang = preferredLang {
            finalLanguage = userLang
        } else {
            // 用户偏好也是"全部"，随机选择
            finalLanguage = Bool.random() ? .chinese : .english
        }

        // 确定方向（nil 表示全部，随机选择）
        let finalOrientation: WallpaperOrientation
        if let orient = orientation.toWallpaperOrientation {
            finalOrientation = orient
        } else if let userOrient = preferredOrient {
            finalOrientation = userOrient
        } else {
            // 用户偏好也是"全部"，随机选择
            finalOrientation = Bool.random() ? .portrait : .landscape
        }

        // 确定序号
        let index: Int
        if randomSelect {
            index = Int.random(in: 1...2)
        } else {
            index = 1
        }

        // 创建壁纸对象
        let wallpaper = Wallpaper(
            date: selectedDate,
            language: finalLanguage,
            orientation: finalOrientation,
            index: index
        )
        appLog(.info, "选择壁纸: \(wallpaper.fileName)", source: logSource)
        appLog(.debug, "Bundle路径: \(wallpaper.bundleRelativePath), 是否内置: \(wallpaper.isInBundle)", source: logSource)

        // 检查是否已解锁
        guard wallpaper.isUnlocked() else {
            appLog(.error, "壁纸未解锁: \(wallpaper.fileName)", source: logSource)
            throw GetWallpaperError.notUnlocked
        }

        // 下载/加载图片
        let image: UIImage
        do {
            image = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
            appLog(.success, "图片加载成功: \(wallpaper.fileName)", source: logSource)
        } catch {
            appLog(.error, "图片加载失败: \(error.localizedDescription)", source: logSource)
            throw GetWallpaperError.downloadFailed
        }

        // 处理横版旋转
        var processedImage: UIImage
        if wallpaper.orientation.needsRotation {
            processedImage = image.rotated(by: .pi / 2) ?? image
            appLog(.debug, "已旋转横版壁纸", source: logSource)
        } else {
            processedImage = image
        }

        // 应用显示模式
        let screenSize = await MainActor.run { ImageProcessingService.screenSize }
        processedImage = ImageProcessingService.shared.processImage(processedImage, mode: displayMode, targetSize: screenSize)
        appLog(.debug, "已处理显示模式: \(displayMode.displayName)", source: logSource)

        // 转换为 IntentFile
        guard let imageData = processedImage.pngData() else {
            appLog(.error, "图片数据转换失败", source: logSource)
            throw GetWallpaperError.imageConversionFailed
        }

        let file = IntentFile(data: imageData, filename: wallpaper.fileName, type: .png)
        appLog(.success, "快捷指令执行完成, 返回文件: \(wallpaper.fileName) (\(imageData.count / 1024)KB)", source: logSource)

        return .result(value: file)
    }

    /// 根据日期范围获取随机日期
    private func getRandomDate(for range: DateRangeOption) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch range {
        case .preferred:
            // 不应该到达这里，因为调用前已经转换过了
            return today

        case .today:
            return today

        case .lastThreeDays:
            let daysBack = Int.random(in: 0...2)
            return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today

        case .lastSevenDays:
            let daysBack = Int.random(in: 0...6)
            return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today

        case .allUnlocked:
            // 从2025年12月1日到今天随机选择
            let startDate = DateUtils.date(year: 2025, month: 12, day: 1) ?? today
            let startDay = calendar.startOfDay(for: startDate)

            if let daysBetween = calendar.dateComponents([.day], from: startDay, to: today).day,
               daysBetween > 0 {
                let randomDays = Int.random(in: 0...daysBetween)
                return calendar.date(byAdding: .day, value: -randomDays, to: today) ?? today
            }
            return today
        }
    }
}

/// 获取壁纸错误
enum GetWallpaperError: Error, CustomLocalizedStringResourceConvertible {
    case notUnlocked
    case downloadFailed
    case imageConversionFailed
    case saveToPhotosFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notUnlocked:
            return "该日期的壁纸尚未解锁"
        case .downloadFailed:
            return "下载壁纸失败"
        case .imageConversionFailed:
            return "图片转换失败"
        case .saveToPhotosFailed:
            return "保存到相册失败，请检查权限"
        }
    }
}

// MARK: - 保存壁纸到相册 Intent

import Photos

/// 保存壁纸到相册的 Intent（自动化时最实用）
struct SaveWallpaperToPhotosIntent: AppIntent {
    static var title: LocalizedStringResource = "保存 Seth365 壁纸到相册"
    static var description = IntentDescription("获取壁纸并直接保存到相册，适合自动化使用")

    /// 日期范围参数
    @Parameter(title: "日期范围", default: .preferred)
    var dateRange: DateRangeOption

    /// 语言参数
    @Parameter(title: "语言", default: .preferred)
    var language: LanguageOption

    /// 方向参数
    @Parameter(title: "方向", default: .preferred)
    var orientation: OrientationOption

    /// 是否随机选择
    @Parameter(title: "随机选择序号", default: true)
    var randomSelect: Bool

    /// 执行 Intent
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 在主线程获取用户偏好设置
        let (preferredLang, preferredOrient, preferredRange, displayMode) = await MainActor.run {
            (
                UserDefaultsManager.shared.preferredLanguage,
                UserDefaultsManager.shared.preferredOrientation,
                UserDefaultsManager.shared.switchDateRange,
                UserDefaultsManager.shared.displayMode
            )
        }

        // 根据日期范围获取可选日期（转换为实际范围）
        let actualRange = dateRange.toActualRange(preferredRange: preferredRange)
        let selectedDate = getRandomDate(for: actualRange)

        // 确定语言（nil 表示全部，随机选择）
        let finalLanguage: WallpaperLanguage
        if let lang = language.toWallpaperLanguage {
            finalLanguage = lang
        } else if let userLang = preferredLang {
            finalLanguage = userLang
        } else {
            // 用户偏好也是"全部"，随机选择
            finalLanguage = Bool.random() ? .chinese : .english
        }

        // 确定方向（nil 表示全部，随机选择）
        let finalOrientation: WallpaperOrientation
        if let orient = orientation.toWallpaperOrientation {
            finalOrientation = orient
        } else if let userOrient = preferredOrient {
            finalOrientation = userOrient
        } else {
            // 用户偏好也是"全部"，随机选择
            finalOrientation = Bool.random() ? .portrait : .landscape
        }

        // 确定序号
        let index: Int
        if randomSelect {
            index = Int.random(in: 1...2)
        } else {
            index = 1
        }

        // 创建壁纸对象
        let wallpaper = Wallpaper(
            date: selectedDate,
            language: finalLanguage,
            orientation: finalOrientation,
            index: index
        )

        // 检查是否已解锁
        guard wallpaper.isUnlocked() else {
            throw GetWallpaperError.notUnlocked
        }

        // 下载图片
        let image = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)

        // 处理横版旋转
        var processedImage: UIImage
        if wallpaper.orientation.needsRotation {
            processedImage = image.rotated(by: .pi / 2) ?? image
        } else {
            processedImage = image
        }

        // 应用显示模式
        let screenSize = await MainActor.run { ImageProcessingService.screenSize }
        processedImage = ImageProcessingService.shared.processImage(processedImage, mode: displayMode, targetSize: screenSize)

        // 保存到相册
        let saved = await saveToPhotoLibrary(processedImage)

        if saved {
            return .result(dialog: "壁纸已保存到相册 ✓\n\(wallpaper.displayName)")
        } else {
            throw GetWallpaperError.saveToPhotosFailed
        }
    }

    /// 保存图片到相册
    private func saveToPhotoLibrary(_ image: UIImage) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {
                    continuation.resume(returning: false)
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetCreationRequest.forAsset().addResource(
                        with: .photo,
                        data: image.pngData() ?? Data(),
                        options: nil
                    )
                }) { success, _ in
                    continuation.resume(returning: success)
                }
            }
        }
    }

    /// 根据日期范围获取随机日期
    private func getRandomDate(for range: DateRangeOption) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch range {
        case .preferred:
            // 不应该到达这里，因为调用前已经转换过了
            return today

        case .today:
            return today

        case .lastThreeDays:
            let daysBack = Int.random(in: 0...2)
            return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today

        case .lastSevenDays:
            let daysBack = Int.random(in: 0...6)
            return calendar.date(byAdding: .day, value: -daysBack, to: today) ?? today

        case .allUnlocked:
            let startDate = DateUtils.date(year: 2025, month: 12, day: 1) ?? today
            let startDay = calendar.startOfDay(for: startDate)

            if let daysBetween = calendar.dateComponents([.day], from: startDay, to: today).day,
               daysBetween > 0 {
                let randomDays = Int.random(in: 0...daysBetween)
                return calendar.date(byAdding: .day, value: -randomDays, to: today) ?? today
            }
            return today
        }
    }
}
