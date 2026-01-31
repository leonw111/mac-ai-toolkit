//
//  TTSViewModel.swift
//  mac-ai-toolkit
//
//  TTS view model
//  Created on 2026-01-31
//

import Foundation
import SwiftUI
import Combine
import OSLog

/// TTS 视图模型
///
/// 管理 TTS 功能的状态和业务逻辑
@MainActor
final class TTSViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var inputText: String = ""
    @Published var selectedVoiceIdentifier: String = ""
    @Published var rate: Double = 0.5
    @Published var pitch: Double = 1.0
    @Published var volume: Double = 0.8
    @Published var state: ViewState = .idle
    @Published var availableVoices: [VoiceInfo] = []
    @Published var error: TTSError?
    
    // MARK: - Computed Properties
    
    var configuration: TTSConfiguration {
        TTSConfiguration(
            voiceIdentifier: selectedVoiceIdentifier.isEmpty ? nil : selectedVoiceIdentifier,
            rate: Float(rate),
            pitch: Float(pitch),
            volume: Float(volume)
        )
    }
    
    var canSpeak: Bool {
        !inputText.isEmpty && state != .loading
    }
    
    var isPlaying: Bool {
        state == .loading
    }
    
    var characterCount: Int {
        inputText.count
    }
    
    // MARK: - Private Properties
    
    private let ttsService: TTSServiceProtocol
    private let historyService: HistoryServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "TTS")
    
    // MARK: - Initialization
    
    init(
        ttsService: TTSServiceProtocol,
        historyService: HistoryServiceProtocol,
        settingsService: SettingsServiceProtocol
    ) {
        self.ttsService = ttsService
        self.historyService = historyService
        self.settingsService = settingsService
        
        setupBindings()
    }
    
    convenience init(environment: AppEnvironment = .shared) {
        self.init(
            ttsService: environment.ttsService,
            historyService: environment.historyService,
            settingsService: environment.settingsService
        )
    }
    
    // MARK: - Public Methods
    
    /// 加载可用语音列表
    func loadAvailableVoices() async {
        logger.info("加载可用语音列表")
        
        let voices = await ttsService.getAvailableVoices()
        availableVoices = voices.sorted { $0.language < $1.language }
        
        // 如果没有选择语音，使用默认语音
        if selectedVoiceIdentifier.isEmpty {
            let settings = await settingsService.getSettings()
            selectedVoiceIdentifier = settings.ttsDefaultVoice
        }
        
        logger.info("已加载 \(voices.count) 个语音")
    }
    
    /// 预览播放
    func playPreview() async {
        guard canSpeak else {
            logger.warning("无法播放：条件不满足")
            return
        }
        
        logger.info("开始预览播放")
        state = .loading
        error = nil
        
        do {
            try await ttsService.speak(text: inputText, configuration: configuration)
            
            // 添加到历史记录
            await historyService.addRecord(
                type: .tts,
                content: inputText,
                result: "播放完成",
                metadata: ["voice": selectedVoiceIdentifier]
            )
            
            state = .success
            logger.info("播放完成")
            
            // 2 秒后重置状态
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if state == .success {
                state = .idle
            }
            
        } catch let ttsError as TTSError {
            error = ttsError
            state = .error(ttsError)
            logger.error("播放失败: \(ttsError.localizedDescription)")
        } catch {
            let ttsError = TTSError.synthesizeFailed(underlying: error)
            self.error = ttsError
            state = .error(ttsError)
            logger.error("播放失败: \(error.localizedDescription)")
        }
    }
    
    /// 停止播放
    func stopPlayback() async {
        logger.info("停止播放")
        await ttsService.stop()
        state = .idle
    }
    
    /// 导出音频文件
    func exportAudio(format: AudioExportFormat, to url: URL) async {
        guard !inputText.isEmpty else { return }
        
        logger.info("开始导出音频: \(format.rawValue)")
        state = .loading
        error = nil
        
        do {
            try await ttsService.synthesizeToFile(
                text: inputText,
                configuration: configuration,
                outputURL: url,
                format: format
            )
            
            // 添加到历史记录
            await historyService.addRecord(
                type: .tts,
                content: inputText,
                result: "已导出到 \(url.lastPathComponent)",
                metadata: [
                    "format": format.rawValue,
                    "voice": selectedVoiceIdentifier
                ]
            )
            
            state = .success
            logger.info("导出成功: \(url.path)")
            
            // 2 秒后重置状态
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if state == .success {
                state = .idle
            }
            
        } catch let ttsError as TTSError {
            error = ttsError
            state = .error(ttsError)
            logger.error("导出失败: \(ttsError.localizedDescription)")
        } catch {
            let ttsError = TTSError.fileWriteFailed(underlying: error)
            self.error = ttsError
            state = .error(ttsError)
            logger.error("导出失败: \(error.localizedDescription)")
        }
    }
    
    /// 从剪贴板粘贴
    func pasteFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
            inputText = text
            logger.info("已从剪贴板粘贴 \(text.count) 个字符")
        }
    }
    
    /// 清空输入
    func clearInput() {
        inputText = ""
        logger.info("已清空输入")
    }
    
    /// 重置为默认设置
    func resetToDefaults() async {
        let settings = await settingsService.getSettings()
        selectedVoiceIdentifier = settings.ttsDefaultVoice
        rate = Double(settings.ttsDefaultRate)
        pitch = Double(settings.ttsDefaultPitch)
        volume = Double(settings.ttsDefaultVolume)
        
        logger.info("已重置为默认设置")
    }
    
    /// 保存当前设置为默认值
    func saveAsDefaults() async {
        await settingsService.updateSettings { settings in
            settings.ttsDefaultVoice = self.selectedVoiceIdentifier
            settings.ttsDefaultRate = Float(self.rate)
            settings.ttsDefaultPitch = Float(self.pitch)
            settings.ttsDefaultVolume = Float(self.volume)
        }
        
        logger.info("已保存为默认设置")
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 自动保存设置
        Publishers.CombineLatest4($selectedVoiceIdentifier, $rate, $pitch, $volume)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                guard let self = self else { return }
                Task { @MainActor in
                    // 可选：自动保存用户偏好
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - View State

/// 视图状态
enum ViewState: Equatable {
    case idle
    case loading
    case success
    case error(Error)
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.success, .success):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
