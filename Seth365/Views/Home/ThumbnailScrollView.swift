//
//  ThumbnailScrollView.swift
//  Seth365
//
//  壁纸缩略图滚动条组件
//

import SwiftUI

/// 壁纸缩略图滚动条组件
struct ThumbnailScrollView: View {
    let wallpapers: [Wallpaper]
    @Binding var currentIndex: Int

    /// 根据设备类型返回合适的间距
    private var itemSpacing: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 8
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: itemSpacing) {
                    ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                        ThumbnailItem(
                            wallpaper: wallpaper,
                            isSelected: index == currentIndex,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentIndex = index
                                }
                            }
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}

/// 单个缩略图项
struct ThumbnailItem: View {
    let wallpaper: Wallpaper
    let isSelected: Bool
    let onTap: () -> Void

    @State private var image: UIImage?

    /// 根据设备类型返回合适的缩略图宽度
    private var thumbnailWidth: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 70 : 50
    }

    /// 根据设备类型返回合适的缩略图高度
    private var thumbnailHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 98 : 70
    }

    /// 根据设备类型返回合适的圆角
    private var cornerRadius: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 8 : 6
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                }

                // 选中标识
                if isSelected {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                }
            }
            .cornerRadius(cornerRadius)
            .contentShape(Rectangle()) // 确保整个缩略图区域可点击
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 44, minHeight: 44) // 确保最小触摸区域
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        Task {
            do {
                let loadedImage = try await ImageCacheService.shared.getOrDownloadImage(for: wallpaper)
                await MainActor.run {
                    self.image = loadedImage
                }
            } catch {
                // 忽略错误
            }
        }
    }
}

#Preview {
    ThumbnailScrollView(
        wallpapers: Wallpaper.allWallpapers(for: Date()),
        currentIndex: .constant(0)
    )
}
