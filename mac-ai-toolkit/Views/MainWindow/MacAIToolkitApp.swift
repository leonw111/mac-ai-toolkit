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
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 Mac AI Toolkit") {
                    NSApp.orderFrontStandardAboutPanel()
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isServerRunning ? "brain.head.profile" : "brain.head.profile.slash")
        }
        .menuBarExtraStyle(.window)
    }
}
