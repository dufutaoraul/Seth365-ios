//
//  SettingsView.swift
//  Seth365
//
//  设置页面（简化版）
//

import SwiftUI
import PhotosUI

/// 设置页面
struct SettingsView: View {
    @ObservedObject private var userDefaults = UserDefaultsManager.shared
    @EnvironmentObject private var preloadService: WallpaperPreloadService
    @StateObject private var updateService = AppUpdateService.shared
    @State private var showShortcutsGuide = false
    @State private var showQRCodePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var userQRCode: UIImage? = QRCodeStorage.shared.getUserQRCode()
    @State private var showDeleteQRCodeAlert = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 壁纸偏好
                Section {
                    // 语言选择（三选项）
                    languagePicker

                    // 方向选择（三选项）
                    orientationPicker

                    // 显示模式
                    displayModePicker
                } header: {
                    Text("壁纸偏好")
                } footer: {
                    Text("选择「全部」可同时显示中英文或横竖版壁纸")
                }

                // MARK: - 我的二维码
                Section {
                    qrCodeRow

                    // 选择/更换按钮
                    Button(action: { showQRCodePicker = true }) {
                        Label(userQRCode != nil ? "更换二维码" : "选择二维码图片", systemImage: "photo.on.rectangle")
                    }

                    // 删除按钮
                    if userQRCode != nil {
                        Button(role: .destructive, action: { showDeleteQRCodeAlert = true }) {
                            Label("删除二维码", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("我的二维码")
                } footer: {
                    Text("用于生成带二维码的海报分享")
                }

                // MARK: - 自动换壁纸
                Section {
                    Button(action: { showShortcutsGuide = true }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                            Text("设置自动换壁纸")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("快捷指令")
                } footer: {
                    Text("通过 iOS 快捷指令实现每天自动更换壁纸")
                }

                // MARK: - 版本更新
                Section {
                    // 当前版本
                    HStack {
                        Text("当前版本")
                        Spacer()
                        Text(AppInfo.version)
                            .foregroundColor(.secondary)
                    }

                    // 最新版本（如果有）
                    if let latestVersion = updateService.latestVersion {
                        HStack {
                            Text("最新版本")
                            Spacer()
                            HStack(spacing: 4) {
                                Text(latestVersion)
                                if updateService.hasUpdate {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .foregroundColor(updateService.hasUpdate ? .green : .secondary)
                        }
                    }

                    // 检查更新按钮
                    Button(action: {
                        Task {
                            await updateService.checkForUpdate()
                        }
                    }) {
                        HStack {
                            if updateService.isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在检查...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("检查更新")
                            }
                            Spacer()
                            if let lastCheck = updateService.lastCheckTime {
                                Text(formatLastCheckTime(lastCheck))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(updateService.isChecking)

                    // 如果有新版本，显示更新按钮
                    if updateService.hasUpdate {
                        Button(action: {
                            updateService.openAppStore()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.app.fill")
                                    .foregroundColor(.white)
                                Text("前往 App Store 更新")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .listRowBackground(Color.clear)
                    }

                    // 错误信息
                    if let error = updateService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("版本更新")
                } footer: {
                    if updateService.hasUpdate {
                        Text("发现新版本，建议更新以获得最佳体验")
                    } else if updateService.latestVersion != nil {
                        Text("当前已是最新版本")
                    }
                }

                // MARK: - 关于
                Section {
                    HStack {
                        Text("壁纸周期")
                        Spacer()
                        Text("2025.12.21 - 2026.12.31")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("每日壁纸数")
                        Spacer()
                        Text("8张")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("内置壁纸")
                        Spacer()
                        Text("\(AppInfo.totalBundledWallpapers)张")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("关于")
                }

                // MARK: - 调试
                Section {
                    NavigationLink(destination: DebugLogView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.orange)
                            Text("运行日志")
                            Spacer()
                            if DebugLogService.shared.recentErrors().count > 0 {
                                Text("\(DebugLogService.shared.recentErrors().count) 个错误")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("调试")
                } footer: {
                    Text("查看 App 运行日志，用于排查自动化等问题")
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showShortcutsGuide) {
                ShortcutsGuideView()
            }
            .photosPicker(
                isPresented: $showQRCodePicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .onChange(of: selectedPhotoItem) { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        QRCodeStorage.shared.saveUserQRCode(image)
                        userQRCode = image
                    }
                }
            }
            .alert("删除二维码", isPresented: $showDeleteQRCodeAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    QRCodeStorage.shared.deleteUserQRCode()
                    userQRCode = nil
                }
            } message: {
                Text("确定要删除已保存的二维码吗？")
            }
        }
    }

    // MARK: - 语言选择器

    private var languagePicker: some View {
        Picker("语言", selection: $userDefaults.preferredLanguage) {
            Text("全部").tag(nil as WallpaperLanguage?)
            Text("中文").tag(WallpaperLanguage.chinese as WallpaperLanguage?)
            Text("English").tag(WallpaperLanguage.english as WallpaperLanguage?)
        }
    }

    // MARK: - 方向选择器

    private var orientationPicker: some View {
        Picker("方向", selection: $userDefaults.preferredOrientation) {
            Text("全部").tag(nil as WallpaperOrientation?)
            Text("竖版").tag(WallpaperOrientation.portrait as WallpaperOrientation?)
            Text("横版").tag(WallpaperOrientation.landscape as WallpaperOrientation?)
        }
    }

    // MARK: - 显示模式选择器

    private var displayModePicker: some View {
        Picker("显示模式", selection: $userDefaults.displayMode) {
            ForEach(WallpaperDisplayMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
    }

    // MARK: - 时间格式化

    private func formatLastCheckTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - 二维码行

    private var qrCodeRow: some View {
        HStack {
            // 二维码预览
            if let qrCode = userQRCode {
                Image(uiImage: qrCode)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.title3)
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(userQRCode != nil ? "已设置" : "未设置")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WallpaperPreloadService.shared)
}
