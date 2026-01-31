//
//  AppCommands.swift
//  mac-ai-toolkit
//
//  Custom menu commands
//

import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        // File menu additions
        CommandGroup(after: .newItem) {
            Divider()

            Button("Screenshot OCR") {
                NotificationCenter.default.post(name: .screenshotOCR, object: nil)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button("Clipboard OCR") {
                NotificationCenter.default.post(name: .clipboardOCR, object: nil)
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }

        // Help menu
        CommandGroup(replacing: .help) {
            Button("Mac AI Toolkit Help") {
                if let url = URL(string: "https://github.com/mac-ai-toolkit/docs") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            Button("Report Issue...") {
                if let url = URL(string: "https://github.com/mac-ai-toolkit/issues") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let screenshotOCR = Notification.Name("screenshotOCR")
    static let clipboardOCR = Notification.Name("clipboardOCR")
    static let quickTTS = Notification.Name("quickTTS")
    static let quickSTT = Notification.Name("quickSTT")
}
