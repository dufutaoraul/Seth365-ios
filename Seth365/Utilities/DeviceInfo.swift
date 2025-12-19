//
//  DeviceInfo.swift
//  Seth365
//
//  设备信息检测工具
//

import UIKit

/// 设备信息工具类
struct DeviceInfo {

    // MARK: - iOS 版本

    /// iOS 主版本号 (如 16, 17, 18)
    static var iOSMajorVersion: Int {
        return Int(UIDevice.current.systemVersion.components(separatedBy: ".").first ?? "0") ?? 0
    }

    /// iOS 完整版本号
    static var iOSVersion: String {
        return UIDevice.current.systemVersion
    }

    /// 是否是 iOS 16
    static var isiOS16: Bool {
        return iOSMajorVersion == 16
    }

    /// 是否是 iOS 17
    static var isiOS17: Bool {
        return iOSMajorVersion == 17
    }

    /// 是否是 iOS 18 或更高
    static var isiOS18OrLater: Bool {
        return iOSMajorVersion >= 18
    }

    // MARK: - 设备型号

    /// 设备机型标识符 (如 "iPhone15,2")
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// 设备友好名称
    static var modelName: String {
        let identifier = modelIdentifier

        // iPhone 型号映射
        let modelMap: [String: String] = [
            // iPhone 16 系列
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",

            // iPhone 15 系列
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",

            // iPhone 14 系列
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",

            // iPhone 13 系列
            "iPhone14,5": "iPhone 13",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",

            // iPhone 12 系列
            "iPhone13,2": "iPhone 12",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",

            // iPhone 11 系列
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",

            // iPhone SE
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone12,8": "iPhone SE (2nd gen)",

            // 模拟器
            "i386": "Simulator",
            "x86_64": "Simulator",
            "arm64": "Simulator"
        ]

        return modelMap[identifier] ?? "iPhone"
    }

    /// 是否是模拟器
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// 是否有灵动岛 (iPhone 14 Pro 及以上)
    static var hasDynamicIsland: Bool {
        let identifier = modelIdentifier
        let dynamicIslandModels = [
            "iPhone15,2", "iPhone15,3",  // iPhone 14 Pro/Max
            "iPhone16,1", "iPhone16,2",  // iPhone 15 Pro/Max
            "iPhone15,4", "iPhone15,5",  // iPhone 15/Plus
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4"  // iPhone 16 系列
        ]
        return dynamicIslandModels.contains(identifier)
    }

    /// 是否是大屏设备 (Plus/Max/Pro Max)
    static var isLargeScreen: Bool {
        return UIScreen.main.bounds.height >= 896
    }

    // MARK: - 显示信息

    /// 设备信息摘要
    static var summary: String {
        if isSimulator {
            return "模拟器 (iOS \(iOSVersion))"
        }
        return "\(modelName) (iOS \(iOSVersion))"
    }
}
