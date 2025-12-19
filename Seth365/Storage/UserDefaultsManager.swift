//
//  UserDefaultsManager.swift
//  Seth365
//
//  用户偏好存储管理
//

import Foundation
import SwiftUI
import Combine

/// 用户偏好存储管理器
class UserDefaultsManager: ObservableObject {
    /// 共享实例
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let preferredLanguage = "preferredLanguage"
        static let preferredOrientation = "preferredOrientation"
        static let hasSeenShortcutsGuide = "hasSeenShortcutsGuide"
        static let lastOpenedDate = "lastOpenedDate"
        static let switchDateRange = "switchDateRange"
        static let switchRandomIndex = "switchRandomIndex"
        static let customSelectedDates = "customSelectedDates"
        static let displayMode = "displayMode"
    }

    // MARK: - 偏好语言

    /// 偏好语言（nil 表示全部）
    @Published var preferredLanguage: WallpaperLanguage? {
        didSet {
            if let language = preferredLanguage {
                defaults.set(language.rawValue, forKey: Keys.preferredLanguage)
            } else {
                defaults.set("all", forKey: Keys.preferredLanguage)
            }
        }
    }

    // MARK: - 偏好方向

    /// 偏好方向（nil 表示全部）
    @Published var preferredOrientation: WallpaperOrientation? {
        didSet {
            if let orientation = preferredOrientation {
                defaults.set(orientation.rawValue, forKey: Keys.preferredOrientation)
            } else {
                defaults.set("all", forKey: Keys.preferredOrientation)
            }
        }
    }

    // MARK: - 是否已看过 Shortcuts 引导

    /// 是否已看过 Shortcuts 引导
    @Published var hasSeenShortcutsGuide: Bool {
        didSet {
            defaults.set(hasSeenShortcutsGuide, forKey: Keys.hasSeenShortcutsGuide)
        }
    }

    // MARK: - 上次打开日期

    /// 上次打开日期
    var lastOpenedDate: Date? {
        get { defaults.object(forKey: Keys.lastOpenedDate) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastOpenedDate) }
    }

    // MARK: - 切换日期范围

    /// 切换壁纸时的日期范围
    @Published var switchDateRange: SwitchDateRange {
        didSet {
            defaults.set(switchDateRange.rawValue, forKey: Keys.switchDateRange)
        }
    }

    // MARK: - 随机选择序号

    /// 切换壁纸时是否随机选择序号
    @Published var switchRandomIndex: Bool {
        didSet {
            defaults.set(switchRandomIndex, forKey: Keys.switchRandomIndex)
        }
    }

    // MARK: - 显示模式

    /// 壁纸显示模式
    @Published var displayMode: WallpaperDisplayMode {
        didSet {
            defaults.set(displayMode.rawValue, forKey: Keys.displayMode)
        }
    }

    // MARK: - 自定义选择的日期

    /// 自定义选择的日期集合
    var customSelectedDates: Set<Date> {
        get {
            guard let data = defaults.data(forKey: Keys.customSelectedDates),
                  let timestamps = try? JSONDecoder().decode([TimeInterval].self, from: data) else {
                return []
            }
            return Set(timestamps.map { Date(timeIntervalSince1970: $0) })
        }
        set {
            let timestamps = newValue.map { $0.timeIntervalSince1970 }
            if let data = try? JSONEncoder().encode(timestamps) {
                defaults.set(data, forKey: Keys.customSelectedDates)
            }
            objectWillChange.send()
        }
    }

    // MARK: - 初始化

    private init() {
        // 加载偏好语言（默认：全部）
        if let savedLanguage = defaults.string(forKey: Keys.preferredLanguage) {
            if savedLanguage == "all" {
                self.preferredLanguage = nil
            } else if let language = WallpaperLanguage(rawValue: savedLanguage) {
                self.preferredLanguage = language
            } else {
                self.preferredLanguage = nil  // 默认全部
            }
        } else {
            self.preferredLanguage = nil  // 默认全部
        }

        // 加载偏好方向（默认：全部）
        if let savedOrientation = defaults.string(forKey: Keys.preferredOrientation) {
            if savedOrientation == "all" {
                self.preferredOrientation = nil
            } else if let orientation = WallpaperOrientation(rawValue: savedOrientation) {
                self.preferredOrientation = orientation
            } else {
                self.preferredOrientation = nil  // 默认全部
            }
        } else {
            self.preferredOrientation = nil  // 默认全部
        }

        // 加载是否已看过 Shortcuts 引导
        self.hasSeenShortcutsGuide = defaults.bool(forKey: Keys.hasSeenShortcutsGuide)

        // 加载切换日期范围（默认：仅今天）
        if let savedRange = defaults.string(forKey: Keys.switchDateRange),
           let range = SwitchDateRange(rawValue: savedRange) {
            self.switchDateRange = range
        } else {
            self.switchDateRange = .today
        }

        // 加载是否随机选择序号（默认：是）
        if defaults.object(forKey: Keys.switchRandomIndex) != nil {
            self.switchRandomIndex = defaults.bool(forKey: Keys.switchRandomIndex)
        } else {
            self.switchRandomIndex = true
        }

        // 加载显示模式（默认：模糊背景）
        if let savedMode = defaults.string(forKey: Keys.displayMode),
           let mode = WallpaperDisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        } else {
            self.displayMode = .blurBackground
        }

        // 更新上次打开日期
        self.lastOpenedDate = Date()
    }

    // MARK: - 重置

    /// 重置所有设置
    func resetAll() {
        defaults.removeObject(forKey: Keys.preferredLanguage)
        defaults.removeObject(forKey: Keys.preferredOrientation)
        defaults.removeObject(forKey: Keys.hasSeenShortcutsGuide)
        defaults.removeObject(forKey: Keys.lastOpenedDate)
        defaults.removeObject(forKey: Keys.switchDateRange)
        defaults.removeObject(forKey: Keys.switchRandomIndex)
        defaults.removeObject(forKey: Keys.displayMode)

        // 重新加载默认值
        preferredLanguage = nil  // 全部
        preferredOrientation = nil  // 全部
        hasSeenShortcutsGuide = false
        switchDateRange = .today
        switchRandomIndex = true
        displayMode = .blurBackground
    }
}

