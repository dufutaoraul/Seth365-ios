//
//  WallpaperCard.swift
//  Seth365
//
//  壁纸卡片组件
//

import SwiftUI

/// 壁纸卡片组件
struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let image: UIImage?
    let isLoading: Bool
    let onTap: () -> Void

    /// 根据设备类型返回合适的卡片高度
    private var cardHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad
            ? Constants.UI.wallpaperCardHeight * 1.3
            : Constants.UI.wallpaperCardHeight
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color.gray.opacity(0.1))

                if let image = image {
                    // 已加载的图片
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: cardHeight)
                        .clipped()
                        .cornerRadius(Constants.UI.cornerRadius)
                } else if isLoading {
                    // 加载中
                    ProgressView()
                        .scaleEffect(1.2)
                } else {
                    // 占位图标
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                }

                // 标签
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(wallpaper.shortDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(6)
                            .padding(8)
                    }
                }
            }
            .frame(height: cardHeight)
            .contentShape(Rectangle()) // 确保整个卡片区域可点击
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let wallpaper = Wallpaper(
        date: Date(),
        language: .chinese,
        orientation: .portrait,
        index: 1
    )

    return VStack(spacing: 16) {
        // 无图片
        WallpaperCard(
            wallpaper: wallpaper,
            image: nil,
            isLoading: false,
            onTap: {}
        )

        // 加载中
        WallpaperCard(
            wallpaper: wallpaper,
            image: nil,
            isLoading: true,
            onTap: {}
        )
    }
    .padding()
}
