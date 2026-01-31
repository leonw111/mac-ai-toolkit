//
//  HistoryService.swift
//  mac-ai-toolkit
//
//  History records management
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HistoryService: ObservableObject {
    static let shared = HistoryService()

    @Published private(set) var items: [HistoryItem] = []

    private let storageKey = "mac_ai_toolkit_history"
    private let maxItems = 1000

    private init() {
        loadHistory()
    }

    // MARK: - Public API

    func addRecord(type: HistoryType, content: String, result: String, metadata: [String: String] = [:]) {
        let item = HistoryItem(
            type: type,
            content: content,
            result: result,
            timestamp: Date(),
            metadata: metadata
        )

        items.insert(item, at: 0)

        // Limit history size
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        saveHistory()
    }

    func deleteItem(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func deleteItems(_ itemsToDelete: [HistoryItem]) {
        let idsToDelete = Set(itemsToDelete.map(\.id))
        items.removeAll { idsToDelete.contains($0.id) }
        saveHistory()
    }

    func clearHistory() {
        items.removeAll()
        saveHistory()
    }

    func clearHistory(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        items.removeAll { $0.timestamp < cutoffDate }
        saveHistory()
    }

    func search(query: String, type: HistoryType? = nil) -> [HistoryItem] {
        var results = items

        if let type = type {
            results = results.filter { $0.type == type }
        }

        if !query.isEmpty {
            results = results.filter {
                $0.content.localizedCaseInsensitiveContains(query) ||
                $0.result.localizedCaseInsensitiveContains(query)
            }
        }

        return results
    }

    func todayCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return items.filter { $0.timestamp >= today }.count
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            items = try decoder.decode([HistoryItem].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save history: \(error)")
        }
    }

    // MARK: - Export

    func export() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(items)
    }

    func `import`(from data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importedItems = try decoder.decode([HistoryItem].self, from: data)
        items.append(contentsOf: importedItems)
        items.sort { $0.timestamp > $1.timestamp }
        saveHistory()
    }
}
// MARK: - Supporting Types

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let type: HistoryType
    let content: String
    let result: String
    let timestamp: Date
    let metadata: [String: String]

    init(
        type: HistoryType,
        content: String,
        result: String,
        timestamp: Date,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.result = result
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

enum HistoryType: String, Codable {
    case ocr
    case tts
    case stt
}

