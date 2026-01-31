//
//  TTSModels.swift
//  mac-ai-toolkit
//
//  TTS data models
//

import Foundation

// MARK: - TTS Request

struct TTSRequest: Codable {
    let text: String
    let voice: String?
    let language: String?
    let rate: Float
    let pitch: Float
    let volume: Float
    let outputFormat: AudioExportFormat

    init(
        text: String,
        voice: String? = nil,
        language: String? = nil,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0,
        outputFormat: AudioExportFormat = .mp3
    ) {
        self.text = text
        self.voice = voice
        self.language = language
        self.rate = rate
        self.pitch = pitch
        self.volume = volume
        self.outputFormat = outputFormat
    }
}

// MARK: - TTS Result

struct TTSResult: Codable {
    let audioData: Data
    let format: AudioExportFormat
    let duration: TimeInterval
    let voice: String
}

// MARK: - Voice Language

struct TTSLanguage: Identifiable {
    let code: String
    let name: String
    let localizedName: String

    var id: String { code }

    static let all: [TTSLanguage] = [
        TTSLanguage(code: "zh-CN", name: "Chinese (Mandarin)", localizedName: "中文普通话"),
        TTSLanguage(code: "zh-TW", name: "Chinese (Taiwan)", localizedName: "中文 (台湾)"),
        TTSLanguage(code: "zh-HK", name: "Chinese (Cantonese)", localizedName: "粤语"),
        TTSLanguage(code: "en-US", name: "English (US)", localizedName: "English (US)"),
        TTSLanguage(code: "en-GB", name: "English (UK)", localizedName: "English (UK)"),
        TTSLanguage(code: "ja-JP", name: "Japanese", localizedName: "日本語"),
        TTSLanguage(code: "ko-KR", name: "Korean", localizedName: "한국어"),
        TTSLanguage(code: "fr-FR", name: "French", localizedName: "Français"),
        TTSLanguage(code: "de-DE", name: "German", localizedName: "Deutsch"),
        TTSLanguage(code: "es-ES", name: "Spanish", localizedName: "Español"),
    ]
}
