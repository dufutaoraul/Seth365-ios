//
//  MonthView.swift
//  Seth365
//
//  单月视图
//

import SwiftUI

/// 单月视图
struct MonthView: View {
    let monthDate: Date
    let days: [DayItem]
    let onDayTap: (Date) -> Void

    /// 星期标题
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    /// 网格列定义
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            // 星期标题行
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日期网格
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days) { item in
                    DayCell(item: item) {
                        if let date = item.date {
                            onDayTap(date)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    let viewModel = CalendarViewModel()
    let monthDate = DateUtils.getMonthsIn2026()[0] // 2026年1月
    let days = viewModel.getDaysForMonth(monthDate)

    return MonthView(monthDate: monthDate, days: days) { date in
        print("Selected: \(date)")
    }
}
