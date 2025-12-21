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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 70)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 70)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                }

                // 选中标识
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 50, height: 70)
                }
            }
            .cornerRadius(6)
        }
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
