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
        let components = DateUtils.calendar.dateComponents([.year, .month, .day], from: date)
        let isUnlocked = DateUtils.isUnlocked(date)
        print("🖱️ 点击日期: \(components.year!)/\(components.month!)/\(components.day!) isUnlocked=\(isUnlocked)")

        // 检查是否已解锁
        guard isUnlocked else {
            // 显示温馨提示
            print("🔒 显示锁定提示")
            showLockedDateAlert(for: date)
            return
        }

        print("✅ 进入壁纸列表")
        selectedDate = date
        showWallpaperList = true
    }

    /// 显示锁定日期的温馨提示
    private func showLockedDateAlert(for date: Date) {
        let dateString = DateUtils.formatMonthDay(date)
        let today = Date()
        let calendar = DateUtils.calendar

        // 计算还有多少天解锁
        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: today)

        if let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day {
            if days == 1 {
                lockedAlertMessage = "明天就能解锁 \(dateString) 的壁纸啦～\n\n好饭不怕晚，精彩值得等待！"
            } else if days <= 7 {
                lockedAlertMessage = "还有 \(days) 天就能解锁 \(dateString) 的壁纸～\n\n耐心等待，惊喜即将到来！"
            } else if days <= 30 {
                lockedAlertMessage = "\(dateString) 的壁纸还在路上～\n\n再等 \(days) 天，美好如约而至！"
            } else {
                lockedAlertMessage = "\(dateString) 的壁纸正在为你准备中～\n\n时间会带来最好的礼物，敬请期待！"
            }
        } else {
            lockedAlertMessage = "这一天的壁纸还未解锁～\n\n美好的事物值得等待！"
        }

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
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        }
    }

    /// 切换到下一个月
    func nextMonth() {
        if currentMonthIndex < months.count - 1 {
            currentMonthIndex += 1
        }
    }

    /// 是否可以切换到上一个月
    var canGoPrevious: Bool {
        currentMonthIndex > 0
    }

    /// 是否可以切换到下一个月
    var canGoNext: Bool {
        currentMonthIndex < months.count - 1
    }
}

/// 日历单元格数据
struct DayItem: Identifiable {
    let id = UUID()
    let date: Date?
    let isPlaceholder: Bool

    var isUnlocked: Bool {
        guard let date = date else { return false }
        return DateUtils.isUnlocked(date)
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
