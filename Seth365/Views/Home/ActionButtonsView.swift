//
//  ActionButtonsView.swift
//  Seth365
//
//  壁纸操作按钮组件
//

import SwiftUI

/// 壁纸操作按钮组件
struct ActionButtonsView: View {
    let wallpaper: Wallpaper?
    let onSave: () -> Void
    let onPoster: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 保存按钮
            Button(action: onSave) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text("wallpaper.detail.save".localized)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(wallpaper == nil)

            // 生成海报按钮
            Button(action: onPoster) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.richtext")
                    Text("wallpaper.detail.poster".localized)
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(wallpaper == nil)
        }
        .padding(.horizontal)
    }
}

/// 壁纸信息栏（显示当前壁纸的类型信息）
struct WallpaperInfoBar: View {
    let wallpaper: Wallpaper?

    var body: some View {
        if let wallpaper = wallpaper {
            HStack {
                // 语言标签
                InfoTag(
                    icon: wallpaper.language == .chinese ? "character" : "a.circle",
                    text: wallpaper.language == .chinese ? "中文" : "English"
                )

                // 方向标签
                InfoTag(
                    icon: wallpaper.orientation == .portrait ? "rectangle.portrait" : "rectangle",
                    text: wallpaper.orientation == .portrait ? "竖版" : "横版"
                )

                // 序号标签
                InfoTag(
                    icon: "number",
                    text: "第\(wallpaper.index)张"
                )

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
}

/// 信息标签
struct InfoTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    VStack {
        WallpaperInfoBar(wallpaper: Wallpaper.allWallpapers(for: Date()).first)
        ActionButtonsView(
            wallpaper: Wallpaper.allWallpapers(for: Date()).first,
            onSave: {},
            onPoster: {}
        )
    }
}
