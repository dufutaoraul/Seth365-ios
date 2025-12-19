//
//  WallpaperDetailView.swift
//  Seth365
//
//  壁纸详情视图（全屏预览）
//

import SwiftUI
import Photos

/// 壁纸详情视图
struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    let image: UIImage?

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showPosterEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 图片区域
                ZStack {
                    // 背景
                    Color.black

                    // 图片
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = value
                                    }
                                    .onEnded { _ in
                                        withAnimation {
                                            scale = max(1.0, min(scale, 3.0))
                                        }
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    scale = scale > 1.0 ? 1.0 : 2.0
                                }
                            }
                    } else {
                        // 无图片占位
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("图片未加载")
                                .foregroundColor(.gray)
                        }
                    }
                }

                // 底部操作栏
                if image != nil {
                    HStack(spacing: 0) {
                        // 保存按钮
                        Button(action: saveToPhotos) {
                            VStack(spacing: 4) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                }
                                Text("保存")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .disabled(isSaving)
                        .foregroundColor(.white)

                        // 分隔线
                        Divider()
                            .background(Color.gray)
                            .frame(height: 40)

                        // 生成海报按钮
                        Button(action: { showPosterEditor = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title2)
                                Text("生成海报")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .foregroundColor(.white)
                    }
                    .background(Color.black.opacity(0.9))
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(wallpaper.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("好的") { }
            Button("去设置壁纸") {
                openPhotosApp()
            }
        } message: {
            Text("图片已保存到相册。\n\n设置壁纸方法：\n1. 打开「照片」App\n2. 找到刚保存的图片\n3. 点击分享按钮\n4. 选择「用作壁纸」")
        }
        .alert("保存失败", isPresented: $showSaveError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPosterEditor) {
            if let image = image {
                PosterEditorView(wallpaperImage: image)
            }
        }
    }

    /// 保存到相册
    private func saveToPhotos() {
        guard let image = image else { return }

        isSaving = true

        // 检查权限
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            performSave(image: image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        performSave(image: image)
                    } else {
                        isSaving = false
                        errorMessage = "需要相册权限才能保存图片。请在「设置」中开启相册权限。"
                        showSaveError = true
                    }
                }
            }
        case .denied, .restricted:
            isSaving = false
            errorMessage = "需要相册权限才能保存图片。请在「设置 > 隐私 > 照片」中开启权限。"
            showSaveError = true
        @unknown default:
            isSaving = false
            errorMessage = "未知的权限状态"
            showSaveError = true
        }
    }

    /// 执行保存
    private func performSave(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.forAsset().addResource(
                with: .photo,
                data: image.pngData() ?? Data(),
                options: nil
            )
        }) { success, error in
            DispatchQueue.main.async {
                isSaving = false
                if success {
                    showSaveSuccess = true
                } else {
                    errorMessage = error?.localizedDescription ?? "保存失败"
                    showSaveError = true
                }
            }
        }
    }

    /// 打开照片 App
    private func openPhotosApp() {
        if let url = URL(string: "photos-redirect://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    let wallpaper = Wallpaper(
        date: Date(),
        language: .chinese,
        orientation: .portrait,
        index: 1
    )

    return WallpaperDetailView(wallpaper: wallpaper, image: nil)
}
