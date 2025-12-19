//
//  Seth365App.swift
//  Seth365
//
//  Created by 刘文骏 on 2025/12/11.
//

import SwiftUI

@main
struct Seth365App: App {
    @StateObject private var preloadService = WallpaperPreloadService.shared

    init() {
        // 启动时打印调试信息
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        print("🚀 App启动 当前时间: \(components.year!)-\(components.month!)-\(components.day!) \(components.hour!):\(components.minute!)")
        print("🚀 时区: \(TimeZone.current.identifier)")
        print("🚀 时间戳: \(now.timeIntervalSince1970)")

        // 测试今天的解锁状态
        let todayStart = calendar.startOfDay(for: now)
        print("🚀 今天起点时间戳: \(todayStart.timeIntervalSince1970)")

        // 创建12月15日并检查
        var dec15Components = DateComponents()
        dec15Components.year = 2025
        dec15Components.month = 12
        dec15Components.day = 15
        if let dec15 = calendar.date(from: dec15Components) {
            let dec15Start = calendar.startOfDay(for: dec15)
            print("🚀 12月15日时间戳: \(dec15Start.timeIntervalSince1970)")
            print("🚀 12月15日 <= 今天? \(dec15Start <= todayStart)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preloadService)
                .task {
                    // 启动时：只下载缺失的壁纸（不强制更新）
                    await preloadService.preloadWallpapers()
                }
        }
    }
}
