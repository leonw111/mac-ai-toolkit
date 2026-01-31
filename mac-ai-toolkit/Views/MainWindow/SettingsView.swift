//
//  SettingsView.swift
//  mac-ai-toolkit
//
//  Settings panel
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }

            APISettingsView()
                .tabItem {
                    Label("API 服务", systemImage: "network")
                }

            OCRSettingsView()
                .tabItem {
                    Label("OCR", systemImage: "doc.text.viewfinder")
                }

            TTSSettingsView()
                .tabItem {
                    Label("TTS", systemImage: "speaker.wave.3")
                }

            STTSettingsView()
                .tabItem {
                    Label("STT", systemImage: "mic")
                }

            ShortcutsSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }

            StorageSettingsView()
                .tabItem {
                    Label("存储", systemImage: "internaldrive")
                }
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Toggle("开机自动启动", isOn: $appState.settings.launchAtLogin)
                    .onChange(of: appState.settings.launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Picker("主题", selection: $appState.settings.theme) {
                    Text("跟随系统").tag(AppTheme.system)
                    Text("浅色").tag(AppTheme.light)
                    Text("深色").tag(AppTheme.dark)
                }

                Picker("语言", selection: $appState.settings.language) {
                    Text("简体中文").tag("zh-Hans")
                    Text("English").tag("en")
                }
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        // TODO: Use SMAppService for launch at login
    }
}

// MARK: - API Settings

struct APISettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Toggle("启用 API 服务", isOn: $appState.settings.apiEnabled)

                HStack {
                    Text("端口号")
                    TextField("", value: $appState.settings.apiPort, format: .number)
                        .frame(width: 80)
                    Text("默认: 19527")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                HStack {
                    Text("认证密钥")
                    SecureField("", text: $appState.settings.apiAuthKey)
                        .frame(maxWidth: 200)
                    Text("留空则不需要认证")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } header: {
                Text("HTTP API")
            }

            Section {
                HStack {
                    Text("服务地址")
                    Text("http://localhost:\(appState.settings.apiPort)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("复制") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString("http://localhost:\(appState.settings.apiPort)", forType: .string)
                    }
                }
            } header: {
                Text("连接信息")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - OCR Settings

struct OCRSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Picker("默认语言", selection: $appState.settings.ocrDefaultLanguage) {
                    Text("中文简体").tag("zh-Hans")
                    Text("中文繁体").tag("zh-Hant")
                    Text("English").tag("en-US")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }

                Picker("识别模式", selection: $appState.settings.ocrRecognitionLevel) {
                    Text("精确模式 (推荐)").tag(OCRRecognitionLevel.accurate)
                    Text("快速模式").tag(OCRRecognitionLevel.fast)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - TTS Settings

struct TTSSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var availableVoices: [String] = []

    var body: some View {
        Form {
            Section {
                Picker("默认语音", selection: $appState.settings.ttsDefaultVoice) {
                    Text("系统默认").tag("")
                    ForEach(availableVoices, id: \.self) { voice in
                        Text(voice).tag(voice)
                    }
                }

                HStack {
                    Text("默认语速")
                    Slider(value: $appState.settings.ttsDefaultRate, in: 0...1)
                    Text(String(format: "%.1f", appState.settings.ttsDefaultRate))
                        .frame(width: 30)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadVoices()
        }
    }

    private func loadVoices() {
        // TODO: Load available voices from AVSpeechSynthesizer
    }
}

// MARK: - STT Settings

struct STTSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Picker("默认语言", selection: $appState.settings.sttDefaultLanguage) {
                    Text("中文普通话").tag("zh-CN")
                    Text("中文 (台湾)").tag("zh-TW")
                    Text("English (US)").tag("en-US")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }

                Toggle("优先使用本地识别", isOn: $appState.settings.sttLocalOnly)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shortcuts Settings

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                ShortcutRow(label: "截图 OCR", shortcut: "⌘ + Shift + O")
                ShortcutRow(label: "剪贴板 OCR", shortcut: "⌘ + Shift + V")
                ShortcutRow(label: "快速 TTS", shortcut: "⌘ + Shift + T")
                ShortcutRow(label: "快速 STT", shortcut: "⌘ + Shift + S")
                ShortcutRow(label: "打开主窗口", shortcut: "⌘ + Shift + M")
            } header: {
                Text("全局快捷键")
            } footer: {
                Text("点击快捷键区域可自定义")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutRow: View {
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - Storage Settings

struct StorageSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Stepper("历史记录保留 \(appState.settings.historyRetentionDays) 天",
                        value: $appState.settings.historyRetentionDays,
                        in: 1...365)

                HStack {
                    Text("默认导出路径")
                    Text(appState.settings.defaultExportPath.isEmpty ? "未设置" : appState.settings.defaultExportPath)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("选择...") {
                        selectExportPath()
                    }
                }
            }

            Section {
                Button("清除所有历史记录", role: .destructive) {
                    // TODO: Clear history
                }
            }
        }
        .formStyle(.grouped)
    }

    private func selectExportPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            appState.settings.defaultExportPath = url.path
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
}
