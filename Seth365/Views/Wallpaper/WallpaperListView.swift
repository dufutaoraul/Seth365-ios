//
//  WallpaperListView.swift
//  Seth365
//
//  壁纸列表视图
//

import SwiftUI

/// 壁纸列表视图
struct WallpaperListView: View {
    let date: Date
    @StateObject private var viewModel: WallpaperViewModel
    @State private var selectedWallpaper: Wallpaper?

    /// 网格列定义
    private let columns = [
        GridItem(.flexible(), spacing: Constants.UI.cardSpacing),
        GridItem(.flexible(), spacing: Constants.UI.cardSpacing)
    ]

    init(date: Date) {
        self.date = date
        _viewModel = StateObject(wrappedValue: WallpaperViewModel(date: date))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            filterBar

            // 壁纸网格
            ScrollView {
                LazyVGrid(columns: columns, spacing: Constants.UI.cardSpacing) {
                    ForEach(viewModel.filteredWallpapers) { wallpaper in
                        WallpaperCard(
                            wallpaper: wallpaper,
                            image: viewModel.getImage(for: wallpaper),
                            isLoading: viewModel.isLoading(wallpaper),
                            onTap: {
                                selectedWallpaper = wallpaper
                            }
                        )
                        .task {
                            await viewModel.loadImage(for: wallpaper)
                        }
                    }
                }
                .padding(Constants.UI.padding)
            }
        }
        .navigationTitle(viewModel.dateDisplayText)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
                image: viewModel.getImage(for: wallpaper)
            )
        }
        .alert("提示", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// 筛选栏
    private var filterBar: some View {
        HStack(spacing: 12) {
            // 语言筛选
            Menu {
                Button("全部") {
                    viewModel.selectedLanguage = nil
                }
                ForEach(WallpaperLanguage.allCases) { language in
                    Button(language.displayName) {
                        viewModel.selectedLanguage = language
                    }
                }
            } label: {
                FilterChip(
                    title: viewModel.selectedLanguage?.displayName ?? "语言",
                    isSelected: viewModel.selectedLanguage != nil
                )
            }

            // 方向筛选
            Menu {
                Button("全部") {
                    viewModel.selectedOrientation = nil
                }
                ForEach(WallpaperOrientation.allCases) { orientation in
                    Button(orientation.displayName) {
                        viewModel.selectedOrientation = orientation
                    }
                }
            } label: {
                FilterChip(
                    title: viewModel.selectedOrientation?.displayName ?? "方向",
                    isSelected: viewModel.selectedOrientation != nil
                )
            }

            Spacer()

            // 重置按钮
            if viewModel.selectedLanguage != nil || viewModel.selectedOrientation != nil {
                Button("重置") {
                    viewModel.resetFilter()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, Constants.UI.padding)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
    }
}

/// 筛选标签组件
struct FilterChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Constants.Colors.primary : Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        WallpaperListView(date: Date())
    }
}
