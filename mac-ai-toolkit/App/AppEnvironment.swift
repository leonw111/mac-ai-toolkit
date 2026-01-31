//
//  AppEnvironment.swift
//  mac-ai-toolkit
//
//  Dependency injection container
//  Created on 2026-01-31
//

import Foundation

/// 应用环境 - 依赖注入容器
///
/// 集中管理所有服务实例，便于测试和依赖管理
@MainActor
final class AppEnvironment {
    
    // MARK: - Shared Instance
    
    static let shared = AppEnvironment()
    
    // MARK: - Services
    
    let ocrService: OCRServiceProtocol
    let ttsService: TTSServiceProtocol
    let sttService: STTServiceProtocol
    let historyService: HistoryServiceProtocol
    let settingsService: SettingsServiceProtocol
    
    // MARK: - Managers
    
    let keyboardShortcutsManager: KeyboardShortcutsManager
    let notificationManager: NotificationManager
    
    // MARK: - API
    
    let httpServer: HTTPServer
    
    // MARK: - Initialization
    
    private init(
        ocrService: OCRServiceProtocol? = nil,
        ttsService: TTSServiceProtocol? = nil,
        sttService: STTServiceProtocol? = nil,
        historyService: HistoryServiceProtocol? = nil,
        settingsService: SettingsServiceProtocol? = nil
    ) {
        // 使用提供的服务或创建默认实例
        self.ocrService = ocrService ?? OCRService()
        self.ttsService = ttsService ?? TTSService()
        self.sttService = sttService ?? STTService()
        self.historyService = historyService ?? HistoryService.shared
        self.settingsService = settingsService ?? SettingsService.shared
        
        self.keyboardShortcutsManager = KeyboardShortcutsManager.shared
        self.notificationManager = NotificationManager.shared
        self.httpServer = HTTPServer.shared
    }
    
    // MARK: - Factory Methods
    
    /// 创建测试环境
    static func makeTest(
        ocrService: OCRServiceProtocol? = nil,
        ttsService: TTSServiceProtocol? = nil,
        sttService: STTServiceProtocol? = nil,
        historyService: HistoryServiceProtocol? = nil,
        settingsService: SettingsServiceProtocol? = nil
    ) -> AppEnvironment {
        return AppEnvironment(
            ocrService: ocrService,
            ttsService: ttsService,
            sttService: sttService,
            historyService: historyService,
            settingsService: settingsService
        )
    }
}

// MARK: - Environment Key

import SwiftUI

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.shared
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

extension View {
    /// 注入应用环境
    func withAppEnvironment(_ environment: AppEnvironment = .shared) -> some View {
        self.environment(\.appEnvironment, environment)
    }
}
