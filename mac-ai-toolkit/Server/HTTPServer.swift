//
//  HTTPServer.swift
//  mac-ai-toolkit
//
//  HTTP API Server using Vapor
//

import Foundation
import Vapor
import Combine

@MainActor
class HTTPServer: ObservableObject {
    static let shared = HTTPServer()

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var requestCount: Int = 0

    private var app: Application?
    private let defaultPort: Int = 19527

    private init() {}

    // MARK: - Server Control

    func start(port: Int? = nil) async throws {
        guard !isRunning else { return }

        let serverPort = port ?? defaultPort

        app = try await Application.make(.production)

        guard let app = app else {
            throw ServerError.failedToStart
        }

        // Configure server
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = serverPort

        // Setup routes
        try configureRoutes(app)

        // Start server
        try await app.startup()
        isRunning = true
    }

    func stop() async {
        guard isRunning, let app = app else { return }

        try? await app.asyncShutdown()
        self.app = nil
        isRunning = false
    }

    // MARK: - Route Configuration

    private func configureRoutes(_ app: Application) throws {
        // Health check
        app.get("health") { req -> HealthResponse in
            HealthResponse(status: "ok", version: "1.0.0")
        }

        // OCR endpoint
        app.on(.POST, "ocr", body: .collect(maxSize: "50mb")) { [weak self] req async throws -> OCRAPIResponse in
            self?.incrementRequestCount()

            guard let imageData = req.body.data else {
                throw Abort(.badRequest, reason: "No image data provided")
            }

            let language = req.query[String.self, at: "language"] ?? "zh-Hans"
            let levelString = req.query[String.self, at: "recognitionLevel"] ?? "accurate"
            let level: OCRRecognitionLevel = levelString == "fast" ? .fast : .accurate

            let data = Data(buffer: imageData)
            let result = try await OCRService.shared.recognizeText(
                from: data,
                language: language,
                level: level
            )

            return OCRAPIResponse(
                text: result.text,
                confidence: result.confidence,
                language: result.language,
                blocks: result.blocks.map { block in
                    OCRBlockResponse(
                        text: block.text,
                        confidence: Double(block.confidence),
                        boundingBox: BoundingBoxResponse(
                            x: block.boundingBox.origin.x,
                            y: block.boundingBox.origin.y,
                            width: block.boundingBox.size.width,
                            height: block.boundingBox.size.height
                        )
                    )
                }
            )
        }

        // TTS endpoint
        app.post("tts") { [weak self] req async throws -> Response in
            self?.incrementRequestCount()

            let request = try req.content.decode(TTSAPIRequest.self)

            // Synthesize to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(request.outputFormat ?? "mp3")

            let format: AudioExportFormat = request.outputFormat == "wav" ? .wav : .mp3

            try await TTSService.shared.synthesizeToFile(
                text: request.text,
                voiceIdentifier: request.voice,
                rate: request.rate ?? 0.5,
                pitch: request.pitch ?? 1.0,
                volume: request.volume ?? 1.0,
                outputURL: tempURL,
                format: format
            )

            let audioData = try Data(contentsOf: tempURL)
            try? FileManager.default.removeItem(at: tempURL)

            let response = Response(status: .ok)
            response.headers.contentType = format == .mp3 ? .init(type: "audio", subType: "mpeg") : .init(type: "audio", subType: "wav")
            response.body = .init(data: audioData)

            return response
        }

        // TTS voices endpoint
        app.get("tts", "voices") { req -> [VoiceResponse] in
            TTSService.availableVoices().map { voice in
                VoiceResponse(
                    identifier: voice.identifier,
                    name: voice.name,
                    language: voice.language,
                    quality: voice.quality == .enhanced ? "enhanced" : "standard"
                )
            }
        }

        // STT endpoint
        app.on(.POST, "stt", body: .collect(maxSize: "100mb")) { [weak self] req async throws -> STTAPIResponse in
            self?.incrementRequestCount()

            guard let audioData = req.body.data else {
                throw Abort(.badRequest, reason: "No audio data provided")
            }

            let language = req.query[String.self, at: "language"] ?? "zh-CN"

            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("wav")

            try Data(buffer: audioData).write(to: tempURL)

            defer {
                try? FileManager.default.removeItem(at: tempURL)
            }

            let result = try await STTService.shared.transcribe(
                audioURL: tempURL,
                language: language,
                localOnly: false
            )

            return STTAPIResponse(
                text: result.text,
                confidence: result.confidence,
                segments: result.segments.map { segment in
                    SegmentResponse(
                        text: segment.text,
                        timestamp: segment.timestamp,
                        duration: segment.duration
                    )
                }
            )
        }
    }

    private func incrementRequestCount() {
        Task { @MainActor in
            requestCount += 1
        }
    }
}

// MARK: - Server Error

enum ServerError: LocalizedError {
    case failedToStart
    case alreadyRunning

    var errorDescription: String? {
        switch self {
        case .failedToStart:
            return "Failed to start HTTP server"
        case .alreadyRunning:
            return "Server is already running"
        }
    }
}

// MARK: - API Response Types

struct HealthResponse: Content {
    let status: String
    let version: String
}

struct OCRAPIResponse: Content {
    let text: String
    let confidence: Double
    let language: String
    let blocks: [OCRBlockResponse]
}

struct OCRBlockResponse: Content {
    let text: String
    let confidence: Double
    let boundingBox: BoundingBoxResponse
}

struct BoundingBoxResponse: Content {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct TTSAPIRequest: Content {
    let text: String
    let voice: String?
    let language: String?
    let rate: Float?
    let pitch: Float?
    let volume: Float?
    let outputFormat: String?
}

struct VoiceResponse: Content {
    let identifier: String
    let name: String
    let language: String
    let quality: String
}

struct STTAPIResponse: Content {
    let text: String
    let confidence: Double
    let segments: [SegmentResponse]
}

struct SegmentResponse: Content {
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
}
