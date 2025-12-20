//
//  DayCell.swift
//  Seth365
//
//  日历日期单元格
//

import SwiftUI

/// 日历日期单元格
struct DayCell: View {
    let item: DayItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景
                if item.isToday && item.cellState == .unlocked {
                    Circle()
                        .fill(Constants.Colors.today)
                }

                // 内容
                if item.isPlaceholder {
                    // 空白占位
                    Color.clear
                } else if let dayNumber = item.dayNumber {
                    switch item.cellState {
                    case .unlocked:
                        // 已解锁：显示日期数字
                        Text("\(dayNumber)")
                            .font(.system(size: 16, weight: item.isToday ? .bold : .regular))
                            .foregroundColor(item.isToday ? .white : .primary)

                    case .locked:
                        // 未来日期：显示锁图标
                        VStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("\(dayNumber)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Constants.Colors.locked)

                    case .test:
                        // 测试日期：显示禁止图标
                        VStack(spacing: 2) {
                            Image(systemName: "nosign")
                                .font(.system(size: 10))
                            Text("\(dayNumber)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
            .frame(width: Constants.UI.calendarDaySize, height: Constants.UI.calendarDaySize)
        }
        .disabled(item.isPlaceholder || item.cellState == .test)
    }
}

#Preview {
    HStack(spacing: 8) {
        // 已解锁的日期
        DayCell(item: DayItem(date: Date(), isPlaceholder: false)) {
            print("Tapped today")
        }

        // 未解锁的日期
        DayCell(item: DayItem(
            date: DateUtils.date(year: 2026, month: 12, day: 31),
            isPlaceholder: false
        )) {
            print("Tapped future")
        }

        // 占位符
        DayCell(item: DayItem(date: nil, isPlaceholder: true)) {
            print("Tapped placeholder")
        }
    }
    .padding()
}
