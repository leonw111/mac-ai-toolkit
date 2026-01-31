//
//  HistoryModels.swift
//  mac-ai-toolkit
//
//  History record models
//

import Foundation
import SwiftUI

// MARK: - History Type

enum HistoryType: String, Codable, CaseIterable {
    case ocr
    case tts
    case stt

    var displayName: String {
        switch self {
        case .ocr: return "OCR"
        case .tts: return "TTS"
        case .stt: return "STT"
        }
    }

    var icon: String {
        switch self {
        case .ocr: return "doc.text.viewfinder"
        case .tts: return "speaker.wave.3"
        case .stt: return "mic"
        }
    }

    var color: Color {
        switch self {
        case .ocr: return .blue
        case .tts: return .green
        case .stt: return .orange
        }
    }
}

// MARK: - History Item

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let type: HistoryType
    let content: String
    let result: String
    let timestamp: Date
    let metadata: [String: String]

    init(
        id: UUID = UUID(),
        type: HistoryType,
        content: String,
        result: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.result = result
        self.timestamp = timestamp
        self.metadata = metadata
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - History Statistics

struct HistoryStatistics {
    let totalCount: Int
    let ocrCount: Int
    let ttsCount: Int
    let sttCount: Int
    let todayCount: Int

    init(items: [HistoryItem]) {
        totalCount = items.count
        ocrCount = items.filter { $0.type == .ocr }.count
        ttsCount = items.filter { $0.type == .tts }.count
        sttCount = items.filter { $0.type == .stt }.count

        let today = Calendar.current.startOfDay(for: Date())
        todayCount = items.filter { $0.timestamp >= today }.count
    }
}
