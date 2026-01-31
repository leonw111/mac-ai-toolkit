//
//  OCRView.swift
//  mac-ai-toolkit
//
//  OCR functionality view
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
    @State private var confidence: Double = 0.0
    @State private var isDragOver: Bool = false

    var body: some View {
        HSplitView {
            // Left panel - Image input
            VStack(spacing: 16) {
                // Drop zone
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
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("拖拽图片到此处")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("或")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("选择图片") {
                                selectImage()
                            }
                        }
                    }
                }
                .frame(minHeight: 300)
                .onDrop(of: [.image, .fileURL], isTargeted: $isDragOver) { providers in
                    handleDrop(providers: providers)
                }

                // Options
                HStack {
                    Picker("语言", selection: $selectedLanguage) {
                        Text("中文简体").tag("zh-Hans")
                        Text("中文繁体").tag("zh-Hant")
                        Text("English").tag("en-US")
                        Text("日本語").tag("ja-JP")
                        Text("한국어").tag("ko-KR")
                    }
                    .frame(width: 150)

                    Picker("模式", selection: $recognitionLevel) {
                        Text("精确").tag(OCRRecognitionLevel.accurate)
                        Text("快速").tag(OCRRecognitionLevel.fast)
                    }
                    .frame(width: 100)

                    Spacer()

                    Button("识别") {
                        performOCR()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil || isProcessing)
                }

                // Action buttons
                HStack {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("粘贴", systemImage: "doc.on.clipboard")
                    }

                    Button {
                        captureScreen()
                    } label: {
                        Label("截图", systemImage: "camera.viewfinder")
                    }

                    Spacer()

                    if selectedImage != nil {
                        Button("清除", role: .destructive) {
                            selectedImage = nil
                            recognizedText = ""
                            confidence = 0
                        }
                    }
                }
            }
            .padding()
            .frame(minWidth: 350)

            // Right panel - Results
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("识别结果")
                        .font(.headline)

                    Spacer()

                    if confidence > 0 {
                        Text("置信度: \(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if isProcessing {
                    VStack {
                        Spacer()
                        ProgressView("识别中...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    TextEditor(text: $recognizedText)
                        .font(.body)
                        .frame(maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                // Result actions
                HStack {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label("复制文本", systemImage: "doc.on.doc")
                    }
                    .disabled(recognizedText.isEmpty)

                    Button {
                        saveToFile()
                    } label: {
                        Label("保存文件", systemImage: "square.and.arrow.down")
                    }
                    .disabled(recognizedText.isEmpty)

                    Spacer()

                    Button("清空") {
                        recognizedText = ""
                    }
                    .disabled(recognizedText.isEmpty)
                }
            }
            .padding()
            .frame(minWidth: 350)
        }
        .navigationTitle("OCR 文字识别")
    }

    // MARK: - Actions

    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }

    private func loadImage(from url: URL) {
        if let image = NSImage(contentsOf: url) {
            selectedImage = image
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
                DispatchQueue.main.async {
                    if let data = item as? Data, let image = NSImage(data: data) {
                        selectedImage = image
                    } else if let url = item as? URL {
                        loadImage(from: url)
                    }
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                DispatchQueue.main.async {
                    if let data = item as? Data,
                       let path = String(data: data, encoding: .utf8),
                       let url = URL(string: path) {
                        loadImage(from: url)
                    }
                }
            }
            return true
        }

        return false
    }

    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general

        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            selectedImage = image
        }
    }

    private func captureScreen() {
        // TODO: Implement screen capture
        NotificationCenter.default.post(name: .screenshotOCR, object: nil)
    }

    private func performOCR() {
        guard let image = selectedImage else { return }

        isProcessing = true

        Task {
            do {
                let result = try await OCRService.shared.recognizeText(
                    from: image,
                    language: selectedLanguage,
                    level: recognitionLevel
                )
                await MainActor.run {
                    recognizedText = result.text
                    confidence = result.confidence
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

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(recognizedText, forType: .string)
    }

    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "ocr_result.txt"

        if panel.runModal() == .OK, let url = panel.url {
            try? recognizedText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

#Preview {
    OCRView()
        .environmentObject(AppState.shared)
}
