//
//  CalendarViewModel.swift
//  Seth365
//
//  日历视图模型
//

import Foundation
import SwiftUI
import Combine

/// 日历视图模型
class CalendarViewModel: ObservableObject {
    /// 2026 年的所有月份
    @Published var months: [Date] = []

    /// 当前显示的月份索引
    @Published var currentMonthIndex: Int = 0

    /// 选中的日期
    @Published var selectedDate: Date?

    /// 是否显示壁纸列表
    @Published var showWallpaperList: Bool = false

    /// 是否显示锁定提示
    @Published var showLockedAlert: Bool = false

    /// 锁定提示信息
    @Published var lockedAlertMessage: String = ""

    /// 是否显示导航提示
    @Published var showNavigationAlert: Bool = false

    /// 导航提示信息
    @Published var navigationAlertMessage: String = ""

    init() {
        loadMonths()
        scrollToCurrentMonth()
    }

    /// 加载 2026 年的所有月份
    private func loadMonths() {
        months = DateUtils.getMonthsIn2026()
    }

    /// 滚动到当前月份
    private func scrollToCurrentMonth() {
        let today = Date()
        let year = DateUtils.calendar.component(.year, from: today)
        let month = DateUtils.calendar.component(.month, from: today)

        print("📅 今天: \(year)年\(month)月")
        print("📅 可用月份: \(months.map { "\(DateUtils.calendar.component(.year, from: $0))年\(DateUtils.calendar.component(.month, from: $0))月" })")

        // 查找匹配的月份索引
        for (index, monthDate) in months.enumerated() {
            let monthYear = DateUtils.calendar.component(.year, from: monthDate)
            let monthMonth = DateUtils.calendar.component(.month, from: monthDate)

            if monthYear == year && monthMonth == month {
                currentMonthIndex = index
                print("📅 找到当前月份索引: \(index)")
                return
            }
        }

        // 如果没找到，显示最后一个有日期的月份（最近的）
        if !months.isEmpty {
            currentMonthIndex = months.count - 1
            print("📅 未找到当前月份，显示最后一个: \(currentMonthIndex)")
        } else {
            currentMonthIndex = 0
        }
    }

    /// 选择日期
    /// - Parameter date: 要选择的日期
    func selectDate(_ date: Date) {
        let cellState = DateUtils.cellState(for: date)

        switch cellState {
        case .test:
            // 测试日期：无反应
            break

        case .unlocked:
            // 已解锁：进入壁纸列表
            selectedDate = date
            showWallpaperList = true

        case .locked:
            // 未来日期：显示温馨提示
            showLockedDateAlert(for: date)
        }
    }

    /// 显示锁定日期的温馨提示
    private func showLockedDateAlert(for date: Date) {
        let month = DateUtils.calendar.component(.month, from: date)
        let day = DateUtils.calendar.component(.day, from: date)

        lockedAlertMessage = String(format: "calendar.locked.hint".localized, month, day)
        showLockedAlert = true
    }

    /// 检查指定日期是否已解锁
    func isDateUnlocked(_ date: Date) -> Bool {
        DateUtils.isUnlocked(date)
    }

    /// 检查指定日期是否为今天
    func isToday(_ date: Date) -> Bool {
        DateUtils.isToday(date)
    }

    /// 获取指定月份的天数数据
    func getDaysForMonth(_ monthDate: Date) -> [DayItem] {
        let days = DateUtils.getDaysInMonth(monthDate)
        let firstWeekday = DateUtils.firstWeekdayOfMonth(monthDate)

        var items: [DayItem] = []

        // 添加空白占位（月初）
        for _ in 0..<firstWeekday {
            items.append(DayItem(date: nil, isPlaceholder: true))
        }

        // 添加实际日期
        for date in days {
            items.append(DayItem(date: date, isPlaceholder: false))
        }

        return items
    }

    /// 获取当前月份
    var currentMonth: Date {
        guard currentMonthIndex >= 0 && currentMonthIndex < months.count else {
            return months.first ?? Date()
        }
        return months[currentMonthIndex]
    }

    /// 切换到上一个月
    func previousMonth() {
        guard currentMonthIndex > 0 else {
            // 已经是第一个月（2025年12月）
            navigationAlertMessage = "calendar.nav.past".localized
            showNavigationAlert = true
            return
        }

        let targetMonth = months[currentMonthIndex - 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)

        // 检查是否早于2025年12月
        if targetComp.year! < 2025 || (targetComp.year == 2025 && targetComp.month! < 12) {
            navigationAlertMessage = "calendar.nav.past".localized
            showNavigationAlert = true
            return
        }

        currentMonthIndex -= 1
    }

    /// 切换到下一个月
    func nextMonth() {
        guard currentMonthIndex < months.count - 1 else {
            // 已经是最后一个月
            navigationAlertMessage = "calendar.nav.future".localized
            showNavigationAlert = true
            return
        }

        let todayComp = DateUtils.calendar.dateComponents([.year, .month], from: Date())
        let targetMonth = months[currentMonthIndex + 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)

        // 检查是否晚于当前月份
        if targetComp.year! > todayComp.year! ||
           (targetComp.year == todayComp.year && targetComp.month! > todayComp.month!) {
            navigationAlertMessage = "calendar.nav.future".localized
            showNavigationAlert = true
            return
        }

        currentMonthIndex += 1
    }

    /// 是否可以切换到上一个月
    var canGoPrevious: Bool {
        guard currentMonthIndex > 0 else { return false }
        let targetMonth = months[currentMonthIndex - 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)
        // 不能早于2025年12月
        return !(targetComp.year! < 2025 || (targetComp.year == 2025 && targetComp.month! < 12))
    }

    /// 是否可以切换到下一个月
    var canGoNext: Bool {
        guard currentMonthIndex < months.count - 1 else { return false }
        let todayComp = DateUtils.calendar.dateComponents([.year, .month], from: Date())
        let targetMonth = months[currentMonthIndex + 1]
        let targetComp = DateUtils.calendar.dateComponents([.year, .month], from: targetMonth)
        // 不能晚于当前月份
        return !(targetComp.year! > todayComp.year! ||
                (targetComp.year == todayComp.year && targetComp.month! > todayComp.month!))
    }
}

/// 日历单元格数据
struct DayItem: Identifiable {
    let id = UUID()
    let date: Date?
    let isPlaceholder: Bool

    /// 日期单元格状态
    var cellState: DateCellState {
        guard let date = date else { return .test }
        return DateUtils.cellState(for: date)
    }

    var isUnlocked: Bool {
        cellState == .unlocked
    }

    var isToday: Bool {
        guard let date = date else { return false }
        return DateUtils.isToday(date)
    }

    var dayNumber: Int? {
        guard let date = date else { return nil }
        return DateUtils.calendar.component(.day, from: date)
    }
}
