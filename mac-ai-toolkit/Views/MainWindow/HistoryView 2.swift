//
//  HistoryView.swift
//  mac-ai-toolkit
//
//  历史记录视图
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var selectedType: HistoryType? = nil
    @State private var selectedItems: Set<HistoryItem.ID> = []

    var filteredItems: [HistoryItem] {
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

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                SearchField(text: $searchText, prompt: "搜索历史记录")

                Picker("类型", selection: $selectedType) {
                    Text("全部").tag(nil as HistoryType?)
                    Text("OCR").tag(HistoryType.ocr as HistoryType?)
                    Text("TTS").tag(HistoryType.tts as HistoryType?)
                    Text("STT").tag(HistoryType.stt as HistoryType?)
                }
                .frame(width: 120)

                Spacer()

                Button(action: { deleteSelectedItems() }) {
                    Label("删除选中", systemImage: "trash")
                }
                .disabled(selectedItems.isEmpty)

                Button(action: { clearAllHistory() }) {
                    Label("清空全部", systemImage: "trash.fill")
                }
                .disabled(appState.historyItems.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // History list
            if filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无历史记录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedItems) {
                    ForEach(filteredItems) { item in
                        HistoryItemRow(item: item)
                            .tag(item.id)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("历史记录")
    }

    private func deleteSelectedItems() {
        let itemsToDelete = appState.historyItems.filter { selectedItems.contains($0.id) }
        HistoryService.shared.deleteItems(itemsToDelete)
        selectedItems.removeAll()
    }

    private func clearAllHistory() {
        HistoryService.shared.clearHistory()
        selectedItems.removeAll()
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type icon
                Image(systemName: item.type.icon)
                    .foregroundColor(.accentColor)

                // Timestamp
                Text(item.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(item.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Copy button
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.result, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
            }

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                if !item.content.isEmpty {
                    Text("输入: \(item.content)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(item.result)
                    .font(.body)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

extension HistoryType {
    var icon: String {
        switch self {
        case .ocr:
            return "doc.text.viewfinder"
        case .tts:
            return "speaker.wave.3"
        case .stt:
            return "mic"
        }
    }
}

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState.shared)
}
