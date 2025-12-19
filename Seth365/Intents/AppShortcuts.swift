//
//  AppShortcuts.swift
//  Seth365
//
//  预配置的 App Shortcuts
//

import AppIntents

/// App Shortcuts 提供者
struct AppShortcuts: AppShortcutsProvider {
    /// 预配置的快捷指令
    static var appShortcuts: [AppShortcut] {
        // 保存壁纸到相册（推荐用于自动化）
        AppShortcut(
            intent: SaveWallpaperToPhotosIntent(),
            phrases: [
                "保存 \(.applicationName) 壁纸",
                "\(.applicationName) 保存壁纸",
                "\(.applicationName) 每日壁纸"
            ],
            shortTitle: "保存壁纸到相册",
            systemImageName: "square.and.arrow.down"
        )

        // 获取壁纸（返回图片文件，供高级用户使用）
        AppShortcut(
            intent: GetTodayWallpaperIntent(),
            phrases: [
                "获取 \(.applicationName) 壁纸",
                "今日 \(.applicationName) 壁纸",
                "\(.applicationName) 换壁纸"
            ],
            shortTitle: "获取今日壁纸",
            systemImageName: "photo.on.rectangle"
        )
    }
}
