//
//  AppDelegate.swift
//  mac-ai-toolkit
//
//  Application lifecycle management
//

import AppKit
import SwiftUI
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "AppDelegate")
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("应用启动")
        
        Task {
            await setupApplication()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.info("应用退出")
        
        Task {
            await cleanup()
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 关闭主窗口后继续在菜单栏运行
        false
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
    
    // MARK: - Setup
    
    private func setupApplication() async {
        // 注册全局快捷键
        KeyboardShortcutsManager.shared.registerDefaultShortcuts()
        
        // 设置通知监听
        setupNotificationObservers()
        
        // 启动 HTTP 服务器（如果启用）
        await startServerIfNeeded()
        
        // 清理旧历史记录
        await cleanOldHistory()
    }
    
    private func startServerIfNeeded() async {
        guard AppState.shared.settings.apiEnabled else { return }
        
        do {
            try await HTTPServer.shared.start(port: AppState.shared.settings.apiPort)
            await MainActor.run {
                AppState.shared.isServerRunning = true
            }
            logger.info("HTTP 服务器已启动")
        } catch {
            logger.error("启动 HTTP 服务器失败: \(error.localizedDescription)")
        }
    }
    
    private func cleanup() async {
        // 停止服务器
        await HTTPServer.shared.stop()
        
        // 注销快捷键
        KeyboardShortcutsManager.shared.unregisterAll()
        
        // 保存设置
        AppState.shared.settings.save()
        
        logger.info("清理完成")
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        
        center.addObserver(forName: .screenshotOCR, object: nil, queue: .main) { [weak self] _ in
            self?.handleScreenshotOCR()
        }
        
        center.addObserver(forName: .clipboardOCR, object: nil, queue: .main) { [weak self] _ in
            self?.handleClipboardOCR()
        }
        
        center.addObserver(forName: .quickTTS, object: nil, queue: .main) { [weak self] _ in
            self?.handleQuickTTS()
        }
        
        center.addObserver(forName: .quickSTT, object: nil, queue: .main) { [weak self] _ in
            self?.handleQuickSTT()
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleScreenshotOCR() {
        logger.info("截图 OCR 触发")
        // TODO: 实现截图捕获和 OCR
    }
    
    private func handleClipboardOCR() {
        logger.info("剪贴板 OCR 触发")
        
        guard let image = ImageUtils.imageFromClipboard() else {
            logger.warning("剪贴板中没有图像")
            return
        }
        
        Task {
            do {
                let result = try await OCRService.shared.recognizeText(from: image)
                
                await MainActor.run {
                    // 复制结果到剪贴板
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result.text, forType: .string)
                    
                    // 添加到历史记录
                    HistoryService.shared.addRecord(
                        type: .ocr,
                        content: "[剪贴板图像]",
                        result: result.text
                    )
                }
                
                logger.info("OCR 识别成功")
            } catch {
                logger.error("OCR 识别失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleQuickTTS() {
        logger.info("快速 TTS 触发")
        
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            logger.warning("剪贴板中没有文本")
            return
        }
        
        Task {
            do {
                try await TTSService.shared.speak(text: text)
                
                await MainActor.run {
                    HistoryService.shared.addRecord(
                        type: .tts,
                        content: text,
                        result: "[音频播放]"
                    )
                }
                
                logger.info("TTS 播放成功")
            } catch {
                logger.error("TTS 播放失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleQuickSTT() {
        logger.info("快速 STT 触发")
        // TODO: 实现快速录音
    }
    
    // MARK: - Maintenance
    
    private func cleanOldHistory() async {
        let retentionDays = AppState.shared.settings.historyRetentionDays
        
        await MainActor.run {
            HistoryService.shared.clearHistory(olderThan: retentionDays)
        }
        
        logger.info("清理了 \(retentionDays) 天前的历史记录")
    }
}
// MARK: - Notification Names

extension Notification.Name {
    static let screenshotOCR = Notification.Name("screenshotOCR")
    static let clipboardOCR = Notification.Name("clipboardOCR")
    static let quickTTS = Notification.Name("quickTTS")
    static let quickSTT = Notification.Name("quickSTT")
}

