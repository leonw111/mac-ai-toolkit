//
//  SettingsService.swift
//  mac-ai-toolkit
//
//  Centralized settings management service
//

import Foundation

@MainActor
final class SettingsService: SettingsServiceProtocol {
    static let shared = SettingsService()
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Keys
    
    private enum Keys {
        static let ttsSettings = "tts_settings"
        static let sttSettings = "stt_settings"
        static let ocrSettings = "ocr_settings"
        static let apiSettings = "api_settings"
    }
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - TTS Settings
    
    func getTTSSettings() -> TTSSettings {
        guard let data = userDefaults.data(forKey: Keys.ttsSettings),
              let settings = try? decoder.decode(TTSSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    func saveTTSSettings(_ settings: TTSSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        userDefaults.set(data, forKey: Keys.ttsSettings)
    }
    
    // MARK: - Reset
    
    func resetTTSSettings() {
        userDefaults.removeObject(forKey: Keys.ttsSettings)
    }
    
    func resetAllSettings() {
        userDefaults.removeObject(forKey: Keys.ttsSettings)
        userDefaults.removeObject(forKey: Keys.sttSettings)
        userDefaults.removeObject(forKey: Keys.ocrSettings)
        userDefaults.removeObject(forKey: Keys.apiSettings)
    }
}

// MARK: - TTSSettings Extension

extension TTSSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case voiceIdentifier
        case rate
        case pitch
        case volume
        case language
    }
}
