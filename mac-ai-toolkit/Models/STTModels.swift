//
//  STTModels.swift
//  mac-ai-toolkit
//
//  STT data models
//

import Foundation

// MARK: - STT Result

struct STTResult: Codable {
    let text: String
    let confidence: Double
    let segments: [TranscriptionSegment]

    init(text: String, confidence: Double, segments: [TranscriptionSegment] = []) {
        self.text = text
        self.confidence = confidence
        self.segments = segments
    }
}

// MARK: - Transcription Segment

struct TranscriptionSegment: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Double

    init(text: String, timestamp: TimeInterval, duration: TimeInterval, confidence: Double = 1.0) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.duration = duration
        self.confidence = confidence
    }

    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var srtTimestamp: String {
        let startHours = Int(timestamp) / 3600
        let startMinutes = (Int(timestamp) % 3600) / 60
        let startSeconds = Int(timestamp) % 60
        let startMillis = Int((timestamp * 1000).truncatingRemainder(dividingBy: 1000))

        let endTime = timestamp + duration
        let endHours = Int(endTime) / 3600
        let endMinutes = (Int(endTime) % 3600) / 60
        let endSeconds = Int(endTime) % 60
        let endMillis = Int((endTime * 1000).truncatingRemainder(dividingBy: 1000))

        return String(format: "%02d:%02d:%02d,%03d --> %02d:%02d:%02d,%03d",
                      startHours, startMinutes, startSeconds, startMillis,
                      endHours, endMinutes, endSeconds, endMillis)
    }
}

// MARK: - STT Language

struct STTLanguage: Identifiable {
    let code: String
    let name: String
    let localizedName: String

    var id: String { code }

    static let all: [STTLanguage] = [
        STTLanguage(code: "zh-CN", name: "Chinese (Mandarin)", localizedName: "中文普通话"),
        STTLanguage(code: "zh-TW", name: "Chinese (Taiwan)", localizedName: "中文 (台湾)"),
        STTLanguage(code: "zh-HK", name: "Chinese (Cantonese)", localizedName: "粤语"),
        STTLanguage(code: "en-US", name: "English (US)", localizedName: "English (US)"),
        STTLanguage(code: "en-GB", name: "English (UK)", localizedName: "English (UK)"),
        STTLanguage(code: "ja-JP", name: "Japanese", localizedName: "日本語"),
        STTLanguage(code: "ko-KR", name: "Korean", localizedName: "한국어"),
        STTLanguage(code: "fr-FR", name: "French", localizedName: "Français"),
        STTLanguage(code: "de-DE", name: "German", localizedName: "Deutsch"),
        STTLanguage(code: "es-ES", name: "Spanish", localizedName: "Español"),
    ]
}

// MARK: - Recording State

enum RecordingState {
    case idle
    case recording
    case processing
    case completed
    case error(String)
}
