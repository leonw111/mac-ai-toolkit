//
//  SettingsModels.swift
//  mac-ai-toolkit
//
//  App settings models
//

import Foundation
import SwiftUI

// MARK: - App Theme

enum AppTheme: String, Codable, CaseIterable {
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

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - App Settings

struct AppSettings: Codable {
    // General
    var launchAtLogin: Bool = false
    var theme: AppTheme = .system
    var language: String = "zh-Hans"

    // API
    var apiEnabled: Bool = true
    var apiPort: Int = 19527
    var apiAuthKey: String = ""

    // OCR
    var ocrDefaultLanguage: String = "zh-Hans"
    var ocrRecognitionLevel: OCRRecognitionLevel = .accurate

    // TTS
    var ttsDefaultVoice: String = ""
    var ttsDefaultRate: Double = 0.5

    // STT
    var sttDefaultLanguage: String = "zh-CN"
    var sttLocalOnly: Bool = false

    // Storage
    var historyRetentionDays: Int = 30
    var defaultExportPath: String = ""

    // MARK: - Persistence

    private static let storageKey = "mac_ai_toolkit_settings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return AppSettings()
        }

        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            return AppSettings()
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: AppSettings.storageKey)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

// MARK: - Keyboard Shortcut

struct KeyboardShortcut: Codable, Identifiable {
    let id: String
    let action: ShortcutAction
    var key: String
    var modifiers: [ShortcutModifier]

    var displayString: String {
        let modifierSymbols = modifiers.map(\.symbol).joined()
        return modifierSymbols + key.uppercased()
    }
}

enum ShortcutAction: String, Codable {
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

enum ShortcutModifier: String, Codable {
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
