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
                    Text("settings.preferences".localized)
                } footer: {
                    Text("settings.preferences.hint".localized)
                }

                // MARK: - 我的二维码
                Section {
                    qrCodeRow

                    // 选择/更换按钮
                    Button(action: { showQRCodePicker = true }) {
                        Label(userQRCode != nil ? "settings.qr.change".localized : "settings.qr.select".localized, systemImage: "photo.on.rectangle")
                    }

                    // 删除按钮
                    if userQRCode != nil {
                        Button(role: .destructive, action: { showDeleteQRCodeAlert = true }) {
                            Label("settings.qr.delete".localized, systemImage: "trash")
                        }
                    }
                } header: {
                    Text("settings.my_qr".localized)
                } footer: {
                    Text("settings.qr.hint".localized)
                }

                // MARK: - 自动换壁纸
                Section {
                    Button(action: { showShortcutsGuide = true }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.blue)
                            Text("settings.auto.shortcuts".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("settings.shortcuts".localized)
                } footer: {
                    Text("settings.shortcuts.hint".localized)
                }

                // MARK: - 版本更新
                Section {
                    // 当前版本
                    HStack {
                        Text("settings.version.current".localized)
                        Spacer()
                        Text(AppInfo.version)
                            .foregroundColor(.secondary)
                    }

                    // 最新版本（如果有）
                    if let latestVersion = updateService.latestVersion {
                        HStack {
                            Text("settings.version.latest".localized)
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
                                Text("settings.version.checking".localized)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("settings.version.check".localized)
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
                                Text("settings.version.go_update".localized)
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
                    Text("settings.version".localized)
                } footer: {
                    if updateService.hasUpdate {
                        Text("settings.version.update_available".localized)
                    } else if updateService.latestVersion != nil {
                        Text("settings.version.up_to_date".localized)
                    }
                }

                // MARK: - 关于
                Section {
                    HStack {
                        Text("settings.about.period".localized)
                        Spacer()
                        Text("2025.12.21 - 2026.12.31")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("settings.about.daily_count".localized)
                        Spacer()
                        Text("settings.about.daily_count_value".localized)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("settings.about.bundled".localized)
                        Spacer()
                        Text(String(format: "settings.about.bundled_value".localized, AppInfo.totalBundledWallpapers))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("settings.about".localized)
                }

                // MARK: - 调试
                Section {
                    NavigationLink(destination: DebugLogView()) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.orange)
                            Text("settings.debug.logs".localized)
                            Spacer()
                            if DebugLogService.shared.recentErrors().count > 0 {
                                Text(String(format: "settings.debug.errors".localized, DebugLogService.shared.recentErrors().count))
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("settings.debug".localized)
                } footer: {
                    Text("settings.debug.hint".localized)
                }
            }
            .navigationTitle("settings.title".localized)
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
            .alert("settings.qr.delete.title".localized, isPresented: $showDeleteQRCodeAlert) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.delete".localized, role: .destructive) {
                    QRCodeStorage.shared.deleteUserQRCode()
                    userQRCode = nil
                }
            } message: {
                Text("settings.qr.delete.message".localized)
            }
        }
    }

    // MARK: - 语言选择器

    private var languagePicker: some View {
        Picker("settings.language".localized, selection: $userDefaults.preferredLanguage) {
            Text("common.all".localized).tag(nil as WallpaperLanguage?)
            Text("language.chinese".localized).tag(WallpaperLanguage.chinese as WallpaperLanguage?)
            Text("language.english".localized).tag(WallpaperLanguage.english as WallpaperLanguage?)
        }
    }

    // MARK: - 方向选择器

    private var orientationPicker: some View {
        Picker("settings.orientation".localized, selection: $userDefaults.preferredOrientation) {
            Text("common.all".localized).tag(nil as WallpaperOrientation?)
            Text("orientation.portrait".localized).tag(WallpaperOrientation.portrait as WallpaperOrientation?)
            Text("orientation.landscape".localized).tag(WallpaperOrientation.landscape as WallpaperOrientation?)
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
        formatter.locale = Locale.current
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
                Text(userQRCode != nil ? "settings.qr.set".localized : "settings.qr.not_set".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}
