//
//  HomeViewModel.swift
//  Seth365
//
//  首页视图模型
//

import Foundation
import SwiftUI
import Photos
import Combine

/// 首页视图模型
@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - 日历相关

    /// 可用月份列表
    @Published var months: [Date] = []

    /// 当前月份索引
    @Published var currentMonthIndex: Int = 0

    /// 选中的日期
    @Published var selectedDate: Date = Date()

    /// 当前月份的天数数据
    @Published var currentMonthDays: [DayItem] = []

    // MARK: - 壁纸相关

    /// 语言筛选
    @Published var filterLanguage: WallpaperLanguage? = nil

    /// 方向筛选
    @Published var filterOrientation: WallpaperOrientation? = nil

    /// 当前壁纸索引
    @Published var currentWallpaperIndex: Int = 0

    /// 所有壁纸（当前选中日期）
    @Published var allWallpapers: [Wallpaper] = []

    // MARK: - 弹窗相关

    @Published var showLockedAlert = false
    @Published var lockedAlertMessage = ""

    @Published var showNavigationAlert = false
    @Published var navigationAlertMessage = ""

    @Published var showPosterEditor = false
    @Published var posterImage: UIImage?

    @Published var showSaveAlert = false
    @Published var saveAlertTitle = ""
    @Published var saveAlertMessage = ""

    // MARK: - 计算属性

    /// 当前月份
    var currentMonth: Date {
        guard currentMonthIndex >= 0 && currentMonthIndex < months.count else {
            return months.first ?? Date()
        }
        return months[currentMonthIndex]
    }

    /// 筛选后的壁纸
    var filteredWallpapers: [Wallpaper] {
        var result = allWallpapers

        if let language = filterLanguage {
            result = result.filter { $0.language == language }
        }

        if let orientation = filterOrientation {
            result = result.filter { $0.orientation == orientation }
        }

        return result
    }

    /// 当前壁纸
    var currentWallpaper: Wallpaper? {
        guard currentWallpaperIndex >= 0 && currentWallpaperIndex < filteredWallpapers.count else {
            return filteredWallpapers.first
        }
        return filteredWallpapers[currentWallpaperIndex]
    }

    /// 是否可以切换到上一个月
    var canGoPrevious: Bool {
        guard currentMonthIndex > 0 else { return false }
        let targetMonth = months[currentMonthIndex - 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)
        return !(targetComp.year! < 2025 || (targetComp.year == 2025 && targetComp.month! < 12))
    }

    /// 是否可以切换到下一个月
    var canGoNext: Bool {
        guard currentMonthIndex < months.count - 1 else { return false }
        let todayComp = DateUtils.calendar.dateComponents([.year, .month], from: Date())
        let targetMonth = months[currentMonthIndex + 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)
        return !(targetComp.year! > todayComp.year! ||
                (targetComp.year == todayComp.year && targetComp.month! > todayComp.month!))
    }

    // MARK: - 初始化

    init() {
        loadMonths()
        scrollToCurrentMonth()
        updateCurrentMonthDays()
        selectTodayOrFirstUnlocked()
    }

    // MARK: - 月份操作

    private func loadMonths() {
        months = DateUtils.getAllAvailableMonths()
    }

    private func scrollToCurrentMonth() {
        let today = Date()
        let year = DateUtils.calendar.component(.year, from: today)
        let month = DateUtils.calendar.component(.month, from: today)

        for (index, monthDate) in months.enumerated() {
            let monthYear = DateUtils.calendar.component(.year, from: monthDate)
            let monthMonth = DateUtils.calendar.component(.month, from: monthDate)

            if monthYear == year && monthMonth == month {
                currentMonthIndex = index
                return
            }
        }

        if !months.isEmpty {
            currentMonthIndex = months.count - 1
        }
    }

    private func updateCurrentMonthDays() {
        let days = DateUtils.getDaysInMonth(currentMonth)
        let firstWeekday = DateUtils.firstWeekdayOfMonth(currentMonth)

        var items: [DayItem] = []

        for _ in 0..<firstWeekday {
            items.append(DayItem(date: nil, isPlaceholder: true))
        }

        for date in days {
            items.append(DayItem(date: date, isPlaceholder: false))
        }

        currentMonthDays = items
    }

    private func selectTodayOrFirstUnlocked() {
        let today = DateUtils.calendar.startOfDay(for: Date())

        // 如果今天已解锁，选中今天
        if DateUtils.cellState(for: today) == .unlocked {
            selectedDate = today
        } else {
            // 否则选中最后一个已解锁的日期
            selectedDate = DateUtils.launchDate
        }

        loadWallpapers()
    }

    func previousMonth() {
        guard canGoPrevious else {
            navigationAlertMessage = "calendar.nav.past".localized
            showNavigationAlert = true
            return
        }

        currentMonthIndex -= 1
        updateCurrentMonthDays()
    }

    func nextMonth() {
        guard canGoNext else {
            navigationAlertMessage = "calendar.nav.future".localized
            showNavigationAlert = true
            return
        }

        currentMonthIndex += 1
        updateCurrentMonthDays()
    }

    // MARK: - 日期选择

    func selectDate(_ date: Date) {
        let cellState = DateUtils.cellState(for: date)

        switch cellState {
        case .test:
            break

        case .unlocked:
            selectedDate = date
            currentWallpaperIndex = 0
            loadWallpapers()

        case .locked:
            let month = DateUtils.calendar.component(.month, from: date)
            let day = DateUtils.calendar.component(.day, from: date)
            lockedAlertMessage = String(format: "calendar.locked.hint".localized, month, day)
            showLockedAlert = true
        }
    }

    // MARK: - 壁纸操作

    private func loadWallpapers() {
        allWallpapers = Wallpaper.allWallpapers(for: selectedDate)
        currentWallpaperIndex = 0
    }

    func openPosterEditor() {
        guard let wallpaper = currentWallpaper else { return }

        Task {
            do {
                let image = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                posterImage = image
                showPosterEditor = true
            } catch {
                saveAlertTitle = "wallpaper.save.failed".localized
                saveAlertMessage = error.localizedDescription
                showSaveAlert = true
            }
        }
    }

    func saveCurrentWallpaper() {
        guard let wallpaper = currentWallpaper else { return }

        Task {
            do {
                let image = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)

                // 请求相册权限
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    saveAlertTitle = "wallpaper.save.failed".localized
                    saveAlertMessage = "需要相册访问权限"
                    showSaveAlert = true
                    return
                }

                // 保存到相册
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }

                saveAlertTitle = "wallpaper.save.success".localized
                saveAlertMessage = "wallpaper.save.success.message".localized
                showSaveAlert = true

            } catch {
                saveAlertTitle = "wallpaper.save.failed".localized
                saveAlertMessage = error.localizedDescription
                showSaveAlert = true
            }
        }
    }
}
