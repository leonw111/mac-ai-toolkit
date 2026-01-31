//
//  TTSViewModel.swift
//  mac-ai-toolkit
//
//  ViewModel for TTS functionality
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class TTSViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var inputText: String = ""
    @Published var selectedVoice: String = ""
    @Published var rate: Double = 0.5
    @Published var pitch: Double = 1.0
    @Published var volume: Double = 0.8
    @Published var isPlaying: Bool = false
    @Published var availableVoices: [VoiceInfo] = []
    @Published var filteredVoices: [VoiceInfo] = []
    @Published var selectedLanguage: String = "zh-CN"
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isExporting: Bool = false
    
    // MARK: - Computed Properties
    
    var characterCount: Int {
        inputText.count
    }
    
    var canPerformAction: Bool {
        !inputText.isEmpty && !isExporting
    }
    
    var canPlayPreview: Bool {
        canPerformAction && !isPlaying
    }
    
    // MARK: - Private Properties
    
    private let ttsService: TTSServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let historyService: HistoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        ttsService: TTSServiceProtocol = TTSService.shared,
        settingsService: SettingsServiceProtocol = SettingsService.shared,
        historyService: HistoryServiceProtocol = HistoryService.shared
    ) {
        self.ttsService = ttsService
        self.settingsService = settingsService
        self.historyService = historyService
        
        setupObservers()
        loadSettings()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听语言变化，自动过滤语音
        $selectedLanguage
            .combineLatest($availableVoices)
            .map { language, voices in
                voices.filter { $0.language.hasPrefix(language.prefix(2)) }
            }
            .assign(to: &$filteredVoices)
        
        // 自动保存设置
        Publishers.CombineLatest4($rate, $pitch, $volume, $selectedVoice)
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] rate, pitch, volume, voice in
                self?.saveSettings(rate: rate, pitch: pitch, volume: volume, voice: voice)
            }
            .store(in: &cancellables)
    }
    
    private func loadSettings() {
        let settings = settingsService.getTTSSettings()
        rate = Double(settings.rate)
        pitch = Double(settings.pitch)
        volume = Double(settings.volume)
        selectedVoice = settings.voiceIdentifier ?? ""
        selectedLanguage = settings.language
    }
    
    private func saveSettings(rate: Double, pitch: Double, volume: Double, voice: String) {
        let settings = TTSSettings(
            voiceIdentifier: voice.isEmpty ? nil : voice,
            rate: Float(rate),
            pitch: Float(pitch),
            volume: Float(volume),
            language: selectedLanguage
        )
        settingsService.saveTTSSettings(settings)
    }
    
    // MARK: - Public Methods
    
    func loadAvailableVoices() {
        availableVoices = TTSService.availableVoices().map { voice in
            VoiceInfo(
                identifier: voice.identifier,
                name: voice.name,
                language: voice.language
            )
        }.sorted { $0.language < $1.language }
        
        // 如果有保存的语音，确保它仍然可用
        if !selectedVoice.isEmpty && !availableVoices.contains(where: { $0.identifier == selectedVoice }) {
            selectedVoice = ""
        }
    }
    
    func pasteFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string) {
            inputText = text
        }
    }
    
    func clearText() {
        inputText = ""
    }
    
    func playPreview() {
        guard canPlayPreview else { return }
        
        isPlaying = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                try await ttsService.speak(
                    text: inputText,
                    voiceIdentifier: selectedVoice.isEmpty ? nil : selectedVoice,
                    rate: Float(rate),
                    pitch: Float(pitch),
                    volume: Float(volume)
                )
                
                // 记录历史
                await recordHistory(action: .preview)
                
                isPlaying = false
            } catch {
                isPlaying = false
                handleError(error)
            }
        }
    }
    
    func stopPlayback() {
        Task {
            await ttsService.stop()
            isPlaying = false
        }
    }
    
    func exportAudio(format: AudioExportFormat) {
        guard canPerformAction else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = format == .mp3 ? [.mp3] : [.wav]
        panel.nameFieldStringValue = generateFileName(format: format)
        panel.canCreateDirectories = true
        panel.showsTagField = true
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            
            Task { @MainActor in
                await self.performExport(to: url, format: format)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performExport(to url: URL, format: AudioExportFormat) async {
        isExporting = true
        errorMessage = nil
        showError = false
        
        do {
            try await ttsService.synthesizeToFile(
                text: inputText,
                voiceIdentifier: selectedVoice.isEmpty ? nil : selectedVoice,
                rate: Float(rate),
                pitch: Float(pitch),
                volume: Float(volume),
                outputURL: url,
                format: format
            )
            
            // 记录历史
            await recordHistory(action: .export(format: format, url: url))
            
            isExporting = false
            
            // 可选：显示成功通知
            showSuccessNotification(format: format, url: url)
        } catch {
            isExporting = false
            handleError(error)
        }
    }
    
    private func recordHistory(action: TTSHistoryAction) async {
        let historyItem = TTSHistoryItem(
            text: inputText,
            voice: selectedVoice,
            language: selectedLanguage,
            action: action,
            timestamp: Date()
        )
        
        await historyService.addTTSHistory(historyItem)
    }
    
    private func handleError(_ error: Error) {
        if let ttsError = error as? TTSError {
            errorMessage = ttsError.localizedDescription
        } else {
            errorMessage = "操作失败: \(error.localizedDescription)"
        }
        showError = true
    }
    
    private func generateFileName(format: AudioExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "TTS_\(timestamp).\(format.rawValue)"
    }
    
    private func showSuccessNotification(format: AudioExportFormat, url: URL) {
        // 可以集成 UserNotifications 或 NSUserNotification
        print("✅ 导出成功: \(url.path)")
    }
}

// MARK: - Supporting Types

struct VoiceInfo: Identifiable, Hashable {
    let identifier: String
    let name: String
    let language: String
    
    var id: String { identifier }
    
    var displayName: String {
        "\(name) (\(language))"
    }
}

struct TTSSettings {
    let voiceIdentifier: String?
    let rate: Float
    let pitch: Float
    let volume: Float
    let language: String
    
    static let `default` = TTSSettings(
        voiceIdentifier: nil,
        rate: 0.5,
        pitch: 1.0,
        volume: 0.8,
        language: "zh-CN"
    )
}

struct TTSHistoryItem {
    let text: String
    let voice: String
    let language: String
    let action: TTSHistoryAction
    let timestamp: Date
}

enum TTSHistoryAction {
    case preview
    case export(format: AudioExportFormat, url: URL)
}

// MARK: - Protocol Definitions

protocol TTSServiceProtocol {
    func speak(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        volume: Float
    ) async throws
    
    func stop() async
    
    func synthesizeToFile(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        volume: Float,
        outputURL: URL,
        format: AudioExportFormat
    ) async throws
}

protocol SettingsServiceProtocol {
    func getTTSSettings() -> TTSSettings
    func saveTTSSettings(_ settings: TTSSettings)
}

protocol HistoryServiceProtocol {
    func addTTSHistory(_ item: TTSHistoryItem) async
}

// MARK: - Default Implementations

extension TTSService: TTSServiceProtocol {}

// MARK: - Preview Support

extension TTSViewModel {
    static var preview: TTSViewModel {
        let viewModel = TTSViewModel()
        viewModel.inputText = "这是一段测试文本，用于预览界面效果。"
        viewModel.availableVoices = [
            VoiceInfo(identifier: "com.apple.ttsbundle.Tingting-compact", name: "Tingting", language: "zh-CN"),
            VoiceInfo(identifier: "com.apple.ttsbundle.Samantha-compact", name: "Samantha", language: "en-US")
        ]
        return viewModel
    }
}
