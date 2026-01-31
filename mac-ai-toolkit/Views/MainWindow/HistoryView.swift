//
//  HistoryView.swift
//  mac-ai-toolkit
//
//  History records view
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedType: HistoryType? = nil
    @State private var searchText: String = ""
    @State private var selectedItems: Set<UUID> = []

    private var filteredHistory: [HistoryItem] {
        var items = appState.historyItems

        if let type = selectedType {
            items = items.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.result.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Filter
                Picker("类型", selection: $selectedType) {
                    Text("全部").tag(nil as HistoryType?)
                    Text("OCR").tag(HistoryType.ocr as HistoryType?)
                    Text("TTS").tag(HistoryType.tts as HistoryType?)
                    Text("STT").tag(HistoryType.stt as HistoryType?)
                }
                .frame(width: 120)

                // Search
                TextField("搜索历史记录...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Spacer()

                // Actions
                if !selectedItems.isEmpty {
                    Button("删除所选 (\(selectedItems.count))") {
                        deleteSelected()
                    }
                    .foregroundColor(.red)
                }

                Menu {
                    Button("导出全部") {
                        exportAll()
                    }
                    Divider()
                    Button("清空历史", role: .destructive) {
                        clearAll()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .padding()

            Divider()

            // History list
            if filteredHistory.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无历史记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("使用 OCR、TTS 或 STT 功能后，记录将显示在这里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(filteredHistory, selection: $selectedItems) { item in
                    HistoryItemRow(item: item)
                        .tag(item.id)
                        .contextMenu {
                            Button("复制结果") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.result, forType: .string)
                            }
                            Button("重新处理") {
                                reprocess(item)
                            }
                            Divider()
                            Button("删除", role: .destructive) {
                                delete(item)
                            }
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Status bar
            HStack {
                Text("\(filteredHistory.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle("历史记录")
    }

    // MARK: - Actions

    private func deleteSelected() {
        appState.historyItems.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
    }

    private func delete(_ item: HistoryItem) {
        appState.historyItems.removeAll { $0.id == item.id }
    }

    private func reprocess(_ item: HistoryItem) {
        // TODO: Re-process the history item
    }

    private func exportAll() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "history_export.json"

        if panel.runModal() == .OK, let url = panel.url {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601

            if let data = try? encoder.encode(filteredHistory) {
                try? data.write(to: url)
            }
        }
    }

    private func clearAll() {
        appState.historyItems.removeAll()
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: item.type.icon)
                .font(.title2)
                .foregroundColor(item.type.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                // Content preview
                Text(item.content.prefix(100) + (item.content.count > 100 ? "..." : ""))
                    .font(.body)
                    .lineLimit(2)

                // Result preview
                Text(item.result.prefix(50) + (item.result.count > 50 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                // Metadata
                HStack {
                    Text(item.type.rawValue.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.type.color.opacity(0.1))
                        .foregroundColor(item.type.color)
                        .cornerRadius(4)

                    Text(item.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState.shared)
}
