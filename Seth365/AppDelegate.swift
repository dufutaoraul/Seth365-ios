//
//  AppDelegate.swift
//  Seth365
//
//  处理后台下载回调
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {

    /// 处理后台 URLSession 事件
    /// iOS 在后台下载完成时会调用此方法
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        appLog(.info, "收到后台会话事件: \(identifier)", source: "AppDelegate")

        if identifier == BackgroundDownloadManager.backgroundSessionIdentifier {
            // 保存完成回调，等所有下载事件处理完后调用
            BackgroundDownloadManager.shared.backgroundCompletionHandler = completionHandler
        } else {
            completionHandler()
        }
    }

    /// App 启动完成
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        appLog(.info, "App 启动完成", source: "AppDelegate")

        // 恢复之前的下载任务
        BackgroundDownloadManager.shared.resumePendingDownloads()

        return true
    }
}
