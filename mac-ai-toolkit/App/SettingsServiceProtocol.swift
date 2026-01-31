//
//  SettingsServiceProtocol.swift
//  mac-ai-toolkit
//
//  Settings service protocol definition
//  Created on 2026-01-31
//

import Foundation
import Vision

// MARK: - Settings Service Protocol

/// 设置服务协议
protocol SettingsServiceProtocol: AnyObject {
    
    /// 获取当前设置
    func getSettings() async -> AppSettings
    
    /// 更新设置
    func updateSettings(_ update: @escaping (inout AppSettings) -> Void) async
    
    /// 重置为默认设置
    func resetToDefaults() async
    
    /// 保存设置
    func save() async
}

// MARK: - App Settings

/// 应用设置
struct AppSettings: Codable, Sendable {
    
    // MARK: - General
    
    var launchAtLogin: Bool
    var theme: AppTheme
    var language: String
    var showInMenuBar: Bool
    
    // MARK: - API
    
    var apiEnabled: Bool
    var apiPort: Int
    var apiKey: String
    
    // MARK: - OCR
    
    var ocrDefaultLanguage: String
    var ocrRecognitionLevel: OCRRecognitionLevel
    var ocrAutoCopy: Bool
    var ocrMinimumTextHeight: Float
    
    // MARK: - TTS
    
    var ttsDefaultVoice: String
    var ttsDefaultRate: Float
    var ttsDefaultPitch: Float
    var ttsDefaultVolume: Float
    
    // MARK: - STT
    
    var sttDefaultLanguage: String
    var sttLocalOnly: Bool
    var sttAutoCopy: Bool
    var sttEnhancedMode: Bool
    
    // MARK: - History
    
    var historyRetentionDays: Int
    var historyMaxItems: Int
    var historyAutoCleanup: Bool
    
    // MARK: - Shortcuts
    
    var shortcuts: [KeyboardShortcut]
    
    // MARK: - Default Values
    
    static let `default` = AppSettings(
        launchAtLogin: false,
        theme: .system,
        language: "zh-Hans",
        showInMenuBar: true,
        apiEnabled: false,
        apiPort: 19527,
        apiKey: "",
        ocrDefaultLanguage: "zh-Hans",
        ocrRecognitionLevel: .accurate,
        ocrAutoCopy: true,
        ocrMinimumTextHeight: 0.0,
        ttsDefaultVoice: "",
        ttsDefaultRate: 0.5,
        ttsDefaultPitch: 1.0,
        ttsDefaultVolume: 0.8,
        sttDefaultLanguage: "zh-CN",
        sttLocalOnly: false,
        sttAutoCopy: true,
        sttEnhancedMode: true,
        historyRetentionDays: 30,
        historyMaxItems: 1000,
        historyAutoCleanup: true,
        shortcuts: KeyboardShortcut.defaultShortcuts
    )
}

// MARK: - App Theme

/// 应用主题
enum AppTheme: String, Codable, Sendable, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

// MARK: - OCR Recognition Level

/// OCR 识别级别
enum OCRRecognitionLevel: String, Codable, Sendable {
    case fast
    case accurate
    
    var displayName: String {
        switch self {
        case .fast: return "快速"
        case .accurate: return "准确"
        }
    }
    
    var visionLevel: VNRequestTextRecognitionLevel {
        switch self {
        case .fast: return .fast
        case .accurate: return .accurate
        }
    }
}

// MARK: - Keyboard Shortcut

/// 键盘快捷键
struct KeyboardShortcut: Codable, Identifiable, Sendable {
    let id: String
    let action: ShortcutAction
    var key: String
    var modifiers: [ShortcutModifier]
    var isEnabled: Bool
    
    var displayString: String {
        guard isEnabled else { return "未设置" }
        let modifierSymbols = modifiers.map(\.symbol).joined()
        return modifierSymbols + key.uppercased()
    }
    
    static let defaultShortcuts: [KeyboardShortcut] = [
        KeyboardShortcut(
            id: "screenshot-ocr",
            action: .screenshotOCR,
            key: "1",
            modifiers: [.command, .shift],
            isEnabled: true
        ),
        KeyboardShortcut(
            id: "clipboard-ocr",
            action: .clipboardOCR,
            key: "2",
            modifiers: [.command, .shift],
            isEnabled: true
        ),
        KeyboardShortcut(
            id: "quick-tts",
            action: .quickTTS,
            key: "3",
            modifiers: [.command, .shift],
            isEnabled: true
        ),
        KeyboardShortcut(
            id: "quick-stt",
            action: .quickSTT,
            key: "4",
            modifiers: [.command, .shift],
            isEnabled: true
        ),
        KeyboardShortcut(
            id: "open-main-window",
            action: .openMainWindow,
            key: "0",
            modifiers: [.command, .shift],
            isEnabled: true
        )
    ]
}

/// 快捷键动作
enum ShortcutAction: String, Codable, Sendable {
    case screenshotOCR
    case clipboardOCR
    case quickTTS
    case quickSTT
    case openMainWindow
    
    var displayName: String {
        switch self {
        case .screenshotOCR: return "截图 OCR"
        case .clipboardOCR: return "剪贴板 OCR"
        case .quickTTS: return "快速 TTS"
        case .quickSTT: return "快速 STT"
        case .openMainWindow: return "打开主窗口"
        }
    }
}

/// 快捷键修饰符
enum ShortcutModifier: String, Codable, Sendable {
    case command
    case shift
    case option
    case control
    
    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .shift: return "⇧"
        case .option: return "⌥"
        case .control: return "⌃"
        }
    }
}
