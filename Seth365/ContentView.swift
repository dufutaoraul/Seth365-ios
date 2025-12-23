//
//  ContentView.swift
//  Seth365
//
//  Created by 刘文骏 on 2025/12/11.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isReady = false
    @State private var showSplash = true
    @State private var showDownloadAlert = false
    @State private var pendingDownloadInfo: (count: Int, size: String)? = nil
    @StateObject private var preloadService = WallpaperPreloadService.shared

    var body: some View {
        ZStack {
            // 主内容
            TabView(selection: $selectedTab) {
                // 日历页面
                CalendarView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text(LocalizedStringKey("tab.calendar"))
                    }
                    .tag(0)

                // 今日壁纸页面
                NavigationStack {
                    WallpaperListView(date: Date())
                }
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text(LocalizedStringKey("tab.today"))
                }
                .tag(1)

                // 设置页面
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text(LocalizedStringKey("tab.settings"))
                    }
                    .tag(2)
            }
            .opacity(showSplash ? 0 : 1)

            // 启动欢迎页
            if showSplash {
                SplashView(isReady: $isReady)
                    .transition(.opacity)
            }

            // 可拖动的下载进度浮窗
            if !showSplash && preloadService.isLoading {
                DraggableDownloadIndicator()
                    .environmentObject(preloadService)
            }
        }
        .onChange(of: isReady) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
                // 检查是否需要下载额外资源
                Task {
                    await checkForDownloads()
                }
            }
        }
        .alert("download.alert.title".localized, isPresented: $showDownloadAlert) {
            Button("download.alert.download_now".localized) {
                Task {
                    await preloadService.preloadWallpapers()
                }
            }
            Button("download.alert.later".localized, role: .cancel) {
                // 用户选择稍后下载，不执行任何操作
            }
        } message: {
            if let info = pendingDownloadInfo {
                Text(String(format: "download.alert.message".localized, info.count, info.size))
            }
        }
    }

    /// 检查是否需要下载额外资源
    private func checkForDownloads() async {
        let downloadInfo = await preloadService.checkPendingDownloads()

        if downloadInfo.count > 0 {
            await MainActor.run {
                pendingDownloadInfo = downloadInfo
                showDownloadAlert = true
            }
        }
    }
}

/// 启动欢迎页
struct SplashView: View {
    @Binding var isReady: Bool
    @State private var isAnimating = false
    @State private var statusText = "splash.loading".localized

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // App 图标
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // App 名称
                Text("Seth365")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // 副标题
                Text("splash.subtitle".localized)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                // 加载指示器
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
            prepareApp()
        }
    }

    private func prepareApp() {
        // 模拟准备过程（实际上内置壁纸已经在 Bundle 中，无需加载）
        Task {
            // 短暂延迟让用户看到欢迎页
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒

            await MainActor.run {
                statusText = "splash.ready".localized
            }

            // 再等待一小段时间
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            await MainActor.run {
                isReady = true
            }
        }
    }
}

/// 可拖动的下载进度浮窗
struct DraggableDownloadIndicator: View {
    @EnvironmentObject private var preloadService: WallpaperPreloadService
    @State private var position: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 80, y: 100)
    @State private var isDragging = false
    @State private var isExpanded = true

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .trailing, spacing: 4) {
                // 主体内容
                HStack(spacing: 10) {
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 4) {
                            // 状态消息
                            Text(preloadService.statusMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .foregroundColor(.primary)

                            // 下载进度
                            HStack(spacing: 4) {
                                Text("download.progress".localized)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(preloadService.downloadedCount)/\(preloadService.totalCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }

                            // 警告提示
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text("download.warning".localized)
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                        .frame(maxWidth: 150)
                    }

                    // 圆形进度
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: preloadService.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.3), value: preloadService.progress)

                        Text("\(Int(preloadService.progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, isExpanded ? 14 : 10)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                )
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.spring(response: 0.3), value: isDragging)
            }
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        // 限制在屏幕范围内
                        let newX = min(max(value.location.x, 60), geometry.size.width - 60)
                        let newY = min(max(value.location.y, 80), geometry.size.height - 80)
                        position = CGPoint(x: newX, y: newY)
                    }
                    .onEnded { _ in
                        isDragging = false
                        // 吸附到边缘
                        withAnimation(.spring(response: 0.4)) {
                            if position.x < geometry.size.width / 2 {
                                position.x = 80
                            } else {
                                position.x = geometry.size.width - 80
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
            .onAppear {
                // 初始位置在右上角
                position = CGPoint(x: geometry.size.width - 80, y: 120)
            }
        }
    }
}

#Preview {
    ContentView()
}
