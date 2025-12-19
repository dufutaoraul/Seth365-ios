//
//  DebugLogService.swift
//  Seth365
//
//  调试日志服务 - 记录运行日志用于排查问题
//

import Foundation
import UIKit
import Combine

/// 日志级别
enum LogLevel: String {
    case info = "ℹ️"
    case success = "✅"
    case warning = "⚠️"
    case error = "❌"
    case debug = "🔍"
}

/// 日志条目
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }

    var displayText: String {
        "[\(formattedTime)] \(level.rawValue) [\(source)] \(message)"
    }
}

/// 调试日志服务
class DebugLogService: ObservableObject {
    /// 共享实例
    static let shared = DebugLogService()

    /// 日志条目（最新在前）
    @Published private(set) var logs: [LogEntry] = []

    /// 最大日志数量
    private let maxLogs = 500

    /// 是否启用日志（Release 版本可以关闭）
    var isEnabled = true

    private init() {
        log(.info, "应用启动", source: "App")
    }

    // MARK: - 日志记录方法

    /// 记录日志
    func log(_ level: LogLevel, _ message: String, source: String = "General") {
        guard isEnabled else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            source: source
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.insert(entry, at: 0)

            // 限制日志数量
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
        }

        // 同时输出到控制台
        print(entry.displayText)
    }

    /// 快捷方法
    func info(_ message: String, source: String = "General") {
        log(.info, message, source: source)
    }

    func success(_ message: String, source: String = "General") {
        log(.success, message, source: source)
    }

    func warning(_ message: String, source: String = "General") {
        log(.warning, message, source: source)
    }

    func error(_ message: String, source: String = "General") {
        log(.error, message, source: source)
    }

    func debug(_ message: String, source: String = "General") {
        log(.debug, message, source: source)
    }

    // MARK: - 日志管理

    /// 清除所有日志
    func clearLogs() {
        DispatchQueue.main.async { [weak self] in
            self?.logs.removeAll()
        }
    }

    /// 导出日志文本
    func exportLogs() -> String {
        let header = """
        Seth365 调试日志
        导出时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))
        设备: \(UIDevice.current.name)
        系统: iOS \(UIDevice.current.systemVersion)
        App 版本: \(AppInfo.fullVersion)
        ----------------------------------------

        """

        let logText = logs.reversed().map { $0.displayText }.joined(separator: "\n")
        return header + logText
    }

    /// 获取最近的错误日志
    func recentErrors(count: Int = 10) -> [LogEntry] {
        return logs.filter { $0.level == .error }.prefix(count).map { $0 }
    }
}

// MARK: - 全局日志函数

/// 全局日志函数，方便调用
func appLog(_ level: LogLevel, _ message: String, source: String = "General") {
    DebugLogService.shared.log(level, message, source: source)
}
