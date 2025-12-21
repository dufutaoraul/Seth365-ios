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
    var onTap: (() -> Void)?
    @ObservedObject private var userDefaults = UserDefaultsManager.shared

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                WallpaperImageView(wallpaper: wallpaper, onTap: onTap)
                    .tag(index)
                    // 当显示模式改变时强制重新渲染
                    .id("\(wallpaper.id)_\(userDefaults.displayMode.rawValue)")
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: .infinity)
    }
}

/// 单张壁纸图片视图
struct WallpaperImageView: View {
    let wallpaper: Wallpaper
    var onTap: (() -> Void)?
    @State private var image: UIImage?
    @State private var isLoading = true
    @ObservedObject private var userDefaults = UserDefaultsManager.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色（根据显示模式）
                backgroundColor
                    .ignoresSafeArea()

                if let image = image {
                    // 根据方向决定是否旋转
                    if wallpaper.orientation == .landscape {
                        // 横版壁纸旋转90度显示
                        displayModeView(for: image, geometry: geometry, isLandscape: true)
                            .onTapGesture {
                                onTap?()
                            }
                    } else {
                        // 竖版壁纸正常显示
                        displayModeView(for: image, geometry: geometry, isLandscape: false)
                            .onTapGesture {
                                onTap?()
                            }
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

    /// 背景色
    private var backgroundColor: Color {
        switch userDefaults.displayMode {
        case .fitBlack:
            return .black
        case .fitWhite:
            return .white
        default:
            return .black
        }
    }

    /// 根据显示模式渲染图片
    @ViewBuilder
    private func displayModeView(for image: UIImage, geometry: GeometryProxy, isLandscape: Bool) -> some View {
        let displayMode = userDefaults.displayMode

        switch displayMode {
        case .fitBlack, .fitWhite:
            // 适配模式：完整显示图片
            if isLandscape {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(90))
                    .frame(width: geometry.size.height, height: geometry.size.width)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .stretch:
            // 拉伸模式：铺满全屏
            if isLandscape {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .rotationEffect(.degrees(90))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }

        case .cropCenter:
            // 裁切居中模式
            if isLandscape {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .rotationEffect(.degrees(90))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }

        case .cropTop:
            // 裁切顶部模式
            if isLandscape {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .rotationEffect(.degrees(90))
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .clipped()
            } else {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                    .clipped()
            }

        case .blurBackground:
            // 模糊背景模式
            ZStack {
                // 模糊背景
                if isLandscape {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .rotationEffect(.degrees(90))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 30)
                        .scaleEffect(1.1)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 30)
                        .scaleEffect(1.1)
                }

                // 前景图片
                if isLandscape {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(.degrees(90))
                        .frame(width: geometry.size.height, height: geometry.size.width)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
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
        currentIndex: .constant(0),
        onTap: nil
    )
}
