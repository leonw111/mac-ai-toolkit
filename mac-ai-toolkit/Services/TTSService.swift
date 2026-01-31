//
//  TTSService.swift
//  mac-ai-toolkit
//
//  AVSpeechSynthesizer TTS service
//

import Foundation
import AVFoundation

actor TTSService {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?

    private init() {}

    // MARK: - Public API

    func speak(
        text: String,
        voiceIdentifier: String? = nil,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0
    ) async throws {
        let utterance = AVSpeechUtterance(string: text)

        if let identifier = voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        }

        utterance.rate = rate * AVSpeechUtteranceMaximumSpeechRate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume

        await MainActor.run {
            synthesizer.speak(utterance)
        }

        // Wait for speech to complete
        try await waitForSpeechCompletion()
    }

    func stop() {
        Task { @MainActor in
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    func synthesizeToFile(
        text: String,
        voiceIdentifier: String? = nil,
        rate: Float = 0.5,
        pitch: Float = 1.0,
        volume: Float = 1.0,
        outputURL: URL,
        format: AudioExportFormat
    ) async throws {
        let utterance = AVSpeechUtterance(string: text)

        if let identifier = voiceIdentifier {
            utterance.voice = AVSpeechSynthesisVoice(identifier: identifier)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        }

        utterance.rate = rate * AVSpeechUtteranceMaximumSpeechRate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var audioData = Data()

            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                    if audioData.isEmpty {
                        continuation.resume(throwing: TTSError.synthesizeFailed("No audio data generated"))
                    } else {
                        // Write to file
                        do {
                            try self.writeAudioData(audioData, to: outputURL, format: format, sourceFormat: pcmBuffer?.format)
                            continuation.resume()
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                    return
                }

                guard let channelData = pcmBuffer.floatChannelData else { return }

                let frameLength = Int(pcmBuffer.frameLength)
                let channelCount = Int(pcmBuffer.format.channelCount)

                for frame in 0..<frameLength {
                    for channel in 0..<channelCount {
                        let sample = channelData[channel][frame]
                        var sampleData = sample
                        audioData.append(Data(bytes: &sampleData, count: MemoryLayout<Float>.size))
                    }
                }
            }
        }
    }

    // MARK: - Voice Management

    nonisolated static func availableVoices() -> [TTSVoice] {
        AVSpeechSynthesisVoice.speechVoices().map { voice in
            TTSVoice(
                identifier: voice.identifier,
                name: voice.name,
                language: voice.language,
                quality: voice.quality == .enhanced ? .enhanced : .standard
            )
        }
    }

    nonisolated static func voicesForLanguage(_ language: String) -> [TTSVoice] {
        availableVoices().filter { $0.language.hasPrefix(language.prefix(2)) }
    }

    // MARK: - Private Helpers

    private func waitForSpeechCompletion() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task { @MainActor in
                // Poll for completion
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if !self.synthesizer.isSpeaking {
                        timer.invalidate()
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func writeAudioData(_ data: Data, to url: URL, format: AudioExportFormat, sourceFormat: AVAudioFormat?) throws {
        // For now, write as raw audio data
        // TODO: Proper format conversion for MP3/WAV
        try data.write(to: url)
    }
}

// MARK: - Supporting Types

struct TTSVoice: Identifiable {
    let identifier: String
    let name: String
    let language: String
    let quality: VoiceQuality

    var id: String { identifier }

    enum VoiceQuality {
        case standard
        case enhanced
    }
}

enum AudioExportFormat: String {
    case mp3 = "mp3"
    case wav = "wav"
}

enum TTSError: LocalizedError {
    case noVoiceAvailable
    case synthesizeFailed(String)
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noVoiceAvailable:
            return "No voice available for the selected language"
        case .synthesizeFailed(let message):
            return "Speech synthesis failed: \(message)"
        case .exportFailed(let message):
            return "Audio export failed: \(message)"
        }
    }
}
