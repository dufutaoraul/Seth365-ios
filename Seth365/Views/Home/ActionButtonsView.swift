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
    var onSetWallpaper: (() -> Void)?

    /// 根据设备类型返回合适的按钮高度
    private var buttonHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 52 : 44
    }

    /// 根据设备类型返回合适的字体
    private var buttonFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .body.weight(.semibold) : .subheadline.weight(.semibold)
    }

    /// 根据设备类型返回合适的圆角
    private var buttonCornerRadius: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10
    }

    var body: some View {
        VStack(spacing: 12) {
            // 第一行：保存和海报按钮
            HStack(spacing: 12) {
                // 保存按钮
                Button(action: onSave) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("wallpaper.detail.save".localized)
                    }
                    .font(buttonFont)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(Color.blue)
                    .cornerRadius(buttonCornerRadius)
                }
                .disabled(wallpaper == nil)

                // 生成海报按钮
                Button(action: onPoster) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.richtext")
                        Text("wallpaper.detail.poster".localized)
                    }
                    .font(buttonFont)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(buttonCornerRadius)
                }
                .disabled(wallpaper == nil)
            }

            // 第二行：设置壁纸按钮
            if let onSetWallpaper = onSetWallpaper {
                Button(action: onSetWallpaper) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                        Text("wallpaper.save.go_set".localized)
                    }
                    .font(buttonFont)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(buttonCornerRadius)
                }
                .disabled(wallpaper == nil)
            }
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

    /// 根据设备类型返回合适的图标字体
    private var iconFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .caption : .caption2
    }

    /// 根据设备类型返回合适的文字字体
    private var textFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .subheadline : .caption
    }

    /// 根据设备类型返回合适的 padding
    private var horizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 8
    }

    private var verticalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 8 : 4
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(iconFont)
            Text(text)
                .font(textFont)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
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
            onPoster: {},
            onSetWallpaper: {}
        )
    }
}
