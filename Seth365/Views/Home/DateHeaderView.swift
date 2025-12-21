//
//  DateHeaderView.swift
//  Seth365
//
//  日期栏组件（带折叠按钮）
//

import SwiftUI

/// 日期栏组件
struct DateHeaderView: View {
    let currentMonth: Date
    @Binding var showCalendar: Bool
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void
    let canGoPrev: Bool
    let canGoNext: Bool

    var body: some View {
        HStack {
            // 上一月按钮
            Button(action: onPrevMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(canGoPrev ? .primary : .gray.opacity(0.3))
            }
            .disabled(!canGoPrev)

            Spacer()

            // 当前月份标题 + 折叠按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCalendar.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Text(DateUtils.formatYearMonth(currentMonth))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 下一月按钮
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canGoNext ? .primary : .gray.opacity(0.3))
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    DateHeaderView(
        currentMonth: Date(),
        showCalendar: .constant(true),
        onPrevMonth: {},
        onNextMonth: {},
        canGoPrev: true,
        canGoNext: false
    )
}
