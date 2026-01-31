//
//  TTSView.swift
//  mac-ai-toolkit
//
//  Text-to-Speech功能视图
//

import SwiftUI
import AVFoundation

struct TTSView: View {
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedVoice: String = ""
    @State private var rate: Float = 0.5
    @State private var pitch: Float = 1.0
    @State private var volume: Float = 1.0
    @State private var isSpeaking: Bool = false
    @State private var availableVoices: [TTSVoice] = []

    var body: some View {
        VStack(spacing: 20) {
            // Text input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("输入文本")
                        .font(.headline)
                    Spacer()
                    Button("从剪贴板粘贴") {
                        if let text = NSPasteboard.general.string(forType: .string) {
                            inputText = text
                        }
                    }
                    .buttonStyle(.bordered)
                }

                TextEditor(text: $inputText)
                    .font(.body)
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.3))
            }

            // Voice controls
            VStack(spacing: 16) {
                HStack {
                    Text("语音")
                    Picker("", selection: $selectedVoice) {
                        Text("系统默认").tag("")
                        ForEach(availableVoices) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }
                    .frame(width: 300)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("语速")
                        Slider(value: $rate, in: 0...1)
                        Text(String(format: "%.1f", rate))
                            .frame(width: 40)
                    }

                    HStack {
                        Text("音调")
                        Slider(value: $pitch, in: 0.5...2.0)
                        Text(String(format: "%.1f", pitch))
                            .frame(width: 40)
                    }

                    HStack {
                        Text("音量")
                        Slider(value: $volume, in: 0...1)
                        Text(String(format: "%.1f", volume))
                            .frame(width: 40)
                    }
                }
            }

            // Control buttons
            HStack {
                Button(isSpeaking ? "停止" : "播放") {
                    if isSpeaking {
                        stopSpeaking()
                    } else {
                        startSpeaking()
                    }
                }
                .disabled(inputText.isEmpty)
                .keyboardShortcut(.return, modifiers: .command)

                Button("导出音频") {
                    exportAudio()
                }
                .disabled(inputText.isEmpty)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("TTS 文字转语音")
        .onAppear {
            loadVoices()
            rate = appState.settings.ttsDefaultRate
            pitch = appState.settings.ttsDefaultPitch
            volume = appState.settings.ttsDefaultVolume
            selectedVoice = appState.settings.ttsDefaultVoice
        }
    }

    private func loadVoices() {
        availableVoices = TTSService.availableVoices()
    }

    private func startSpeaking() {
        guard !inputText.isEmpty else { return }

        isSpeaking = true

        Task {
            do {
                try await TTSService.shared.speak(
                    text: inputText,
                    voiceIdentifier: selectedVoice.isEmpty ? nil : selectedVoice,
                    rate: rate,
                    pitch: pitch,
                    volume: volume
                )

                await MainActor.run {
                    isSpeaking = false

                    // Add to history
                    HistoryService.shared.addRecord(
                        type: .tts,
                        content: inputText,
                        result: "[语音播放]"
                    )
                }
            } catch {
                await MainActor.run {
                    isSpeaking = false
                    print("TTS failed: \(error)")
                }
            }
        }
    }

    private func stopSpeaking() {
        TTSService.shared.stop()
        isSpeaking = false
    }

    private func exportAudio() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.audio]
        panel.nameFieldStringValue = "output.wav"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    try await TTSService.shared.synthesizeToFile(
                        text: inputText,
                        voiceIdentifier: selectedVoice.isEmpty ? nil : selectedVoice,
                        rate: rate,
                        pitch: pitch,
                        volume: volume,
                        outputURL: url,
                        format: .wav
                    )

                    await MainActor.run {
                        print("Audio exported to: \(url.path)")
                    }
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    TTSView()
        .environmentObject(AppState.shared)
}