// MARK: - 切换日期范围枚举

/// 壁纸切换时的日期范围
enum SwitchDateRange: String, CaseIterable, Identifiable {
    case today = "today"                    // 仅今天（8张）
    case lastThreeDays = "lastThreeDays"    // 最近3天（24张）
    case lastSevenDays = "lastSevenDays"    // 最近7天（56张）
    case allUnlocked = "allUnlocked"        // 所有已解锁
    case custom = "custom"                  // 自定义选择

    var id: String { rawValue }

    // CaseIterable 需要过滤掉 custom（不在快速选择列表中显示）
    static var quickSelectCases: [SwitchDateRange] {
        [.today, .lastThreeDays, .lastSevenDays, .allUnlocked]
    }

    var displayName: String {
        switch self {
        case .today: return "仅今天"
        case .lastThreeDays: return "最近3天"
        case .lastSevenDays: return "最近7天"
        case .allUnlocked: return "所有已解锁"
        case .custom: return "自定义"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .today: return "range.today".localized
        case .lastThreeDays: return "range.three_days".localized
        case .lastSevenDays: return "range.seven_days".localized
        case .allUnlocked: return "range.all".localized
        case .custom: return "range.custom".localized
        }
    }

    var description: String {
        switch self {
        case .today: return "从今天的8张壁纸中随机选择"
        case .lastThreeDays: return "从最近3天的24张壁纸中随机选择"
        case .lastSevenDays: return "从最近7天的56张壁纸中随机选择"
        case .allUnlocked: return "从所有已解锁的壁纸中随机选择"
        case .custom: return "从自定义选择的日期中随机选择"
        }
    }

    var localizedDescription: String {
        switch self {
        case .today: return "range.today.hint".localized
        case .lastThreeDays: return "range.three_days.hint".localized
        case .lastSevenDays: return "range.seven_days.hint".localized
        case .allUnlocked: return "range.all.hint".localized
        case .custom: return "range.custom.hint".localized
        }
    }
}
