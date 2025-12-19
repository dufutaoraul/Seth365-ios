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
                // 调试：如果是今天，打印状态
                let _ = {
                    if item.isToday {
                        print("📅 DayCell渲染今天: day=\(item.dayNumber ?? 0) isToday=\(item.isToday) isUnlocked=\(item.isUnlocked)")
                    }
                }()

                // 背景
                if item.isToday {
                    Circle()
                        .fill(Constants.Colors.today)
                } else if item.isUnlocked && item.date != nil {
                    Circle()
                        .fill(Color.clear)
                }

                // 内容
                if item.isPlaceholder {
                    // 空白占位
                    Color.clear
                } else if let dayNumber = item.dayNumber {
                    if item.isUnlocked {
                        // 已解锁：显示日期数字
                        Text("\(dayNumber)")
                            .font(.system(size: 16, weight: item.isToday ? .bold : .regular))
                            .foregroundColor(item.isToday ? .white : .primary)
                    } else {
                        // 未解锁：显示锁图标
                        VStack(spacing: 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("\(dayNumber)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Constants.Colors.locked)
                    }
                }
            }
            .frame(width: Constants.UI.calendarDaySize, height: Constants.UI.calendarDaySize)
        }
        .disabled(item.isPlaceholder)
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
