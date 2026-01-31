//
//  TTSViewModelTests.swift
//  mac-ai-toolkit-tests
//
//  Unit tests for TTSViewModel
//

import Testing
import Foundation
@testable import mac_ai_toolkit

// MARK: - Mock Services

@MainActor
final class MockTTSService: TTSServiceProtocol {
    var speakCalled = false
    var stopCalled = false
    var synthesizeCalled = false
    var shouldThrowError = false
    
    func speak(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        volume: Float
    ) async throws {
        speakCalled = true
        if shouldThrowError {
            throw TTSError.synthesizeFailed("Mock error")
        }
        try await Task.sleep(for: .milliseconds(100))
    }
    
    func stop() async {
        stopCalled = true
    }
    
    func synthesizeToFile(
        text: String,
        voiceIdentifier: String?,
        rate: Float,
        pitch: Float,
        volume: Float,
        outputURL: URL,
        format: AudioExportFormat
    ) async throws {
        synthesizeCalled = true
        if shouldThrowError {
            throw TTSError.exportFailed("Mock error")
        }
    }
}

@MainActor
final class MockSettingsService: SettingsServiceProtocol {
    var savedSettings: TTSSettings?
    
    func getTTSSettings() -> TTSSettings {
        savedSettings ?? .default
    }
    
    func saveTTSSettings(_ settings: TTSSettings) {
        savedSettings = settings
    }
}

@MainActor
final class MockHistoryService: HistoryServiceProtocol {
    var addedItems: [TTSHistoryItem] = []
    
    func addTTSHistory(_ item: TTSHistoryItem) async {
        addedItems.append(item)
    }
}

// MARK: - Tests

@Suite("TTSViewModel Tests")
@MainActor
struct TTSViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test("ViewModel initializes with default values")
    func testInitialization() async throws {
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        #expect(viewModel.inputText.isEmpty)
        #expect(viewModel.rate == 0.5)
        #expect(viewModel.pitch == 1.0)
        #expect(viewModel.volume == 0.8)
        #expect(!viewModel.isPlaying)
        #expect(!viewModel.isExporting)
    }
    
    @Test("ViewModel loads saved settings")
    func testLoadSettings() async throws {
        let settingsService = MockSettingsService()
        settingsService.savedSettings = TTSSettings(
            voiceIdentifier: "test-voice",
            rate: 0.7,
            pitch: 1.5,
            volume: 0.9,
            language: "en-US"
        )
        
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: settingsService,
            historyService: MockHistoryService()
        )
        
        #expect(viewModel.selectedVoice == "test-voice")
        #expect(viewModel.rate == 0.7)
        #expect(viewModel.pitch == 1.5)
        #expect(viewModel.volume == 0.9)
        #expect(viewModel.selectedLanguage == "en-US")
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("Character count is calculated correctly")
    func testCharacterCount() async throws {
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        viewModel.inputText = "Hello World"
        #expect(viewModel.characterCount == 11)
        
        viewModel.inputText = "你好世界"
        #expect(viewModel.characterCount == 4)
    }
    
    @Test("Can perform action checks input text")
    func testCanPerformAction() async throws {
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        #expect(!viewModel.canPerformAction)
        
        viewModel.inputText = "Test"
        #expect(viewModel.canPerformAction)
        
        viewModel.isExporting = true
        #expect(!viewModel.canPerformAction)
    }
    
    // MARK: - Action Tests
    
    @Test("Play preview calls TTS service")
    func testPlayPreview() async throws {
        let ttsService = MockTTSService()
        let historyService = MockHistoryService()
        let viewModel = TTSViewModel(
            ttsService: ttsService,
            settingsService: MockSettingsService(),
            historyService: historyService
        )
        
        viewModel.inputText = "Test text"
        viewModel.playPreview()
        
        // 等待异步操作完成
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(ttsService.speakCalled)
        #expect(historyService.addedItems.count == 1)
        #expect(!viewModel.isPlaying)
    }
    
    @Test("Stop playback calls TTS service")
    func testStopPlayback() async throws {
        let ttsService = MockTTSService()
        let viewModel = TTSViewModel(
            ttsService: ttsService,
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        viewModel.inputText = "Test text"
        viewModel.isPlaying = true
        viewModel.stopPlayback()
        
        try await Task.sleep(for: .milliseconds(50))
        
        #expect(ttsService.stopCalled)
        #expect(!viewModel.isPlaying)
    }
    
    @Test("Error handling shows error message")
    func testErrorHandling() async throws {
        let ttsService = MockTTSService()
        ttsService.shouldThrowError = true
        
        let viewModel = TTSViewModel(
            ttsService: ttsService,
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        viewModel.inputText = "Test text"
        viewModel.playPreview()
        
        try await Task.sleep(for: .milliseconds(200))
        
        #expect(!viewModel.isPlaying)
        #expect(viewModel.showError)
        #expect(viewModel.errorMessage != nil)
    }
    
    // MARK: - Clipboard Tests
    
    @Test("Paste from clipboard updates input text")
    func testPasteFromClipboard() async throws {
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        // 设置剪贴板内容
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("Pasted text", forType: .string)
        
        viewModel.pasteFromClipboard()
        
        #expect(viewModel.inputText == "Pasted text")
    }
    
    @Test("Clear text empties input")
    func testClearText() async throws {
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: MockSettingsService(),
            historyService: MockHistoryService()
        )
        
        viewModel.inputText = "Some text"
        viewModel.clearText()
        
        #expect(viewModel.inputText.isEmpty)
    }
    
    // MARK: - Settings Tests
    
    @Test("Settings are saved automatically")
    func testSettingsAutoSave() async throws {
        let settingsService = MockSettingsService()
        let viewModel = TTSViewModel(
            ttsService: MockTTSService(),
            settingsService: settingsService,
            historyService: MockHistoryService()
        )
        
        viewModel.rate = 0.8
        viewModel.pitch = 1.2
        viewModel.volume = 0.7
        viewModel.selectedVoice = "test-voice"
        
        // 等待 debounce
        try await Task.sleep(for: .seconds(1))
        
        let settings = try #require(settingsService.savedSettings)
        #expect(settings.rate == 0.8)
        #expect(settings.pitch == 1.2)
        #expect(settings.volume == 0.7)
        #expect(settings.voiceIdentifier == "test-voice")
    }
}

// MARK: - Voice Info Tests

@Suite("VoiceInfo Tests")
struct VoiceInfoTests {
    
    @Test("VoiceInfo creates correct display name")
    func testDisplayName() {
        let voice = VoiceInfo(
            identifier: "com.apple.voice.compact.zh-CN.Tingting",
            name: "Tingting",
            language: "zh-CN"
        )
        
        #expect(voice.displayName == "Tingting (zh-CN)")
    }
    
    @Test("VoiceInfo is identifiable by identifier")
    func testIdentifiable() {
        let voice = VoiceInfo(
            identifier: "test-id",
            name: "Test",
            language: "en-US"
        )
        
        #expect(voice.id == "test-id")
    }
}
