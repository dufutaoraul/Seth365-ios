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
        }
        .onChange(of: isReady) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
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

#Preview {
    ContentView()
}
