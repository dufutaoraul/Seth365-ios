//
//  WallpaperPageView.swift
//  Seth365
//
//  壁纸大图轮播组件
//

import SwiftUI

/// 壁纸大图轮播组件
struct WallpaperPageView: View {
    let wallpapers: [Wallpaper]
    @Binding var currentIndex: Int

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                WallpaperImageView(wallpaper: wallpaper)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }
}

/// 单张壁纸图片视图
struct WallpaperImageView: View {
    let wallpaper: Wallpaper
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    // 根据方向决定是否旋转
                    if wallpaper.orientation == .landscape {
                        // 横版壁纸旋转90度显示
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(.degrees(90))
                            .frame(width: geometry.size.height, height: geometry.size.width)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        // 竖版壁纸正常显示
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("加载失败")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .padding(.horizontal, 16)
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        Task {
            do {
                let loadedImage = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

/// 壁纸标题视图
struct WallpaperTitleView: View {
    let date: Date

    var body: some View {
        HStack {
            Text(DateUtils.formatMonthDay(date) + "的壁纸")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    WallpaperPageView(
        wallpapers: Wallpaper.allWallpapers(for: Date()),
        currentIndex: .constant(0)
    )
}
