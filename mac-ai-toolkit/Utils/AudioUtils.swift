//
//  AudioUtils.swift
//  mac-ai-toolkit
//
//  Audio processing utilities
//

import Foundation
import AVFoundation

enum AudioUtils {

    // MARK: - Audio File Info

    static func duration(of url: URL) async -> TimeInterval? {
        let asset = AVAsset(url: url)

        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return nil
        }
    }

    static func isValidAudioFile(_ url: URL) -> Bool {
        let supportedExtensions = ["mp3", "wav", "m4a", "aac", "aiff", "caf", "flac"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }

    // MARK: - Audio Format Conversion

    static func convertToWAV(from inputURL: URL, to outputURL: URL) async throws {
        let asset = AVAsset(url: inputURL)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw AudioError.conversionFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .wav

        await exportSession.export()

        if let error = exportSession.error {
            throw error
        }
    }

    // MARK: - Audio Recording Settings

    static var defaultRecordingSettings: [String: Any] {
        [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    // MARK: - Microphone Permissions

    static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    static var hasMicrophonePermission: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    // MARK: - Audio Session

    static func configureAudioSession() throws {
        // macOS doesn't use AVAudioSession like iOS
        // Configuration is handled per-engine/recorder
    }
}

// MARK: - Audio Errors

enum AudioError: LocalizedError {
    case conversionFailed
    case recordingFailed
    case noMicrophoneAccess
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Audio format conversion failed"
        case .recordingFailed:
            return "Audio recording failed"
        case .noMicrophoneAccess:
            return "Microphone access not granted"
        case .invalidFormat:
            return "Invalid audio format"
        }
    }
}
