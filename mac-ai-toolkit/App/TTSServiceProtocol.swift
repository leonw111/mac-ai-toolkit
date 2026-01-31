//
//  TTSServiceProtocol.swift
//  mac-ai-toolkit
//
//  TTS service protocol definition
//  Created on 2026-01-31
//

import Foundation
import AVFoundation

// MARK: - TTS Service Protocol

/// TTS 服务协议
///
/// 定义文字转语音服务的核心接口
protocol TTSServiceProtocol: Actor {
    
    /// 朗读文本
    ///
    /// - Parameters:
    ///   - text: 要朗读的文本
    ///   - configuration: TTS 配置
    /// - Throws: TTSError 如果朗读失败
    func speak(text: String, configuration: TTSConfiguration) async throws
    
    /// 合成音频到文件
    ///
    /// - Parameters:
    ///   - text: 要合成的文本
    ///   - configuration: TTS 配置
    ///   - outputURL: 输出文件路径
    ///   - format: 音频格式
    /// - Throws: TTSError 如果合成失败
    func synthesizeToFile(
        text: String,
        configuration: TTSConfiguration,
        outputURL: URL,
        format: AudioExportFormat
    ) async throws
    
    /// 停止当前播放
    func stop()
    
    /// 暂停播放
    func pause()
    
    /// 继续播放
    func resume()
    
    /// 获取可用语音列表
    func getAvailableVoices() -> [VoiceInfo]
    
    /// 当前播放状态
    var isPlaying: Bool { get async }
}

// MARK: - TTS Configuration

/// TTS 配置
struct TTSConfiguration: Sendable {
    var voiceIdentifier: String?
    var rate: Float           // 0.0 - 1.0
    var pitch: Float          // 0.5 - 2.0
    var volume: Float         // 0.0 - 1.0
    
    static let `default` = TTSConfiguration(
        voiceIdentifier: nil,
        rate: 0.5,
        pitch: 1.0,
        volume: 0.8
    )
    
    /// 验证配置参数是否有效
    var isValid: Bool {
        rate >= 0 && rate <= 1 &&
        pitch >= 0.5 && pitch <= 2.0 &&
        volume >= 0 && volume <= 1
    }
}

// MARK: - Voice Info

/// 语音信息
struct VoiceInfo: Identifiable, Sendable, Codable {
    let identifier: String
    let name: String
    let language: String
    let quality: VoiceQuality
    
    var id: String { identifier }
    
    var displayName: String {
        "\(name) (\(language))"
    }
}

/// 语音质量
enum VoiceQuality: String, Codable, Sendable {
    case `default`
    case enhanced
    case premium
    
    var displayName: String {
        switch self {
        case .default: return "标准"
        case .enhanced: return "增强"
        case .premium: return "高级"
        }
    }
}

// MARK: - Audio Export Format

/// 音频导出格式
enum AudioExportFormat: String, Codable, Sendable, CaseIterable {
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"
    case m4a = "m4a"
    
    var displayName: String {
        rawValue.uppercased()
    }
    
    var fileExtension: String {
        rawValue
    }
    
    var contentType: String {
        switch self {
        case .mp3: return "audio/mpeg"
        case .wav: return "audio/wav"
        case .aac: return "audio/aac"
        case .m4a: return "audio/mp4"
        }
    }
}

// MARK: - TTS Error

/// TTS 错误类型
enum TTSError: LocalizedError, Sendable {
    case invalidText
    case voiceNotFound
    case synthesizeFailed(underlying: Error)
    case fileWriteFailed(underlying: Error)
    case invalidConfiguration
    case serviceUnavailable
    case alreadyPlaying
    
    var errorDescription: String? {
        switch self {
        case .invalidText:
            return "无效的文本内容"
        case .voiceNotFound:
            return "未找到指定的语音"
        case .synthesizeFailed(let error):
            return "合成失败: \(error.localizedDescription)"
        case .fileWriteFailed(let error):
            return "文件写入失败: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "无效的配置参数"
        case .serviceUnavailable:
            return "TTS 服务不可用"
        case .alreadyPlaying:
            return "已有正在播放的任务"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidText:
            return "请输入有效的文本内容"
        case .voiceNotFound:
            return "请选择其他语音"
        case .synthesizeFailed, .fileWriteFailed:
            return "请重试"
        case .invalidConfiguration:
            return "请检查配置参数"
        case .serviceUnavailable:
            return "请检查系统设置"
        case .alreadyPlaying:
            return "请等待当前任务完成"
        }
    }
}

// MARK: - TTS Delegate Protocol

/// TTS 播放委托
protocol TTSSpeechDelegate: AnyObject, Sendable {
    func didStartSpeaking()
    func didFinishSpeaking()
    func didPauseSpeaking()
    func didCancelSpeaking()
    func didEncounterError(_ error: Error)
}
