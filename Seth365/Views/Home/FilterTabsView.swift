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

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                )
        }
    }
}

#Preview {
    FilterTabsView(
        selectedLanguage: .constant(nil),
        selectedOrientation: .constant(nil)
    )
}
