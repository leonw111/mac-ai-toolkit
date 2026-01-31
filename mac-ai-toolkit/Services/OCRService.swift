//
//  OCRService.swift
//  mac-ai-toolkit
//
//  Vision framework OCR service
//

import Foundation
import Vision
import AppKit

actor OCRService {
    static let shared = OCRService()

    private init() {}

    // MARK: - Public API

    func recognizeText(
        from image: NSImage,
        language: String = "zh-Hans",
        level: OCRRecognitionLevel = .accurate
    ) async throws -> OCRResult {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        return try await recognizeText(from: cgImage, language: language, level: level)
    }

    func recognizeText(
        from imageData: Data,
        language: String = "zh-Hans",
        level: OCRRecognitionLevel = .accurate
    ) async throws -> OCRResult {
        guard let image = NSImage(data: imageData),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        return try await recognizeText(from: cgImage, language: language, level: level)
    }

    func recognizeText(
        from url: URL,
        language: String = "zh-Hans",
        level: OCRRecognitionLevel = .accurate
    ) async throws -> OCRResult {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }

        return try await recognizeText(from: cgImage, language: language, level: level)
    }

    // MARK: - Private Implementation

    private func recognizeText(
        from cgImage: CGImage,
        language: String,
        level: OCRRecognitionLevel
    ) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                var textBlocks: [OCRTextBlock] = []
                var fullText = ""
                var totalConfidence: Float = 0

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }

                    let block = OCRTextBlock(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                    textBlocks.append(block)

                    if !fullText.isEmpty {
                        fullText += "\n"
                    }
                    fullText += topCandidate.string
                    totalConfidence += topCandidate.confidence
                }

                let averageConfidence = observations.isEmpty ? 0 : totalConfidence / Float(observations.count)

                let result = OCRResult(
                    text: fullText,
                    confidence: Double(averageConfidence),
                    language: language,
                    blocks: textBlocks
                )

                continuation.resume(returning: result)
            }

            // Configure request
            request.recognitionLevel = level == .accurate ? .accurate : .fast
            request.usesLanguageCorrection = true

            // Set recognition languages
            let languages = mapLanguageCode(language)
            request.recognitionLanguages = languages

            // Execute request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    private func mapLanguageCode(_ code: String) -> [String] {
        switch code {
        case "zh-Hans":
            return ["zh-Hans", "zh-Hant", "en-US"]
        case "zh-Hant":
            return ["zh-Hant", "zh-Hans", "en-US"]
        case "ja-JP":
            return ["ja-JP", "en-US"]
        case "ko-KR":
            return ["ko-KR", "en-US"]
        default:
            return [code, "en-US"]
        }
    }

    // MARK: - Supported Languages

    static func supportedLanguages() -> [String] {
        do {
            let revision = VNRecognizeTextRequest.currentRevision
            return try VNRecognizeTextRequest.supportedRecognitionLanguages(for: .accurate, revision: revision)
        } catch {
            return ["en-US", "zh-Hans", "zh-Hant", "ja-JP", "ko-KR"]
        }
    }
}

// MARK: - Supporting Types

struct OCRResult: Codable {
    let text: String
    let confidence: Double
    let language: String
    let blocks: [OCRTextBlock]
}

struct OCRTextBlock: Codable {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

enum OCRRecognitionLevel {
    case accurate
    case fast
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .noTextFound:
            return "No text found in image"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        }
    }
}
