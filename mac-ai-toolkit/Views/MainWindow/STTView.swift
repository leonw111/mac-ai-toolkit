//
//  STTView.swift
//  mac-ai-toolkit
//
//  Speech-to-Text functionality view
//

import SwiftUI
import UniformTypeIdentifiers

struct STTView: View {
    @EnvironmentObject var appState: AppState
    @State private var isRecording: Bool = false
    @State private var recognizedText: String = ""
    @State private var segments: [TranscriptionSegment] = []
    @State private var selectedLanguage: String = "zh-CN"
    @State private var localOnly: Bool = false
    @State private var isProcessing: Bool = false
    @State private var selectedAudioFile: URL?
    @State private var isDragOver: Bool = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            // Input section
            HStack(spacing: 20) {
                // Recording button
                VStack(spacing: 12) {
                    Button {
                        toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.accentColor)
                                .frame(width: 80, height: 80)

                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    if isRecording {
                        Text(formatDuration(recordingDuration))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                    } else {
                        Text("点击录音")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 120)

                Text("或")
                    .foregroundColor(.secondary)

                // File drop zone
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDragOver ? Color.accentColor : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDragOver ? Color.accentColor.opacity(0.1) : Color.clear)
                        )

                    if let url = selectedAudioFile {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .font(.system(size: 32))
                                .foregroundColor(.accentColor)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Button("移除") {
                                selectedAudioFile = nil
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("拖拽音频文件到此处")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("选择文件") {
                                selectAudioFile()
                            }
                            .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .onDrop(of: [.audio, .fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                }
            }
            .padding(.horizontal)

            // Options
            HStack {
                Picker("语言", selection: $selectedLanguage) {
                    Text("中文普通话").tag("zh-CN")
                    Text("中文 (台湾)").tag("zh-TW")
                    Text("English (US)").tag("en-US")
                    Text("English (UK)").tag("en-GB")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }
                .frame(width: 180)

                Toggle("仅本地识别", isOn: $localOnly)

                Spacer()

                Button("开始识别") {
                    performRecognition()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAudioFile == nil || isProcessing)
            }
            .padding(.horizontal)

            Divider()

            // Results section
            VStack(alignment: .leading, spacing: 8) {
                Text("识别结果")
                    .font(.headline)

                if isProcessing {
                    VStack {
                        Spacer()
                        ProgressView("识别中...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if segments.isEmpty {
                    ScrollView {
                        TextEditor(text: $recognizedText)
                            .font(.body)
                            .frame(maxHeight: .infinity)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                } else {
                    // Segmented view with timestamps
                    List(segments) { segment in
                        HStack(alignment: .top) {
                            Text("[\(formatTimestamp(segment.timestamp))]")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)

                            Text(segment.text)
                                .font(.body)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.horizontal)

            // Action buttons
            HStack {
                Button {
                    copyAllText()
                } label: {
                    Label("复制全部", systemImage: "doc.on.doc")
                }
                .disabled(recognizedText.isEmpty && segments.isEmpty)

                Button {
                    exportAsTxt()
                } label: {
                    Label("导出 TXT", systemImage: "doc.text")
                }
                .disabled(recognizedText.isEmpty && segments.isEmpty)

                Button {
                    exportAsSrt()
                } label: {
                    Label("导出 SRT", systemImage: "captions.bubble")
                }
                .disabled(segments.isEmpty)

                Spacer()

                Button("清空") {
                    recognizedText = ""
                    segments = []
                }
                .disabled(recognizedText.isEmpty && segments.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationTitle("STT 语音转文字")
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        recordingDuration = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }

        Task {
            do {
                try await STTService.shared.startRecording(language: selectedLanguage)
            } catch {
                await MainActor.run {
                    isRecording = false
                    timer?.invalidate()
                }
            }
        }
    }

    private func stopRecording() {
        isRecording = false
        timer?.invalidate()
        timer = nil

        Task {
            do {
                let result = try await STTService.shared.stopRecording()
                await MainActor.run {
                    recognizedText = result.text
                    segments = result.segments
                }
            } catch {
                // Handle error
            }
        }
    }

    private func selectAudioFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mpeg4Audio, .wav, .mp3]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedAudioFile = panel.url
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let path = String(data: data, encoding: .utf8),
                       let url = URL(string: path) {
                        selectedAudioFile = url
                    }
                }
            }
            return true
        }

        return false
    }

    private func performRecognition() {
        guard let url = selectedAudioFile else { return }

        isProcessing = true

        Task {
            do {
                let result = try await STTService.shared.transcribe(
                    audioURL: url,
                    language: selectedLanguage,
                    localOnly: localOnly
                )
                await MainActor.run {
                    recognizedText = result.text
                    segments = result.segments
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    recognizedText = "识别失败: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }

    private func copyAllText() {
        let text = segments.isEmpty ? recognizedText : segments.map(\.text).joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func exportAsTxt() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "transcription.txt"

        if panel.runModal() == .OK, let url = panel.url {
            let text = segments.isEmpty ? recognizedText : segments.map(\.text).joined(separator: "\n")
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func exportAsSrt() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "srt") ?? .plainText]
        panel.nameFieldStringValue = "transcription.srt"

        if panel.runModal() == .OK, let url = panel.url {
            var srtContent = ""
            for (index, segment) in segments.enumerated() {
                let startTime = formatSrtTime(segment.timestamp)
                let endTime = formatSrtTime(segment.timestamp + segment.duration)
                srtContent += "\(index + 1)\n"
                srtContent += "\(startTime) --> \(endTime)\n"
                srtContent += "\(segment.text)\n\n"
            }
            try? srtContent.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Formatting

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatSrtTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time * 1000).truncatingRemainder(dividingBy: 1000))
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}

#Preview {
    STTView()
        .environmentObject(AppState.shared)
}
