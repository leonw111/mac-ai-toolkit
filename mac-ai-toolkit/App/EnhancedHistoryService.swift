//
//  EnhancedHistoryService.swift
//  mac-ai-toolkit
//
//  Enhanced history management service with TTS support
//

import Foundation
import Combine

@MainActor
final class EnhancedHistoryService: HistoryServiceProtocol, ObservableObject {
    static let shared = EnhancedHistoryService()
    
    @Published private(set) var items: [HistoryItem] = []
    @Published private(set) var statistics: HistoryStatistics = HistoryStatistics(items: [])
    
    private let fileManager: FileManager
    private let storageURL: URL
    private let maxItems: Int
    private let retentionDays: Int
    
    // MARK: - Initialization
    
    private init(
        fileManager: FileManager = .default,
        maxItems: Int = 1000,
        retentionDays: Int = 30
    ) {
        self.fileManager = fileManager
        self.maxItems = maxItems
        self.retentionDays = retentionDays
        
        // 设置存储路径
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let appDir = appSupport.appendingPathComponent("mac-ai-toolkit", isDirectory: true)
        self.storageURL = appDir.appendingPathComponent("history.json")
        
        // 创建目录
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        // 加载历史
        loadHistory()
        
        // 定期清理
        scheduleCleanup()
    }
    
    // MARK: - Public Methods
    
    func addTTSHistory(_ item: TTSHistoryItem) async {
        let metadata: [String: String] = [
            "voice": item.voice,
            "language": item.language,
            "action": item.action.description
        ]
        
        let historyItem = HistoryItem(
            type: .tts,
            content: item.text,
            result: item.action.resultDescription,
            timestamp: item.timestamp,
            metadata: metadata
        )
        
        await addItem(historyItem)
    }
    
    func addItem(_ item: HistoryItem) async {
        items.insert(item, at: 0)
        
        // 限制数量
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
        
        // 更新统计
        updateStatistics()
        
        // 保存
        await saveHistory()
    }
    
    func removeItem(_ item: HistoryItem) async {
        items.removeAll { $0.id == item.id }
        updateStatistics()
        await saveHistory()
    }
    
    func removeItems(_ itemsToRemove: [HistoryItem]) async {
        let idsToRemove = Set(itemsToRemove.map { $0.id })
        items.removeAll { idsToRemove.contains($0.id) }
        updateStatistics()
        await saveHistory()
    }
    
    func clearHistory(ofType type: HistoryType? = nil) async {
        if let type = type {
            items.removeAll { $0.type == type }
        } else {
            items.removeAll()
        }
        updateStatistics()
        await saveHistory()
    }
    
    func search(query: String, type: HistoryType? = nil) -> [HistoryItem] {
        var filteredItems = items
        
        if let type = type {
            filteredItems = filteredItems.filter { $0.type == type }
        }
        
        if !query.isEmpty {
            filteredItems = filteredItems.filter {
                $0.content.localizedCaseInsensitiveContains(query) ||
                $0.result.localizedCaseInsensitiveContains(query)
            }
        }
        
        return filteredItems
    }
    
    func itemsGroupedByDate() -> [(Date, [HistoryItem])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Private Methods
    
    private func loadHistory() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            items = try decoder.decode([HistoryItem].self, from: data)
            updateStatistics()
        } catch {
            print("❌ Failed to load history: \(error)")
        }
    }
    
    private func saveHistory() async {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("❌ Failed to save history: \(error)")
        }
    }
    
    private func updateStatistics() {
        statistics = HistoryStatistics(items: items)
    }
    
    private func scheduleCleanup() {
        Task {
            while true {
                try? await Task.sleep(for: .seconds(3600)) // 每小时清理一次
                await cleanup()
            }
        }
    }
    
    private func cleanup() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date())!
        let countBefore = items.count
        
        items.removeAll { $0.timestamp < cutoffDate }
        
        if items.count < countBefore {
            print("🧹 Cleaned up \(countBefore - items.count) old history items")
            updateStatistics()
            await saveHistory()
        }
    }
}

// MARK: - TTSHistoryAction Extension

extension TTSHistoryAction {
    var description: String {
        switch self {
        case .preview:
            return "preview"
        case .export(let format, _):
            return "export_\(format.rawValue)"
        }
    }
    
    var resultDescription: String {
        switch self {
        case .preview:
            return "预览播放"
        case .export(let format, let url):
            return "导出为 \(format.rawValue.uppercased()): \(url.lastPathComponent)"
        }
    }
}
