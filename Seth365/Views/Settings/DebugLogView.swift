//
//  DebugLogView.swift
//  Seth365
//
//  调试日志查看页面
//

import SwiftUI

/// 调试日志查看页面
struct DebugLogView: View {
    @ObservedObject private var logService = DebugLogService.shared
    @State private var selectedLevel: LogLevel?
    @State private var showShareSheet = false
    @State private var exportedText = ""

    var filteredLogs: [LogEntry] {
        if let level = selectedLevel {
            return logService.logs.filter { $0.level == level }
        }
        return logService.logs
    }

    var body: some View {
        VStack(spacing: 0) {
            // 筛选器
            filterBar

            // 日志列表
            if filteredLogs.isEmpty {
                emptyState
            } else {
                logList
            }
        }
        .navigationTitle("运行日志")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: shareLog) {
                        Label("导出日志", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: clearLogs) {
                        Label("清除日志", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [exportedText])
        }
    }

    // MARK: - 筛选栏

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                LogFilterChip(title: "全部", isSelected: selectedLevel == nil) {
                    selectedLevel = nil
                }

                LogFilterChip(title: "✅ 成功", isSelected: selectedLevel == .success) {
                    selectedLevel = .success
                }

                LogFilterChip(title: "⚠️ 警告", isSelected: selectedLevel == .warning) {
                    selectedLevel = .warning
                }

                LogFilterChip(title: "❌ 错误", isSelected: selectedLevel == .error) {
                    selectedLevel = .error
                }

                LogFilterChip(title: "ℹ️ 信息", isSelected: selectedLevel == .info) {
                    selectedLevel = .info
                }

                LogFilterChip(title: "🔍 调试", isSelected: selectedLevel == .debug) {
                    selectedLevel = .debug
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 日志列表

    private var logList: some View {
        List {
            ForEach(filteredLogs) { entry in
                LogEntryRow(entry: entry)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("暂无日志")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("运行快捷指令或使用 App 后会产生日志")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - 操作

    private func shareLog() {
        exportedText = logService.exportLogs()
        showShareSheet = true
    }

    private func clearLogs() {
        logService.clearLogs()
    }
}

// MARK: - 日志筛选按钮

private struct LogFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 日志条目行

private struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.rawValue)
                Text(entry.source)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                Spacer()
                Text(entry.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(entry.message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 分享 Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DebugLogView()
    }
}
