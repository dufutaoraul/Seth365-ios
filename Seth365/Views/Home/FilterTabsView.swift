//
//  FilterTabsView.swift
//  Seth365
//
//  壁纸筛选标签组件
//

import SwiftUI

/// 壁纸筛选标签组件
struct FilterTabsView: View {
    @Binding var selectedLanguage: WallpaperLanguage?
    @Binding var selectedOrientation: WallpaperOrientation?

    var body: some View {
        VStack(spacing: 8) {
            // 语言筛选
            HStack(spacing: 8) {
                HomeFilterChip(
                    title: "common.all".localized,
                    isSelected: selectedLanguage == nil,
                    action: { selectedLanguage = nil }
                )
                HomeFilterChip(
                    title: "language.chinese".localized,
                    isSelected: selectedLanguage == .chinese,
                    action: { selectedLanguage = .chinese }
                )
                HomeFilterChip(
                    title: "language.english".localized,
                    isSelected: selectedLanguage == .english,
                    action: { selectedLanguage = .english }
                )

                Spacer()

                // 方向筛选
                HomeFilterChip(
                    title: "orientation.portrait".localized,
                    isSelected: selectedOrientation == .portrait,
                    action: {
                        selectedOrientation = selectedOrientation == .portrait ? nil : .portrait
                    }
                )
                HomeFilterChip(
                    title: "orientation.landscape".localized,
                    isSelected: selectedOrientation == .landscape,
                    action: {
                        selectedOrientation = selectedOrientation == .landscape ? nil : .landscape
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

/// 首页筛选标签按钮
struct HomeFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    /// 根据设备类型返回合适的字体
    private var chipFont: Font {
        UIDevice.current.userInterfaceIdiom == .pad ? .subheadline : .caption
    }

    /// 根据设备类型返回合适的水平 padding
    private var horizontalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 18 : 14
    }

    /// 根据设备类型返回合适的垂直 padding
    private var verticalPadding: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(chipFont)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                )
        }
        .frame(minHeight: 44) // 确保最小触摸区域
    }
}

#Preview {
    FilterTabsView(
        selectedLanguage: .constant(nil),
        selectedOrientation: .constant(nil)
    )
}
