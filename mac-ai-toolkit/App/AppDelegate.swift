//
//  AppDelegate.swift
//  mac-ai-toolkit
//
//  Application lifecycle management
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register global keyboard shortcuts
        KeyboardShortcutsManager.shared.registerDefaultShortcuts()

        // Start HTTP server if enabled
        if AppState.shared.settings.apiEnabled {
            Task {
                do {
                    try await HTTPServer.shared.start(port: AppState.shared.settings.apiPort)
                    await MainActor.run {
                        AppState.shared.isServerRunning = true
                    }
                } catch {
                    print("Failed to start HTTP server: \(error)")
                }
            }
        }

        // Setup notification observers
        setupNotificationObservers()

        // Clean old history if needed
        Task {
            await cleanOldHistory()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Stop HTTP server
        Task {
            await HTTPServer.shared.stop()
        }

        // Unregister shortcuts
        KeyboardShortcutsManager.shared.unregisterAll()

        // Save settings
        AppState.shared.settings.save()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in menu bar after closing main window
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Private

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .screenshotOCR,
            object: nil,
            queue: .main
        ) { _ in
            self.handleScreenshotOCR()
        }

        NotificationCenter.default.addObserver(
            forName: .clipboardOCR,
            object: nil,
            queue: .main
        ) { _ in
            self.handleClipboardOCR()
        }

        NotificationCenter.default.addObserver(
            forName: .quickTTS,
            object: nil,
            queue: .main
        ) { _ in
            self.handleQuickTTS()
        }

        NotificationCenter.default.addObserver(
            forName: .quickSTT,
            object: nil,
            queue: .main
        ) { _ in
            self.handleQuickSTT()
        }
    }

    private func handleScreenshotOCR() {
        // TODO: Implement screenshot capture and OCR
        print("Screenshot OCR triggered")
    }

    private func handleClipboardOCR() {
        guard let image = ImageUtils.imageFromClipboard() else {
            print("No image in clipboard")
            return
        }

        Task {
            do {
                let result = try await OCRService.shared.recognizeText(from: image)
                await MainActor.run {
                    // Copy result to clipboard
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result.text, forType: .string)

                    // Add to history
                    HistoryService.shared.addRecord(
                        type: .ocr,
                        content: "[Clipboard Image]",
                        result: result.text
                    )
                }
            } catch {
                print("OCR failed: \(error)")
            }
        }
    }

    private func handleQuickTTS() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            print("No text in clipboard")
            return
        }

        Task {
            do {
                try await TTSService.shared.speak(text: text)

                await MainActor.run {
                    HistoryService.shared.addRecord(
                        type: .tts,
                        content: text,
                        result: "[Audio playback]"
                    )
                }
            } catch {
                print("TTS failed: \(error)")
            }
        }
    }

    private func handleQuickSTT() {
        // TODO: Implement quick recording
        print("Quick STT triggered")
    }

    private func cleanOldHistory() async {
        let retentionDays = AppState.shared.settings.historyRetentionDays
        await MainActor.run {
            HistoryService.shared.clearHistory(olderThan: retentionDays)
        }
    }
}
