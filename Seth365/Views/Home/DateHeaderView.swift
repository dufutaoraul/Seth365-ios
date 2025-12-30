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

    /// 根据设备类型返回合适的按钮大小
    private var navButtonSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 52 : 44
    }

    /// 根据设备类型返回合适的图标字体
    private var navIconFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .title2 : .title3
    }

    /// 根据设备类型返回合适的标题字体
    private var titleFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .title : .title2
    }

    var body: some View {
        HStack {
            // 上一月按钮
            Button(action: onPrevMonth) {
                Image(systemName: "chevron.left")
                    .font(navIconFont)
                    .foregroundColor(canGoPrev ? .primary : .gray.opacity(0.3))
                    .frame(width: navButtonSize, height: navButtonSize)
                    .contentShape(Rectangle())
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
                        .font(titleFont)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(minHeight: navButtonSize)
                .contentShape(Rectangle())
            }

            Spacer()

            // 下一月按钮
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(navIconFont)
                    .foregroundColor(canGoNext ? .primary : .gray.opacity(0.3))
                    .frame(width: navButtonSize, height: navButtonSize)
                    .contentShape(Rectangle())
            }
            .disabled(!canGoNext)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
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
