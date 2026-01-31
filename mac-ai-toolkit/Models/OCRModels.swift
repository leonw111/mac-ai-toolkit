//
//  OCRModels.swift
//  mac-ai-toolkit
//
//  OCR data models
//

import Foundation
import CoreGraphics

// MARK: - Recognition Level

enum OCRRecognitionLevel: String, Codable, CaseIterable {
    case accurate
    case fast

    var displayName: String {
        switch self {
        case .accurate: return "精确模式"
        case .fast: return "快速模式"
        }
    }
}

// MARK: - OCR Result

struct OCRResult: Codable, Sendable {
    let text: String
    let confidence: Double
    let language: String
    let blocks: [OCRTextBlock]

    init(text: String, confidence: Double, language: String, blocks: [OCRTextBlock] = []) {
        self.text = text
        self.confidence = confidence
        self.language = language
        self.blocks = blocks
    }
}

// MARK: - Text Block

struct OCRTextBlock: Codable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float
    let boundingBox: CGRect

    init(text: String, confidence: Float, boundingBox: CGRect) {
        self.id = UUID()
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }

    // Custom Codable for CGRect
    enum CodingKeys: String, CodingKey {
        case id, text, confidence
        case x, y, width, height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        confidence = try container.decode(Float.self, forKey: .confidence)

        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        boundingBox = CGRect(x: x, y: y, width: width, height: height)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(boundingBox.origin.x, forKey: .x)
        try container.encode(boundingBox.origin.y, forKey: .y)
        try container.encode(boundingBox.size.width, forKey: .width)
        try container.encode(boundingBox.size.height, forKey: .height)
    }
}

// MARK: - Supported Languages

struct OCRLanguage: Identifiable {
    let code: String
    let name: String
    let localizedName: String

    var id: String { code }

    static let all: [OCRLanguage] = [
        OCRLanguage(code: "zh-Hans", name: "Chinese Simplified", localizedName: "中文简体"),
        OCRLanguage(code: "zh-Hant", name: "Chinese Traditional", localizedName: "中文繁体"),
        OCRLanguage(code: "en-US", name: "English", localizedName: "English"),
        OCRLanguage(code: "ja-JP", name: "Japanese", localizedName: "日本語"),
        OCRLanguage(code: "ko-KR", name: "Korean", localizedName: "한국어"),
        OCRLanguage(code: "fr-FR", name: "French", localizedName: "Français"),
        OCRLanguage(code: "de-DE", name: "German", localizedName: "Deutsch"),
        OCRLanguage(code: "es-ES", name: "Spanish", localizedName: "Español"),
        OCRLanguage(code: "it-IT", name: "Italian", localizedName: "Italiano"),
        OCRLanguage(code: "pt-BR", name: "Portuguese", localizedName: "Português"),
        OCRLanguage(code: "ru-RU", name: "Russian", localizedName: "Русский"),
    ]
}
