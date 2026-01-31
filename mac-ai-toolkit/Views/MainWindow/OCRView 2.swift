//
//  OCRView.swift
//  mac-ai-toolkit
//
//  OCR功能视图
//

import SwiftUI
import UniformTypeIdentifiers

struct OCRView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedImage: NSImage?
    @State private var recognizedText: String = ""
    @State private var isProcessing: Bool = false
    @State private var selectedLanguage: String = "zh-Hans"
    @State private var recognitionLevel: OCRRecognitionLevel = .accurate
    @State private var isDragOver: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Image drop zone
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

                if let image = selectedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("拖拽图片到此处或点击选择")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("选择图片") {
                            selectImage()
                        }
                    }
                }
            }
            .frame(minHeight: 300)
            .onDrop(of: [.image], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
            .onTapGesture {
                if selectedImage == nil {
                    selectImage()
                }
            }

            // Controls
            HStack {
                Picker("语言", selection: $selectedLanguage) {
                    Text("简体中文").tag("zh-Hans")
                    Text("繁体中文").tag("zh-Hant")
                    Text("English").tag("en-US")
                    Text("日本語").tag("ja-JP")
                    Text("한국어").tag("ko-KR")
                }
                .frame(width: 150)

                Picker("识别模式", selection: $recognitionLevel) {
                    Text("精确").tag(OCRRecognitionLevel.accurate)
                    Text("快速").tag(OCRRecognitionLevel.fast)
                }
                .frame(width: 120)

                Spacer()

                if selectedImage != nil {
                    Button("清除") {
                        selectedImage = nil
                        recognizedText = ""
                    }
                    .disabled(isProcessing)
                }

                Button("识别文字") {
                    performOCR()
                }
                .disabled(selectedImage == nil || isProcessing)
                .keyboardShortcut(.return, modifiers: .command)
            }

            // Result
            if !recognizedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("识别结果")
                            .font(.headline)
                        Spacer()
                        Button("复制") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(recognizedText, forType: .string)
                        }
                        .buttonStyle(.bordered)
                    }

                    TextEditor(text: .constant(recognizedText))
                        .font(.body)
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.3))
                }
            }

            if isProcessing {
                ProgressView("识别中...")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("OCR 文字识别")
    }

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK, let url = panel.url {
            selectedImage = NSImage(contentsOf: url)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
            guard let data = data, let image = NSImage(data: data) else { return }

            DispatchQueue.main.async {
                self.selectedImage = image
            }
        }

        return true
    }

    private func performOCR() {
        guard let image = selectedImage else { return }

        isProcessing = true
        recognizedText = ""

        Task {
            do {
                let result = try await OCRService.shared.recognizeText(
                    from: image,
                    language: selectedLanguage,
                    level: recognitionLevel
                )

                await MainActor.run {
                    recognizedText = result.text
                    isProcessing = false

                    // Add to history
                    HistoryService.shared.addRecord(
                        type: .ocr,
                        content: "[图片]",
                        result: result.text,
                        metadata: [
                            "language": selectedLanguage,
                            "confidence": String(format: "%.2f", result.confidence)
                        ]
                    )

                    // Auto copy if enabled
                    if appState.settings.ocrAutoCopy {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(result.text, forType: .string)
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    recognizedText = "识别失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    OCRView()
        .environmentObject(AppState.shared)
}
