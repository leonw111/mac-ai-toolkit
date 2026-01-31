//
//  TTSView.swift
//  mac-ai-toolkit
//
//  Text-to-Speech functionality view
//  Created on 2026-01-31
//

import SwiftUI
import AVFoundation

/// TTS 文字转语音视图
///
/// 提供文字转语音功能的用户界面
struct TTSView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: TTSViewModel
    @State private var showingSavePanel = false
    @State private var exportFormat: AudioExportFormat = .mp3
    
    // MARK: - Initialization
    
    init(viewModel: TTSViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? TTSViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 文本输入区域
                textInputSection
                
                Divider()
                
                // 语音选择
                voiceSelectionSection
                
                // 参数控制
                parametersSection
                
                Divider()
                
                // 操作按钮
                actionButtonsSection
                
                // 状态提示
                if viewModel.state != .idle {
                    statusSection
                }
            }
            .padding()
        }
        .navigationTitle("TTS 文字转语音")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                toolbarButtons
            }
        }
        .alert(isPresented: $showingErrorAlert) {
            errorAlert
        }
        .task {
            await viewModel.loadAvailableVoices()
        }
    }
    
    // MARK: - View Components
    
    /// 文本输入区域
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("输入文本")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.characterCount) 字符")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $viewModel.inputText)
                .font(.body)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.inputText.isEmpty {
                        Text("在此输入要转换的文字...")
                            .foregroundStyle(.tertiary)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
            
            HStack {
                Button("从剪贴板粘贴") {
                    viewModel.pasteFromClipboard()
                }
                .buttonStyle(.link)
                
                Spacer()
                
                if !viewModel.inputText.isEmpty {
                    Button("清空", role: .destructive) {
                        viewModel.clearInput()
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }
    
    /// 语音选择区域
    private var voiceSelectionSection: some View {
        HStack(spacing: 16) {
            Text("语音")
                .frame(width: 80, alignment: .leading)
            
            Picker("选择语音", selection: $viewModel.selectedVoiceIdentifier) {
                Text("系统默认").tag("")
                
                ForEach(viewModel.availableVoices) { voice in
                    Text(voice.displayName)
                        .tag(voice.identifier)
                }
            }
            .frame(maxWidth: 400)
            .help("选择朗读语音")
        }
    }
    
    /// 参数控制区域
    private var parametersSection: some View {
        VStack(spacing: 16) {
            ParameterSlider(
                label: "语速",
                value: $viewModel.rate,
                range: 0...1
            )
            
            ParameterSlider(
                label: "音调",
                value: $viewModel.pitch,
                range: 0.5...2.0
            )
            
            ParameterSlider(
                label: "音量",
                value: $viewModel.volume,
                range: 0...1
            )
        }
    }
    
    /// 操作按钮区域
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            // 播放/停止按钮
            Button {
                Task {
                    if viewModel.isPlaying {
                        await viewModel.stopPlayback()
                    } else {
                        await viewModel.playPreview()
                    }
                }
            } label: {
                Label(
                    viewModel.isPlaying ? "停止" : "预览播放",
                    systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
                )
                .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSpeak)
            .help(viewModel.isPlaying ? "停止播放" : "预览朗读效果")
            
            Spacer()
            
            // 导出按钮
            Menu {
                ForEach(AudioExportFormat.allCases, id: \.self) { format in
                    Button("导出为 \(format.displayName)") {
                        exportFormat = format
                        showSavePanel()
                    }
                }
            } label: {
                Label("导出音频", systemImage: "square.and.arrow.down")
            }
            .disabled(!viewModel.canSpeak)
            .help("将文字合成为音频文件")
        }
    }
    
    /// 状态显示区域
    private var statusSection: some View {
        Group {
            switch viewModel.state {
            case .loading:
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("处理中...")
                        .foregroundStyle(.secondary)
                }
                
            case .success:
                Label("完成", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: viewModel.state)
                
            case .error(let error):
                Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                
            case .idle:
                EmptyView()
            }
        }
        .padding(.vertical, 8)
    }
    
    /// 工具栏按钮
    private var toolbarButtons: some View {
        Group {
            Button {
                Task {
                    await viewModel.resetToDefaults()
                }
            } label: {
                Label("重置", systemImage: "arrow.counterclockwise")
            }
            .help("重置为默认设置")
            
            Button {
                Task {
                    await viewModel.saveAsDefaults()
                }
            } label: {
                Label("保存为默认", systemImage: "bookmark")
            }
            .help("将当前设置保存为默认值")
        }
    }
    
    // MARK: - Helper Properties
    
    private var showingErrorAlert: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }
    
    private var errorAlert: Alert {
        Alert(
            title: Text("操作失败"),
            message: Text(viewModel.error?.localizedDescription ?? ""),
            primaryButton: .default(Text("重试")) {
                Task {
                    await viewModel.playPreview()
                }
            },
            secondaryButton: .cancel(Text("取消"))
        )
    }
    
    // MARK: - Private Methods
    
    private func showSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: exportFormat.fileExtension)!]
        panel.nameFieldStringValue = "tts_output.\(exportFormat.fileExtension)"
        panel.message = "选择保存位置"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            Task {
                await viewModel.exportAudio(format: exportFormat, to: url)
            }
        }
    }
}

// MARK: - Parameter Slider Component

/// 参数滑块组件
private struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 16) {
            Text(label)
                .frame(width: 80, alignment: .leading)
            
            Slider(value: $value, in: range)
                .frame(maxWidth: 400)
            
            Text(String(format: "%.2f", value))
                .font(.body.monospacedDigit())
                .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Preview

#Preview("默认") {
    NavigationStack {
        TTSView()
    }
    .frame(width: 700, height: 600)
}

#Preview("带文本") {
    NavigationStack {
        let viewModel = TTSViewModel()
        viewModel.inputText = "这是一段测试文本，用于演示文字转语音功能。"
        return TTSView(viewModel: viewModel)
    }
    .frame(width: 700, height: 600)
}
