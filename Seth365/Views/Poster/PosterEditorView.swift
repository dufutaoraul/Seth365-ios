//
//  PosterEditorView.swift
//  Seth365
//
//  海报编辑器视图
//

import SwiftUI
import Photos
import PhotosUI

/// 海报编辑器视图
struct PosterEditorView: View {
    let wallpaperImage: UIImage

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PosterViewModel()

    // 边框调整状态
    @State private var frameRect: CGRect = .zero      // 红色边框位置（显示坐标系）
    @State private var frameScale: CGFloat = 1.0     // 缩放比例
    @State private var lastFrameRect: CGRect = .zero // 上次拖动前的位置
    @State private var isFrameInitialized = false    // 标记是否已初始化

    // UI状态
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var showPermissionDeniedAlert = false  // 权限被拒绝的专用弹窗
    @State private var showNoQRCodeAlert = false
    @State private var isSaving = false
    @State private var showQRCodePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // 显示相关
    @State private var displayScale: CGFloat = 1.0   // 图片显示缩放比例
    @State private var imageDisplaySize: CGSize = .zero
    @State private var imageDisplayOrigin: CGPoint = .zero
    @State private var containerSize: CGSize = .zero // 容器尺寸

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 预览区域
                    ZStack {
                        Color.black

                        if let wallpaper = viewModel.originalWallpaper {
                            // 计算显示尺寸
                            let containerSize = CGSize(
                                width: geometry.size.width,
                                height: geometry.size.height - 240 // 减去底部控制区高度
                            )

                            let scale = min(
                                containerSize.width / wallpaper.size.width,
                                containerSize.height / wallpaper.size.height
                            ) * 0.9

                            let displaySize = CGSize(
                                width: wallpaper.size.width * scale,
                                height: wallpaper.size.height * scale
                            )

                            let imageOrigin = CGPoint(
                                x: (containerSize.width - displaySize.width) / 2,
                                y: (containerSize.height - displaySize.height) / 2
                            )

                            ZStack {
                                // 壁纸
                                Image(uiImage: wallpaper)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: displaySize.width, height: displaySize.height)

                                // 可调整的红色边框（只有在初始化后才显示）
                                if isFrameInitialized {
                                    adjustableFrameView(
                                        displaySize: displaySize,
                                        scale: scale,
                                        containerSize: containerSize
                                    )
                                }
                            }
                            .onAppear {
                                displayScale = scale
                                imageDisplaySize = displaySize
                                imageDisplayOrigin = imageOrigin
                                self.containerSize = containerSize
                            }
                        }

