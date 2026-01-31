//
//  STTService.swift
//  mac-ai-toolkit
//
//  Speech framework STT service
//

import Foundation
import Speech
import AVFoundation

actor STTService {
    static let shared = STTService()

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentRecognizer: SFSpeechRecognizer?

    private init() {}

    // MARK: - Authorization

    nonisolated static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated static var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Recording

    func startRecording(language: String) async throws {
        // Check authorization
        let status = await STTService.requestAuthorization()
        guard status == .authorized else {
            throw STTError.notAuthorized
        }

        // Setup recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            throw STTError.recognizerNotAvailable
        }

        guard recognizer.isAvailable else {
            throw STTError.recognizerNotAvailable
        }

        currentRecognizer = recognizer

        // Setup audio engine
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() async throws -> STTResult {
        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest,
              let recognizer = currentRecognizer else {
            throw STTError.notRecording
        }

        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest.endAudio()

        // Get final result
        return try await withCheckedThrowingContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    continuation.resume(throwing: STTError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let segments = result.bestTranscription.segments.map { segment in
                    TranscriptionSegment(
                        text: segment.substring,
                        timestamp: segment.timestamp,
                        duration: segment.duration,
                        confidence: Double(segment.confidence)
                    )
                }

                let sttResult = STTResult(
                    text: result.bestTranscription.formattedString,
                    confidence: Double(result.bestTranscription.segments.map(\.confidence).reduce(0, +)) /
                               Double(max(result.bestTranscription.segments.count, 1)),
                    segments: segments
                )

                continuation.resume(returning: sttResult)
            }
        }
    }

    // MARK: - File Transcription

    func transcribe(
        audioURL: URL,
        language: String,
        localOnly: Bool = false
    ) async throws -> STTResult {
        // Check authorization
        let status = await STTService.requestAuthorization()
        guard status == .authorized else {
            throw STTError.notAuthorized
        }

        // Setup recognizer
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: language)) else {
            throw STTError.recognizerNotAvailable
        }

        guard recognizer.isAvailable else {
            throw STTError.recognizerNotAvailable
        }

        // Create recognition request
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        if localOnly {
            if #available(macOS 13.0, *) {
                request.requiresOnDeviceRecognition = true
            }
        }

        // Perform recognition
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: STTError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let result = result, result.isFinal else { return }

                let segments = result.bestTranscription.segments.map { segment in
                    TranscriptionSegment(
                        text: segment.substring,
                        timestamp: segment.timestamp,
                        duration: segment.duration,
                        confidence: Double(segment.confidence)
                    )
                }

                let sttResult = STTResult(
                    text: result.bestTranscription.formattedString,
                    confidence: Double(result.bestTranscription.segments.map(\.confidence).reduce(0, +)) /
                               Double(max(result.bestTranscription.segments.count, 1)),
                    segments: segments
                )

                continuation.resume(returning: sttResult)
            }
        }
    }

    // MARK: - Supported Languages

    nonisolated static func supportedLanguages() -> [String] {
        Set(SFSpeechRecognizer.supportedLocales().map(\.identifier)).sorted()
    }
}

// MARK: - Supporting Types

struct STTResult: Codable {
    let text: String
    let confidence: Double
    let segments: [TranscriptionSegment]
}

struct TranscriptionSegment: Codable {
    let text: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Double
}

// MARK: - Errors

enum STTError: LocalizedError {
    case notAuthorized
    case recognizerNotAvailable
    case notRecording
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .recognizerNotAvailable:
            return "Speech recognizer not available for this language"
        case .notRecording:
            return "No recording in progress"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        }
    }
}
