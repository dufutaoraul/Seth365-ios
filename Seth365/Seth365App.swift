//
//  Seth365App.swift
//  Seth365
//
//  Created by 刘文骏 on 2025/12/11.
//

import SwiftUI

@main
struct Seth365App: App {
    /// 使用 AppDelegate 处理后台下载
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // 启动时打印调试信息
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        print("🚀 App启动 当前时间: \(components.year!)-\(components.month!)-\(components.day!) \(components.hour!):\(components.minute!)")
        print("🚀 时区: \(TimeZone.current.identifier)")
        print("🚀 内置壁纸数量: \(AppInfo.totalBundledWallpapers) 张")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
