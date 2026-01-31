//
//  OCRServiceProtocol.swift
//  mac-ai-toolkit
//
//  OCR service protocol definition
//  Created on 2026-01-31
//

import AppKit
import Vision

// MARK: - OCR Service Protocol

/// OCR 服务协议
///
/// 定义文字识别服务的核心接口
protocol OCRServiceProtocol: Actor {
    
    /// 识别图像中的文字
    ///
    /// - Parameters:
    ///   - image: 要识别的图像
    ///   - languages: 识别语言列表，nil 表示使用默认语言
    ///   - recognitionLevel: 识别级别（快速/准确）
    /// - Returns: OCR 识别结果
    /// - Throws: OCRError 如果识别失败
    func recognizeText(
        from image: NSImage,
        languages: [String]?,
        recognitionLevel: VNRequestTextRecognitionLevel
    ) async throws -> OCRResult
    
    /// 取消当前识别任务
    func cancelRecognition()
}

// MARK: - OCR Result

/// OCR 识别结果
struct OCRResult: Identifiable, Codable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float
    let recognizedLanguages: [String]
    let processedAt: Date
    let observations: [TextObservation]
    
    init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        recognizedLanguages: [String],
        processedAt: Date = Date(),
        observations: [TextObservation] = []
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.recognizedLanguages = recognizedLanguages
        self.processedAt = processedAt
        self.observations = observations
    }
}

// MARK: - Text Observation

/// 文本观察结果（单个识别的文本块）
struct TextObservation: Identifiable, Codable, Sendable {
    let id: UUID
    let text: String
    let confidence: Float
    let boundingBox: BoundingBox
    
    init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: BoundingBox
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// 边界框
struct BoundingBox: Codable, Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - OCR Error

/// OCR 错误类型
enum OCRError: LocalizedError, Sendable {
    case imageProcessingFailed
    case invalidImage
    case noTextFound
    case recognitionFailed(underlying: Error)
    case cancelled
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图像处理失败"
        case .invalidImage:
            return "无效的图像格式"
        case .noTextFound:
            return "未识别到文字"
        case .recognitionFailed(let error):
            return "识别失败: \(error.localizedDescription)"
        case .cancelled:
            return "识别已取消"
        case .serviceUnavailable:
            return "OCR 服务不可用"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageProcessingFailed, .invalidImage:
            return "请尝试使用其他图像"
        case .noTextFound:
            return "请确保图像中包含清晰的文字"
        case .recognitionFailed:
            return "请重试或检查系统设置"
        case .cancelled:
            return nil
        case .serviceUnavailable:
            return "请检查系统权限设置"
        }
    }
}

// MARK: - OCR Configuration

/// OCR 配置
struct OCRConfiguration: Sendable {
    var defaultLanguages: [String]
    var recognitionLevel: VNRequestTextRecognitionLevel
    var autoCopy: Bool
    var minimumTextHeight: Float
    
    static let `default` = OCRConfiguration(
        defaultLanguages: ["zh-Hans", "en-US"],
        recognitionLevel: .accurate,
        autoCopy: true,
        minimumTextHeight: 0.0
    )
}
