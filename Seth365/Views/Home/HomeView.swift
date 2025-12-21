//
//  HomeView.swift
//  Seth365
//
//  首页视图（日历+轮播一体化）
//

import SwiftUI

/// 首页视图
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCalendar = true
    @State private var showDetailView = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 日期栏（带折叠按钮）
                DateHeaderView(
                    currentMonth: viewModel.currentMonth,
                    showCalendar: $showCalendar,
                    onPrevMonth: { viewModel.previousMonth() },
                    onNextMonth: { viewModel.nextMonth() },
                    canGoPrev: viewModel.canGoPrevious,
                    canGoNext: viewModel.canGoNext
                )

                // 可折叠日历
                if showCalendar {
                    CalendarGridView(
                        days: viewModel.currentMonthDays,
                        selectedDate: $viewModel.selectedDate,
                        onDateTap: { date in
                            viewModel.selectDate(date)
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 壁纸标题
                WallpaperTitleView(date: viewModel.selectedDate)
                    .padding(.top, 8)

                // 筛选标签
                FilterTabsView(
                    selectedLanguage: $viewModel.filterLanguage,
                    selectedOrientation: $viewModel.filterOrientation
                )
                .padding(.vertical, 8)

                // 大图轮播
                if viewModel.filteredWallpapers.isEmpty {
                    Spacer()
                    Text("暂无壁纸")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    WallpaperPageView(
                        wallpapers: viewModel.filteredWallpapers,
                        currentIndex: $viewModel.currentWallpaperIndex,
                        onTap: { showDetailView = true }
                    )

                    // 壁纸信息栏
                    WallpaperInfoBar(wallpaper: viewModel.currentWallpaper)

                    // 缩略图条
                    ThumbnailScrollView(
                        wallpapers: viewModel.filteredWallpapers,
                        currentIndex: $viewModel.currentWallpaperIndex
                    )
                    .padding(.vertical, 8)

                    // 操作按钮
                    ActionButtonsView(
                        wallpaper: viewModel.currentWallpaper,
                        onSave: { viewModel.saveCurrentWallpaper() },
                        onPoster: { viewModel.openPosterEditor() },
                        onSetWallpaper: { viewModel.openPhotosApp() }
                    )
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Seth365")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.3), value: showCalendar)
            .sheet(isPresented: $viewModel.showPosterEditor) {
                if let image = viewModel.posterImage {
                    PosterEditorView(wallpaperImage: image)
                }
            }
            .fullScreenCover(isPresented: $showDetailView) {
                if let wallpaper = viewModel.currentWallpaper {
                    WallpaperDetailView(
                        wallpaper: wallpaper,
                        image: viewModel.currentWallpaperImage
                    )
                }
            }
            .alert("calendar.alert.locked".localized, isPresented: $viewModel.showLockedAlert) {
                Button("calendar.alert.ok".localized) { }
            } message: {
                Text(viewModel.lockedAlertMessage)
            }
            .alert("calendar.alert.hint".localized, isPresented: $viewModel.showNavigationAlert) {
                Button("calendar.alert.gotit".localized) { }
            } message: {
                Text(viewModel.navigationAlertMessage)
            }
            .alert(viewModel.saveAlertTitle, isPresented: $viewModel.showSaveAlert) {
                if viewModel.saveAlertTitle == "wallpaper.save.success".localized {
                    Button("ok".localized) { }
                    Button("wallpaper.save.go_set".localized) {
                        viewModel.openPhotosApp()
                    }
                } else {
                    Button("ok".localized) { }
                }
            } message: {
                Text(viewModel.saveAlertMessage)
            }
        }
    }
}

#Preview {
    HomeView()
}
