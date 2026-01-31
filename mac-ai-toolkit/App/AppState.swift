//
//  AppState.swift
//  mac-ai-toolkit
//
//  Global application state
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published Properties

    @Published var isServerRunning: Bool = false
    @Published var settings: AppSettings
    @Published var historyItems: [HistoryItem] = []
    @Published var todayRequestCount: Int = 0

    // MARK: - Services

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        settings = AppSettings.load()

        // Load history
        historyItems = HistoryService.shared.items

        // Calculate today's request count
        updateTodayCount()

        // Observe history changes
        HistoryService.shared.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.historyItems = items
                self?.updateTodayCount()
            }
            .store(in: &cancellables)

        // Observe server request count
        HTTPServer.shared.$requestCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.todayRequestCount = count
            }
            .store(in: &cancellables)

        // Save settings when they change
        $settings
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { settings in
                settings.save()
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    func startServer() async throws {
        try await HTTPServer.shared.start(port: settings.apiPort)
        isServerRunning = true
    }

    func stopServer() async {
        await HTTPServer.shared.stop()
        isServerRunning = false
    }

    func restartServer() async throws {
        await stopServer()
        try await startServer()
    }

    // MARK: - Private

    private func updateTodayCount() {
        let today = Calendar.current.startOfDay(for: Date())
        todayRequestCount = historyItems.filter { $0.timestamp >= today }.count
    }
}

// MARK: - AppSettings

struct AppSettings: Codable {
    // General
    var launchAtLogin: Bool = false
    var theme: AppTheme = .system
    var language: String = "zh-Hans"

    // API
    var apiEnabled: Bool = false
    var apiPort: Int = 19527
    var apiKey: String = ""

    // OCR
    var ocrDefaultLanguage: String = "zh-Hans"
    var ocrRecognitionLevel: OCRRecognitionLevel = .accurate
    var ocrAutoCopy: Bool = true

    // TTS
    var ttsDefaultVoice: String = ""
    var ttsDefaultRate: Float = 0.5
    var ttsDefaultPitch: Float = 1.0
    var ttsDefaultVolume: Float = 1.0

    // STT
    var sttDefaultLanguage: String = "zh-CN"
    var sttLocalOnly: Bool = false
    var sttAutoCopy: Bool = true

    // History
    var historyRetentionDays: Int = 30
    var historyMaxItems: Int = 1000

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "app_settings") else {
            return AppSettings()
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error)")
            return AppSettings()
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            UserDefaults.standard.set(data, forKey: "app_settings")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

enum AppTheme: String, Codable {
    case system
    case light
    case dark
}

// MARK: - Preview Support

extension AppState {
    static var preview: AppState {
        let state = AppState.shared
        state.isServerRunning = true
        state.todayRequestCount = 42
        return state
    }
}
