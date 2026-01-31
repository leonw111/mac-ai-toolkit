//
//  MenuBarView.swift
//  mac-ai-toolkit
//
//  Menu bar popup view
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status indicator
            HStack {
                Circle()
                    .fill(appState.isServerRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.isServerRunning ? "服务运行中" : "服务已停止")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Quick actions
            MenuBarButton(
                title: "快速 OCR（截图）",
                icon: "doc.text.viewfinder",
                shortcut: "⌘⇧O"
            ) {
                NotificationCenter.default.post(name: .screenshotOCR, object: nil)
            }

            MenuBarButton(
                title: "快速 TTS（剪贴板）",
                icon: "speaker.wave.3",
                shortcut: "⌘⇧T"
            ) {
                NotificationCenter.default.post(name: .quickTTS, object: nil)
            }

            MenuBarButton(
                title: "快速 STT（录音）",
                icon: "mic",
                shortcut: "⌘⇧S"
            ) {
                NotificationCenter.default.post(name: .quickSTT, object: nil)
            }

            Divider()

            // Statistics
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.secondary)
                Text("今日统计: \(appState.todayRequestCount) 次请求")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Window & Settings
            MenuBarButton(
                title: "打开主窗口",
                icon: "macwindow",
                shortcut: "⌘⇧M"
            ) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main")
            }

            MenuBarButton(
                title: "设置...",
                icon: "gear",
                shortcut: nil
            ) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }

            MenuBarButton(
                title: "帮助文档",
                icon: "book",
                shortcut: nil
            ) {
                if let url = URL(string: "https://github.com/mac-ai-toolkit/docs") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider()

            // Quit
            MenuBarButton(
                title: "退出",
                icon: "power",
                shortcut: nil
            ) {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 220)
    }
}

// MARK: - Menu Bar Button

struct MenuBarButton: View {
    let title: String
    let icon: String
    let shortcut: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState.shared)
}
