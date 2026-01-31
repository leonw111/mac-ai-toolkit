//
//  MacAIToolkitApp.swift
//  mac-ai-toolkit
//
//  Application entry point
//

import SwiftUI

@main
struct MacAIToolkitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        // Main window
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(appState)
                .preferredColorScheme(appState.settings.theme.colorScheme)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 900, height: 650)
        .commands {
            AppCommands()
        }

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(appState)
                .preferredColorScheme(appState.settings.theme.colorScheme)
        }

        // Menu bar extra
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isServerRunning ? "brain.head.profile" : "brain.head.profile")
        }
        .menuBarExtraStyle(.window)
    }
}
