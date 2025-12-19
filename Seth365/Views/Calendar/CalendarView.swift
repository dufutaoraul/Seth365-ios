//
//  CalendarView.swift
//  Seth365
//
//  2026年日历主视图
//

import SwiftUI

/// 2026年日历主视图
struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月份切换控制
                monthSwitcher

                // 日历内容
                TabView(selection: $viewModel.currentMonthIndex) {
                    ForEach(Array(viewModel.months.enumerated()), id: \.offset) { index, monthDate in
                        MonthView(
                            monthDate: monthDate,
                            days: viewModel.getDaysForMonth(monthDate),
                            onDayTap: { date in
                                viewModel.selectDate(date)
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // 底部提示
                bottomHint
            }
            .navigationTitle("Seth365")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $viewModel.showWallpaperList) {
                if let selectedDate = viewModel.selectedDate {
                    WallpaperListView(date: selectedDate)
                }
            }
            .alert("还未解锁", isPresented: $viewModel.showLockedAlert) {
                Button("好的，我等待") { }
            } message: {
                Text(viewModel.lockedAlertMessage)
            }
        }
    }

    /// 月份切换控制
    private var monthSwitcher: some View {
        HStack {
            // 上一月按钮
            Button(action: { viewModel.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(viewModel.canGoPrevious ? .primary : .gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoPrevious)

            Spacer()

            // 当前月份标题
            Text(DateUtils.formatYearMonth(viewModel.currentMonth))
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            // 下一月按钮
            Button(action: { viewModel.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(viewModel.canGoNext ? .primary : .gray.opacity(0.3))
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    /// 底部提示
    private var bottomHint: some View {
        VStack(spacing: 8) {
            Text("点击日期查看壁纸")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    CalendarView()
}
