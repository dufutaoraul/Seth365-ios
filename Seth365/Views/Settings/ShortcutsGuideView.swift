//
//  ShortcutsGuideView.swift
//  Seth365
//
//  快捷指令配置引导（简洁易懂版）
//

import SwiftUI

/// 快捷指令配置引导页面
struct ShortcutsGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userDefaults = UserDefaultsManager.shared
    @State private var selectedSection: GuideSection = .setup

    enum GuideSection: String, CaseIterable {
        case setup = "配置步骤"
        case faq = "常见问题"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部重要提示
                    importantTip

                    // 壁纸偏好设置
                    preferencesSection

                    // 分段选择器
                    Picker("", selection: $selectedSection) {
                        ForEach(GuideSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // 内容区域
                    if selectedSection == .setup {
                        setupStepsSection
                    } else {
                        faqSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("自动换壁纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        userDefaults.hasSeenShortcutsGuide = true
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 重要提示

    private var importantTip: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 设备信息
            HStack(spacing: 6) {
                Image(systemName: "iphone")
                    .foregroundColor(.blue)
                Text("你的设备")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(DeviceInfo.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 模拟器警告
            if DeviceInfo.isSimulator {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("模拟器限制")
                        .fontWeight(.bold)
                }

                Text("你正在使用模拟器，「设定墙纸」功能在模拟器上不生效。请在真机上测试完整功能。")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("核心原理")
                        .fontWeight(.bold)
                }

                Text("使用 iOS「快捷指令」的自动化功能，让手机在指定时间或条件下自动更换壁纸。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DeviceInfo.isSimulator ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - 偏好设置

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("壁纸偏好")
                .font(.headline)
                .padding(.horizontal)

            // 日期范围
            VStack(alignment: .leading, spacing: 8) {
                Text("从哪些日期中随机选择")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(SwitchDateRange.quickSelectCases, id: \.self) { range in
                        rangeButton(range)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)

            // 语言和方向
            HStack(spacing: 12) {
                // 语言
                VStack(alignment: .leading, spacing: 4) {
                    Text("语言")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $userDefaults.preferredLanguage) {
                        Text("全部").tag(nil as WallpaperLanguage?)
                        Text("中文").tag(WallpaperLanguage.chinese as WallpaperLanguage?)
                        Text("English").tag(WallpaperLanguage.english as WallpaperLanguage?)
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)

                // 方向
                VStack(alignment: .leading, spacing: 4) {
                    Text("方向")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $userDefaults.preferredOrientation) {
                        Text("全部").tag(nil as WallpaperOrientation?)
                        Text("竖版").tag(WallpaperOrientation.portrait as WallpaperOrientation?)
                        Text("横版").tag(WallpaperOrientation.landscape as WallpaperOrientation?)
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    private func rangeButton(_ range: SwitchDateRange) -> some View {
        Button(action: { userDefaults.switchDateRange = range }) {
            Text(range.displayName)
                .font(.subheadline)
                .fontWeight(userDefaults.switchDateRange == range ? .semibold : .regular)
                .foregroundColor(userDefaults.switchDateRange == range ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(userDefaults.switchDateRange == range ? Color.blue : Color.gray.opacity(0.15))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 配置步骤

    private var setupStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 步骤1
            stepView(1, "打开「快捷指令」App", "在手机上找到并打开")

            // 步骤2：新建自动化（包含触发方式选择）
            step2WithTriggerOptions

            // 步骤3
            stepView(3, "添加获取壁纸动作", "搜索「Seth365」→ 点击「获取 Seth365 壁纸」")

            // 步骤4
            step4DetailView

            // 步骤5
            stepView(5, "完成设置", "点右上角「完成」→ 选择「立即运行」→ 关闭「运行前询问」")

            // 打开快捷指令按钮
            Button(action: openShortcutsApp) {
                HStack {
                    Image(systemName: "arrow.up.forward.app")
                    Text("打开快捷指令 App")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
    }

    // 步骤2：新建自动化（含触发方式说明，根据iOS版本显示不同操作路径）
    private var step2WithTriggerOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 步骤标题
            HStack(alignment: .top, spacing: 12) {
                Text("2")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("新建自动化")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(step2Instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 触发方式选项
            VStack(spacing: 8) {
                // 定时触发
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("特定时间")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("推荐")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.green)
                                .cornerRadius(3)
                        }
                        Text("每天固定时间换壁纸，无需打开任何App")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                // 打开App触发
                HStack(spacing: 10) {
                    Image(systemName: "app.badge.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("打开App时")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("打开微信/抖音等App时换壁纸")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.leading, 40)

            // 选择后的操作（根据iOS版本显示不同文案）
            Text(step2AfterSelectText)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.leading, 40)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }

    /// 步骤2的操作说明（根据iOS版本不同）
    private var step2Instructions: String {
        if DeviceInfo.isiOS18OrLater {
            // iOS 18+
            return "底部点「自动化」→ 右上角「+」→ 选择触发条件："
        } else if DeviceInfo.isiOS17 {
            // iOS 17
            return "底部点「自动化」→「新建自动化」→ 选择触发条件："
        } else {
            // iOS 16
            return "底部点「自动化」→「创建个人自动化」→ 选择触发条件："
        }
    }

    /// 步骤2选择触发条件后的操作说明
    private var step2AfterSelectText: String {
        if DeviceInfo.isiOS18OrLater {
            return "选好触发条件后，点击「新建空白自动化」"
        } else if DeviceInfo.isiOS17 {
            return "选好触发条件后，直接进入动作编辑页面"
        } else {
            return "选好触发条件后，点击「下一步」"
        }
    }

    // 步骤4：设定墙纸（详细说明）
    private var step4DetailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 步骤标题
            HStack(alignment: .top, spacing: 12) {
                Text("4")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("添加设定墙纸动作")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("在底部搜索框继续搜索「墙纸」")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 详细说明
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("选择「设定墙纸」（不是「在墙纸间切换」）")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("点击展开，位置选「锁定屏幕和主屏幕」")
                        .font(.caption)
                }

                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("关闭「显示预览」")
                        .font(.caption)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.leading, 40)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func stepView(_ number: Int, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }

    // MARK: - 常见问题

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 模拟器特别提示
            if DeviceInfo.isSimulator {
                faqItem(
                    question: "为什么壁纸没有换？",
                    answer: "你正在使用模拟器。iOS 模拟器不支持「设定墙纸」功能，请在真机上测试。",
                    isHighlighted: true
                )
            }

            faqItem(
                question: "设置了定时，但壁纸没换？",
                answer: faqTimingNotWorkAnswer
            )

            faqItem(
                question: "设置了「打开App」触发，关闭App后不生效？",
                answer: "「打开App」触发只在你打开那个App时才生效。如果想不打开任何App就自动换，请使用「定时触发」。"
            )

            // iOS 18 特有问题
            if DeviceInfo.isiOS18OrLater {
                faqItem(
                    question: "运行时弹出错误提示？",
                    answer: "这是 iOS 18 的已知问题，壁纸其实已经换好了。\n\n关闭错误提示：设置 → 屏幕使用时间 → 查看所有活动 → 滑到底部「通知」→ 快捷指令 → 关闭",
                    isHighlighted: true
                )
            }

            faqItem(
                question: "主屏幕壁纸变模糊了？",
                answer: faqBlurryAnswer
            )

            faqItem(
                question: "想设置多个触发条件？",
                answer: "先创建一个快捷指令（包含获取壁纸和设定墙纸两个动作），然后创建多个自动化都调用这个快捷指令即可。"
            )

            faqItem(
                question: "可以解锁手机时自动换吗？",
                answer: "抱歉，iOS 不支持「解锁屏幕」作为触发条件。建议使用定时触发，或设置「打开常用App」触发。"
            )

            faqItem(
                question: "壁纸已内置，为什么还要联网？",
                answer: "当前版本已内置 \(AppInfo.totalBundledWallpapers) 张壁纸（到2月底），完全可以离线使用。3月以后的壁纸需要更新App版本获取。"
            )
        }
        .padding(.horizontal)
    }

    /// 定时不生效的答案（根据iOS版本）
    private var faqTimingNotWorkAnswer: String {
        if DeviceInfo.isiOS18OrLater {
            return "检查以下设置：\n1. 自动化设为「立即运行」而不是「运行前询问」\n2. iOS 18 用户：确保已关闭「运行时通知」"
        } else {
            return "检查自动化是否设为「立即运行」而不是「运行前询问」。"
        }
    }

    /// 壁纸模糊的答案（根据iOS版本）
    private var faqBlurryAnswer: String {
        if DeviceInfo.isiOS18OrLater {
            return "设置 → 墙纸 → 点击主屏幕预览 → 关闭「模糊」\n\niOS 18 用户也可以长按主屏幕 → 点击右下角「自定」→ 关闭模糊效果"
        } else {
            return "设置 → 墙纸 → 点击主屏幕预览 → 关闭「模糊」"
        }
    }

    private func faqItem(question: String, answer: String, isHighlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text("Q")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(isHighlighted ? Color.red : Color.orange)
                    .cornerRadius(4)

                Text(question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isHighlighted ? .red : .primary)
            }

            Text(answer)
                .font(.caption)
                .foregroundColor(isHighlighted ? .red.opacity(0.8) : .secondary)
                .padding(.leading, 28)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Color.red.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHighlighted ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - 方法

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ShortcutsGuideView()
}
