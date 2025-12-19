//
//  DateRangeSelectorView.swift
//  Seth365
//
//  灵活的日期范围选择器
//

import SwiftUI

/// 日期范围选择器视图
struct DateRangeSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = UserDefaultsManager.shared

    // 当前选中的日期集合
    @State private var selectedDates: Set<Date> = []

    // 展开状态
    @State private var expandedMonths: Set<Int> = []

    // 当前年份（2025年12月测试，2026年正式）
    private let currentYear: Int
    private let availableMonths: [Int]

    init() {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)

        if year == 2025 && month == 12 {
            // 测试模式
            currentYear = 2025
            availableMonths = [12]
        } else if year == 2026 {
            // 正式模式
            currentYear = 2026
            availableMonths = Array(1...month)
        } else {
            currentYear = 2026
            availableMonths = [1]
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 快速选择
                Section("快速选择") {
                    quickSelectButton("今天", dates: [Date()])
                    quickSelectButton("最近 3 天", dates: lastNDays(3))
                    quickSelectButton("最近 7 天", dates: lastNDays(7))
                    quickSelectButton("全部已解锁", dates: allUnlockedDates())
                }

                // MARK: - 按月份选择
                Section("按月份选择") {
                    ForEach(availableMonths, id: \.self) { month in
                        MonthSelectionView(
                            year: currentYear,
                            month: month,
                            selectedDates: $selectedDates,
                            isExpanded: expandedMonths.contains(month)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                if expandedMonths.contains(month) {
                                    expandedMonths.remove(month)
                                } else {
                                    expandedMonths.insert(month)
                                }
                            }
                        }
                    }
                }

                // MARK: - 已选日期统计
                Section {
                    HStack {
                        Text("已选择")
                        Spacer()
                        Text("\(selectedDates.count) 天，\(selectedDates.count * 8) 张壁纸")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("选择日期范围")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadSavedSelection()
            }
        }
    }

    // MARK: - 快速选择按钮

    private func quickSelectButton(_ title: String, dates: [Date]) -> some View {
        Button {
            withAnimation {
                selectedDates = Set(dates.map { Calendar.current.startOfDay(for: $0) })
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                if Set(dates.map { Calendar.current.startOfDay(for: $0) }) == selectedDates {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }

    // MARK: - 辅助方法

    private func lastNDays(_ n: Int) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []
        for i in 0..<n {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }

    private func allUnlockedDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []

        // 从起始日期到今天
        var startDate: Date
        if currentYear == 2025 {
            startDate = DateUtils.date(year: 2025, month: 12, day: 1) ?? today
        } else {
            startDate = DateUtils.date(year: 2026, month: 1, day: 1) ?? today
        }

        var currentDate = calendar.startOfDay(for: startDate)
        while currentDate <= today {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
        }

        return dates
    }

    private func loadSavedSelection() {
        selectedDates = settings.customSelectedDates
        // 如果没有自定义选择，使用默认的切换范围
        if selectedDates.isEmpty {
            switch settings.switchDateRange {
            case .today:
                selectedDates = Set([Calendar.current.startOfDay(for: Date())])
            case .lastThreeDays:
                selectedDates = Set(lastNDays(3))
            case .lastSevenDays:
                selectedDates = Set(lastNDays(7))
            case .allUnlocked:
                selectedDates = Set(allUnlockedDates())
            case .custom:
                // 自定义模式但没有日期，默认选择今天
                selectedDates = Set([Calendar.current.startOfDay(for: Date())])
            }
        }
    }

    private func saveSelection() {
        settings.customSelectedDates = selectedDates
        settings.switchDateRange = .custom
    }
}

// MARK: - 月份选择视图

struct MonthSelectionView: View {
    let year: Int
    let month: Int
    @Binding var selectedDates: Set<Date>
    let isExpanded: Bool

    private var monthDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startOfMonth = calendar.date(from: components) else { return [] }

        let range = calendar.range(of: .day, in: .month, for: startOfMonth) ?? 1..<32

        for day in range {
            components.day = day
            if let date = calendar.date(from: components) {
                let startOfDay = calendar.startOfDay(for: date)
                // 只包含已解锁的日期（不超过今天）
                if startOfDay <= today {
                    dates.append(startOfDay)
                }
            }
        }

        return dates
    }

    private var isAllSelected: Bool {
        let dates = Set(monthDates)
        return !dates.isEmpty && dates.isSubset(of: selectedDates)
    }

    private var unlockedCount: Int {
        monthDates.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 月份标题行
            HStack {
                Text("\(month)月")
                    .font(.headline)

                Spacer()

                Text("已解锁 \(unlockedCount) 天")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // 全选按钮
                Button {
                    toggleSelectAll()
                } label: {
                    Text(isAllSelected ? "取消全选" : "全选")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // 展开后显示周选择和日期
            if isExpanded {
                // 按周分组
                WeekSelectionView(
                    dates: monthDates,
                    selectedDates: $selectedDates
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleSelectAll() {
        let dates = Set(monthDates)
        if isAllSelected {
            // 取消选择这个月的所有日期
            selectedDates.subtract(dates)
        } else {
            // 选择这个月的所有日期
            selectedDates.formUnion(dates)
        }
    }
}

// MARK: - 周选择视图

struct WeekSelectionView: View {
    let dates: [Date]
    @Binding var selectedDates: Set<Date>

    private var weekGroups: [[Date]] {
        let calendar = Calendar.current
        var groups: [[Date]] = []
        var currentWeek: [Date] = []
        var lastWeekOfYear: Int?

        for date in dates.sorted() {
            let weekOfYear = calendar.component(.weekOfYear, from: date)

            if let last = lastWeekOfYear, last != weekOfYear {
                if !currentWeek.isEmpty {
                    groups.append(currentWeek)
                    currentWeek = []
                }
            }

            currentWeek.append(date)
            lastWeekOfYear = weekOfYear
        }

        if !currentWeek.isEmpty {
            groups.append(currentWeek)
        }

        return groups
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(weekGroups.enumerated()), id: \.offset) { index, weekDates in
                WeekRowView(
                    weekNumber: index + 1,
                    dates: weekDates,
                    selectedDates: $selectedDates
                )
            }
        }
    }
}

// MARK: - 单周行视图

struct WeekRowView: View {
    let weekNumber: Int
    let dates: [Date]
    @Binding var selectedDates: Set<Date>

    private var isAllSelected: Bool {
        let weekSet = Set(dates)
        return weekSet.isSubset(of: selectedDates)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 周标题
            HStack {
                Text("第 \(weekNumber) 周")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    toggleWeek()
                } label: {
                    Image(systemName: isAllSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isAllSelected ? .blue : .gray)
                }
                .buttonStyle(.plain)
            }

            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(dates, id: \.self) { date in
                    DayToggleButton(
                        date: date,
                        isSelected: selectedDates.contains(date)
                    ) {
                        toggleDate(date)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }

    private func toggleWeek() {
        let weekSet = Set(dates)
        if isAllSelected {
            selectedDates.subtract(weekSet)
        } else {
            selectedDates.formUnion(weekSet)
        }
    }

    private func toggleDate(_ date: Date) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            selectedDates.insert(date)
        }
    }
}

// MARK: - 日期切换按钮

struct DayToggleButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: action) {
            Text("\(dayNumber)")
                .font(.caption)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DateRangeSelectorView()
}
