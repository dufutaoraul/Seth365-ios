//
//  ContentView.swift
//  Seth365
//
//  Created by 刘文骏 on 2025/12/11.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var preloadService: WallpaperPreloadService

    var body: some View {
        ZStack {
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

            // 悬浮下载进度指示器（右上角）
            if preloadService.isLoading {
                VStack {
                    HStack {
                        Spacer()
                        DownloadProgressIndicator()
                            .environmentObject(preloadService)
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.trailing, 16)
            }
        }
    }
}

/// 悬浮下载进度指示器
struct DownloadProgressIndicator: View {
    @EnvironmentObject private var preloadService: WallpaperPreloadService
    @State private var isExpanded = true  // 默认展开

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // 主体
            HStack(spacing: 10) {
                if isExpanded {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(preloadService.statusMessage)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text("已下载")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(preloadService.downloadedCount)/\(preloadService.totalCount)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("请勿关闭App")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)

                    Circle()
                        .trim(from: 0, to: preloadService.progress)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: preloadService.progress)

                    Text("\(Int(preloadService.progress * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, isExpanded ? 14 : 8)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WallpaperPreloadService.shared)
}
