//
//  DateUtils.swift
//  Seth365
//
//  日期工具类
//

import Foundation

/// 日期工具类
enum DateUtils {
    /// 共享的日历实例
    static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    /// 2026 年的起始日期
    static let year2026Start: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }()

    /// 2026 年的结束日期
    static let year2026End: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 12
        components.day = 31
        return calendar.date(from: components) ?? Date()
    }()

    /// 获取所有可用月份（只返回有解锁日期的月份）
    static func getAllAvailableMonths() -> [Date] {
        var months: [Date] = []
        let today = calendar.startOfDay(for: Date())

        // 添加 2025 年 12 月（测试用）
        var dec2025 = DateComponents()
        dec2025.year = 2025
        dec2025.month = 12
        dec2025.day = 1
        if let date = calendar.date(from: dec2025) {
            // 检查这个月是否有解锁的日期
            if hasUnlockedDays(in: date) {
                months.append(date)
            }
        }

        // 添加 2026 年的月份（只添加有解锁日期的月份）
        for month in 1...12 {
            var components = DateComponents()
            components.year = 2026
            components.month = month
            components.day = 1
            if let date = calendar.date(from: components) {
                // 检查这个月是否有解锁的日期
                if hasUnlockedDays(in: date) {
                    months.append(date)
                }
            }
        }
        return months
    }

    /// 检查指定月份是否有解锁的日期
    static func hasUnlockedDays(in monthDate: Date) -> Bool {
        let days = getDaysInMonth(monthDate)
        let today = calendar.startOfDay(for: Date())

        for day in days {
            let dayStart = calendar.startOfDay(for: day)
            if dayStart <= today {
                return true
            }
        }
        return false
    }

    /// 获取 2026 年的所有月份（保留兼容）
    static func getMonthsIn2026() -> [Date] {
        return getAllAvailableMonths()
    }

    /// 获取指定月份的所有天数
    /// - Parameter monthDate: 月份的任意一天
    /// - Returns: 该月所有日期的数组
    static func getDaysInMonth(_ monthDate: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    /// 获取月份的第一天是星期几 (0 = 周日, 1 = 周一, ...)
    /// - Parameter monthDate: 月份的任意一天
    /// - Returns: 星期几的索引
    static func firstWeekdayOfMonth(_ monthDate: Date) -> Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) else {
            return 0
        }
        return calendar.component(.weekday, from: monthStart) - 1
    }

    /// 格式化日期为 "x月x日"
    static func formatMonthDay(_ date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)月\(day)日"
    }

    /// 格式化日期为 "2026年x月"
    static func formatYearMonth(_ date: Date) -> String {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return "\(year)年\(month)月"
    }

    /// 检查日期是否为今天
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// 检查日期是否在 2026 年内
    static func isIn2026(_ date: Date) -> Bool {
        let year = calendar.component(.year, from: date)
        return year == 2026
    }

    /// 检查日期是否已解锁（日期 <= 今天）
    static func isUnlocked(_ date: Date) -> Bool {
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)
        let result = targetDay <= today

        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDay)

        // 始终打印12月15日的检查结果
        if targetComponents.month == 12 && targetComponents.day == 15 {
            print("🔓 解锁检查 12/15: 目标=\(targetComponents.year!)/\(targetComponents.month!)/\(targetComponents.day!) 今天=\(todayComponents.year!)/\(todayComponents.month!)/\(todayComponents.day!) target时间戳=\(targetDay.timeIntervalSince1970) today时间戳=\(today.timeIntervalSince1970) 结果=\(result)")
        }

        return result
    }

    /// 获取今天的日期（不含时间）
    static func today() -> Date {
        calendar.startOfDay(for: Date())
    }

    /// 创建指定年月日的日期
    static func date(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)
    }
}
