//
//  StatusItemManager.swift
//  mac-ai-toolkit
//
//  Menu bar status item management
//

import AppKit
import SwiftUI
import Combine

@MainActor
class StatusItemManager: ObservableObject {
    static let shared = StatusItemManager()

    private var statusItem: NSStatusItem?

    private init() {}

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.profile", accessibilityDescription: "Mac AI Toolkit")
        }
    }

    func updateIcon(isRunning: Bool) {
        // Update status item appearance based on server state
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: isRunning ? "brain.head.profile" : "brain.head.profile.slash",
                accessibilityDescription: isRunning ? "Mac AI Toolkit - Running" : "Mac AI Toolkit - Stopped"
            )
        }
    }
}
