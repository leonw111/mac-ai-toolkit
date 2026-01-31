//
//  SidebarView.swift
//  mac-ai-toolkit
//
//  Sidebar navigation
//

import SwiftUI

enum SidebarTab: String, CaseIterable, Identifiable {
    case ocr
    case tts
    case stt
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ocr: return "OCR"
        case .tts: return "TTS"
        case .stt: return "STT"
        case .history: return "历史"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .ocr: return "doc.text.viewfinder"
        case .tts: return "speaker.wave.3"
        case .stt: return "mic"
        case .history: return "clock"
        case .settings: return "gear"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $selectedTab) {
            Section {
                ForEach([SidebarTab.ocr, .tts, .stt], id: \.self) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }

            Section {
                Label(SidebarTab.history.title, systemImage: SidebarTab.history.icon)
                    .tag(SidebarTab.history)
            }

            Section {
                Label(SidebarTab.settings.title, systemImage: SidebarTab.settings.icon)
                    .tag(SidebarTab.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Mac AI Toolkit")
        .safeAreaInset(edge: .bottom) {
            // Server status indicator
            HStack {
                Circle()
                    .fill(appState.isServerRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.isServerRunning ? "服务运行中" : "服务已停止")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

#Preview {
    SidebarView(selectedTab: .constant(.ocr))
        .environmentObject(AppState.shared)
        .frame(width: 200)
}
