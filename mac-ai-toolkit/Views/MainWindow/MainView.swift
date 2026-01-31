//
//  MainView.swift
//  mac-ai-toolkit
//
//  Main window view with navigation
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SidebarTab = .ocr

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            switch selectedTab {
            case .ocr:
                OCRView()
            case .tts:
                TTSView()
            case .stt:
                STTView()
            case .history:
                HistoryView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    MainView()
        .environmentObject(AppState.shared)
}
