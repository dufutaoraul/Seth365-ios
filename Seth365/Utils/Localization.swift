//
//  Localization.swift
//  Seth365
//
//  本地化辅助工具
//

import Foundation
import SwiftUI

// MARK: - String 扩展

extension String {
    /// 本地化字符串
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// 带参数的本地化字符串
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

// MARK: - LocalizedStringKey 辅助

extension LocalizedStringKey {
    /// 从字符串键创建
    static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
}

// MARK: - 本地化键常量

enum L10n {
    // MARK: - Common
    enum Common {
        static let cancel = "cancel".localized
        static let confirm = "confirm".localized
        static let save = "save".localized
        static let delete = "delete".localized
        static let done = "done".localized
        static let settings = "settings".localized
        static let ok = "ok".localized
    }

    // MARK: - Tab Bar
    enum Tab {
        static let calendar = "tab.calendar".localized
        static let today = "tab.today".localized
        static let settings = "tab.settings".localized
    }

    // MARK: - Calendar
    enum Calendar {
        static let title = "calendar.title".localized
        static let lockedTitle = "calendar.locked.title".localized

        static func lockedTomorrow(_ date: String) -> String {
            "calendar.locked.tomorrow".localized(date)
        }

        static func lockedDays(_ days: Int, _ date: String) -> String {
            "calendar.locked.days".localized(days, date)
        }

        static func lockedFuture(_ date: String) -> String {
            "calendar.locked.future".localized(date)
        }
    }

    // MARK: - Wallpaper
    enum Wallpaper {
        static func listTitle(_ date: String) -> String {
            "wallpaper.list.title".localized(date)
        }

        static let filterAll = "wallpaper.filter.all".localized

        static func count(_ count: Int) -> String {
            "wallpaper.count".localized(count)
        }

        static let detailSave = "wallpaper.detail.save".localized
        static let detailPoster = "wallpaper.detail.poster".localized
        static let saveSuccess = "wallpaper.save.success".localized
        static let saveSuccessMessage = "wallpaper.save.success.message".localized
        static let saveFailed = "wallpaper.save.failed".localized
        static let goSet = "wallpaper.save.go_set".localized
    }

    // MARK: - Poster
    enum Poster {
        static let title = "poster.title".localized
        static let generate = "poster.generate".localized
        static let detecting = "poster.detecting".localized
        static let qrSet = "poster.qr.set".localized
        static let qrNotSet = "poster.qr.not_set".localized
        static let qrHint = "poster.qr.hint".localized
        static let qrGoSettings = "poster.qr.go_settings".localized
        static let detected = "poster.detected".localized
        static let notDetected = "poster.not_detected".localized
        static let tip = "poster.tip".localized
        static let noQrTitle = "poster.no_qr.title".localized
        static let noQrMessage = "poster.no_qr.message".localized
        static let noQrGo = "poster.no_qr.go".localized
        static let saveSuccess = "poster.save.success".localized
        static let saveSuccessMessage = "poster.save.success.message".localized
    }

    // MARK: - Settings
    enum Settings {
        static let title = "settings.title".localized
        static let myQr = "settings.my_qr".localized
        static let qrSet = "settings.qr.set".localized
        static let qrNotSet = "settings.qr.not_set".localized
        static let qrHint = "settings.qr.hint".localized
        static let qrSelect = "settings.qr.select".localized
        static let qrChange = "settings.qr.change".localized
        static let qrDelete = "settings.qr.delete".localized
        static let qrDeleteTitle = "settings.qr.delete.title".localized
        static let qrDeleteMessage = "settings.qr.delete.message".localized
        static let preferences = "settings.preferences".localized
        static let language = "settings.language".localized
        static let orientation = "settings.orientation".localized
        static let switchSettings = "settings.switch".localized
        static let switchRange = "settings.switch.range".localized
        static let switchRandom = "settings.switch.random".localized
        static let auto = "settings.auto".localized
        static let autoShortcuts = "settings.auto.shortcuts".localized
        static let storage = "settings.storage".localized
        static let cacheSize = "settings.cache.size".localized
        static let cacheClear = "settings.cache.clear".localized
        static let cacheClearTitle = "settings.cache.clear.title".localized
        static let cacheClearMessage = "settings.cache.clear.message".localized
        static let cacheCalculating = "settings.cache.calculating".localized
        static let about = "settings.about".localized
        static let version = "settings.version".localized
        static let year = "settings.year".localized
        static let dailyCount = "settings.daily_count".localized
    }

    // MARK: - Language
    enum Language {
        static let chinese = "language.chinese".localized
        static let english = "language.english".localized
    }

    // MARK: - Orientation
    enum Orientation {
        static let portrait = "orientation.portrait".localized
        static let landscape = "orientation.landscape".localized
    }

    // MARK: - Date Range
    enum Range {
        static let today = "range.today".localized
        static let todayHint = "range.today.hint".localized
        static let threeDays = "range.three_days".localized
        static let threeDaysHint = "range.three_days.hint".localized
        static let sevenDays = "range.seven_days".localized
        static let sevenDaysHint = "range.seven_days.hint".localized
        static let all = "range.all".localized
        static let allHint = "range.all.hint".localized
    }
}
