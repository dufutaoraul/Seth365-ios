//
//  CalendarGridView.swift
//  Seth365
//
//  可折叠日历网格组件
//

import SwiftUI

/// 可折叠日历网格组件
struct CalendarGridView: View {
    let days: [DayItem]
    @Binding var selectedDate: Date
    let onDateTap: (Date) -> Void

    /// 星期标题
    private let weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]

    /// 网格列定义
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 8) {
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
                    CalendarDayCell(
                        item: item,
                        isSelected: isSelected(item)
                    ) {
                        if let date = item.date {
                            onDateTap(date)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(UIColor.systemBackground))
    }

    private func isSelected(_ item: DayItem) -> Bool {
        guard let date = item.date else { return false }
        return DateUtils.calendar.isDate(date, inSameDayAs: selectedDate)
    }
}

/// 日历日期单元格（首页专用，带选中状态）
struct CalendarDayCell: View {
    let item: DayItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 选中背景
                if isSelected && item.cellState == .unlocked {
                    Circle()
                        .fill(Color.blue)
                }
                // 今天背景（未选中时）
                else if item.isToday && item.cellState == .unlocked {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                }

                // 内容
                if item.isPlaceholder {
                    Color.clear
                } else if let dayNumber = item.dayNumber {
                    switch item.cellState {
                    case .unlocked:
                        Text("\(dayNumber)")
                            .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .white : .primary)

                    case .locked:
                        VStack(spacing: 1) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                            Text("\(dayNumber)")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.gray.opacity(0.5))

                    case .test:
                        VStack(spacing: 1) {
                            Image(systemName: "nosign")
                                .font(.system(size: 8))
                            Text("\(dayNumber)")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.gray.opacity(0.3))
                    }
                }
            }
            .frame(width: 36, height: 36)
        }
        .disabled(item.isPlaceholder || item.cellState == .test)
    }
}

#Preview {
    CalendarGridView(
        days: [],
        selectedDate: .constant(Date()),
        onDateTap: { _ in }
    )
}