                        // 检测中指示器
                        if viewModel.isDetecting {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("正在检测二维码位置...")
                                    .font(.subheadline)
                            }
                            .padding(24)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                    }
                    .frame(height: geometry.size.height - 240)

                    // 底部控制区
                    controlArea
                        .frame(height: 240)
                }
            }
            .navigationTitle("生成我的海报")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("生成海报") {
                        generateAndSavePoster()
                    }
                    .disabled(viewModel.userQRCode == nil || isSaving)
                }
            }
            .task {
                await viewModel.setWallpaper(wallpaperImage)
                // 检测完成后初始化边框位置
                await MainActor.run {
                    if containerSize != .zero && imageDisplaySize != .zero {
                        initializeFrameRect(
                            scale: displayScale,
                            displaySize: imageDisplaySize,
                            containerSize: containerSize
                        )
                        isFrameInitialized = true
                    }
                }
            }
            // 当容器尺寸可用时，如果检测已完成则初始化边框
            .onChange(of: containerSize) { newContainerSize in
                if !isFrameInitialized && !viewModel.isDetecting && viewModel.originalWallpaper != nil {
                    initializeFrameRect(
                        scale: displayScale,
                        displaySize: imageDisplaySize,
                        containerSize: newContainerSize
                    )
                    isFrameInitialized = true
                }
            }
            .alert("保存成功", isPresented: $showSaveSuccess) {
                Button("好的") { dismiss() }
            } message: {
                Text("海报已保存到相册")
            }
            .alert("保存失败", isPresented: $showSaveError) {
                Button("确定") { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
            .alert("需要相册权限", isPresented: $showPermissionDeniedAlert) {
                Button("去设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请按以下步骤操作：\n\n1. 点击「照片」\n2. 选择「完全访问」或「添加照片」\n3. 返回 App 重试")
            }
            .alert("请先设置二维码", isPresented: $showNoQRCodeAlert) {
                Button("选择二维码图片") {
                    showQRCodePicker = true
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请选择你的二维码图片")
            }
            .photosPicker(isPresented: $showQRCodePicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.setUserQRCode(image)
                    }
                }
            }
        }
    }

    // MARK: - 可调整的红色边框

    @ViewBuilder
    private func adjustableFrameView(displaySize: CGSize, scale: CGFloat, containerSize: CGSize) -> some View {
        let imageOrigin = CGPoint(
            x: (containerSize.width - displaySize.width) / 2,
            y: (containerSize.height - displaySize.height) / 2
        )

        ZStack {
            // 如果有用户二维码，显示预览
            if let userQR = viewModel.userQRCode {
                Image(uiImage: userQR)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: frameRect.width, height: frameRect.height)
                    .clipped()
                    .opacity(0.8)
                    .position(
                        x: frameRect.midX,
                        y: frameRect.midY
                    )
            }

            // 红色边框
            Rectangle()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: frameRect.width, height: frameRect.height)
                .position(
                    x: frameRect.midX,
                    y: frameRect.midY
                )

            // 四个角的拖动手柄（小一点）
            ForEach(corners, id: \.self) { corner in
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .position(cornerPosition(corner))
            }
        }
        .contentShape(Rectangle())
        // 拖动手势 - 移动边框
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newX = lastFrameRect.midX + value.translation.width
                    let newY = lastFrameRect.midY + value.translation.height

                    // 限制在图片范围内
                    let halfWidth = frameRect.width / 2
                    let halfHeight = frameRect.height / 2

                    let minX = imageOrigin.x + halfWidth
                    let maxX = imageOrigin.x + displaySize.width - halfWidth
                    let minY = imageOrigin.y + halfHeight
                    let maxY = imageOrigin.y + displaySize.height - halfHeight

                    let clampedX = max(minX, min(maxX, newX))
                    let clampedY = max(minY, min(maxY, newY))

                    frameRect = CGRect(
                        x: clampedX - halfWidth,
                        y: clampedY - halfHeight,
                        width: frameRect.width,
                        height: frameRect.height
                    )
                }
                .onEnded { _ in
                    lastFrameRect = frameRect
                    updateViewModelPosition(scale: scale, imageOrigin: imageOrigin)
                }
        )
        // 缩放手势 - 调整大小（无限制，用户可自由调整）
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let newScale = frameScale * value
                    // 移除缩放比例限制，允许用户自由调整

                    let baseSize = viewModel.detectedQRSize
                    let newWidth = baseSize.width * displayScale * newScale
                    let newHeight = baseSize.height * displayScale * newScale

                    // 只保留最小尺寸限制（防止太小无法操作）
                    let minSize: CGFloat = 30
                    let finalWidth = max(minSize, newWidth)
                    let finalHeight = max(minSize, newHeight)

                    frameRect = CGRect(
                        x: frameRect.midX - finalWidth / 2,
                        y: frameRect.midY - finalHeight / 2,
                        width: finalWidth,
                        height: finalHeight
                    )
                }
                .onEnded { value in
                    frameScale *= value
                    // 移除缩放比例限制
                    lastFrameRect = frameRect
                    updateViewModelPosition(scale: scale, imageOrigin: imageOrigin)
                }
        )
    }

    private var corners: [Corner] {
        [.topLeft, .topRight, .bottomLeft, .bottomRight]
    }

    private enum Corner: Hashable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func cornerPosition(_ corner: Corner) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: frameRect.minX, y: frameRect.minY)
        case .topRight:
            return CGPoint(x: frameRect.maxX, y: frameRect.minY)
        case .bottomLeft:
            return CGPoint(x: frameRect.minX, y: frameRect.maxY)
        case .bottomRight:
            return CGPoint(x: frameRect.maxX, y: frameRect.maxY)
        }
    }

    // MARK: - 初始化边框位置

    private func initializeFrameRect(scale: CGFloat, displaySize: CGSize, containerSize: CGSize) {
        let imageOrigin = CGPoint(
            x: (containerSize.width - displaySize.width) / 2,
            y: (containerSize.height - displaySize.height) / 2
        )

        // 使用检测到的位置或默认位置
        let qrRect = viewModel.adjustedQRPosition
        let displayRect = CGRect(
            x: imageOrigin.x + qrRect.origin.x * scale,
            y: imageOrigin.y + qrRect.origin.y * scale,
            width: qrRect.width * scale,
            height: qrRect.height * scale
        )

        frameRect = displayRect
        lastFrameRect = displayRect
    }

    // MARK: - 更新ViewModel位置

    private func updateViewModelPosition(scale: CGFloat, imageOrigin: CGPoint) {
        // 转换回原始图片坐标
        let originalRect = CGRect(
            x: (frameRect.origin.x - imageOrigin.x) / scale,
            y: (frameRect.origin.y - imageOrigin.y) / scale,
            width: frameRect.width / scale,
            height: frameRect.height / scale
        )
        viewModel.updateQRPosition(originalRect)
    }

    // MARK: - 控制区域

    private var controlArea: some View {
        VStack(spacing: 12) {
            // 二维码状态
            HStack {
                if let qrCode = viewModel.userQRCode {
                    Image(uiImage: qrCode)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 2)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("已设置二维码")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("拖动红框调整位置，捏合调整大小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: { showQRCodePicker = true }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "qrcode")
                                        .foregroundColor(.gray)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("未设置二维码")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                HStack(spacing: 4) {
                                    Text("点击上传二维码")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal)

            // 检测状态提示
            HStack {
                if viewModel.hasDetectedQRCode {
                    Label("已识别到原图二维码位置", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if !viewModel.isDetecting {
                    Label("未识别到二维码，使用默认位置", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
            }
            .padding(.horizontal)

            // 操作提示
            Text("提示：拖动移动位置 | 双指捏合调整大小")
                .font(.caption2)
                .foregroundColor(.secondary)

            // 生成海报按钮
            Button(action: generateAndSavePoster) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "photo.badge.plus")
                    }
                    Text("生成海报")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.userQRCode != nil ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.userQRCode == nil || isSaving)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 12)
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - 生成并保存海报

    private func generateAndSavePoster() {
        guard viewModel.userQRCode != nil else {
            showNoQRCodeAlert = true
            return
        }

        // 先生成海报
        guard let poster = viewModel.generatePoster() else {
            viewModel.errorMessage = "生成海报失败"
            showSaveError = true
            return
        }

        isSaving = true

        // 检查相册权限并保存
        Task {
            await saveImageToPhotos(poster)
        }
    }

    /// 保存图片到相册（带权限检查）
    private func saveImageToPhotos(_ image: UIImage) async {
        // 检查当前权限状态
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .notDetermined:
            // 请求权限
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if granted == .authorized || granted == .limited {
                await performSave(image)
            } else {
                await MainActor.run {
                    isSaving = false
                    showPermissionDeniedAlert = true
                }
            }

        case .authorized, .limited:
            await performSave(image)

        case .denied, .restricted:
            await MainActor.run {
                isSaving = false
                showPermissionDeniedAlert = true
            }

        @unknown default:
            await MainActor.run {
                isSaving = false
                viewModel.errorMessage = "无法确定相册权限状态"
                showSaveError = true
            }
        }
    }

    /// 执行实际的保存操作
    private func performSave(_ image: UIImage) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            await MainActor.run {
                isSaving = false
                showSaveSuccess = true
            }
        } catch let error as NSError {
            await MainActor.run {
                isSaving = false

                // 根据错误码提供更好的提示
                if error.domain == "PHPhotosErrorDomain" {
                    switch error.code {
                    case 3301:
                        // 权限受限或照片库不可用
                        showPermissionDeniedAlert = true
                    case 3300:
                        // 用户取消
                        viewModel.errorMessage = "操作已取消"
                        showSaveError = true
                    default:
                        viewModel.errorMessage = "保存失败（错误码：\(error.code)）\n请检查相册权限设置"
                        showSaveError = true
                    }
                } else {
                    viewModel.errorMessage = "保存失败：\(error.localizedDescription)"
                    showSaveError = true
                }
            }
        }
    }
}

#Preview {
    PosterEditorView(wallpaperImage: UIImage(systemName: "photo")!)
}
