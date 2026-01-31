//
//  HistoryServiceProtocol.swift
//  mac-ai-toolkit
//
//  History service protocol definition
//  Created on 2026-01-31
//

import Foundation
import Combine

// MARK: - History Service Protocol

/// 历史记录服务协议
protocol HistoryServiceProtocol: AnyObject {
    
    /// 所有历史记录
    var items: [HistoryItem] { get }
    
    /// 历史记录发布者（用于观察变化）
    var itemsPublisher: AnyPublisher<[HistoryItem], Never> { get }
    
    /// 添加历史记录
    func addRecord(
        type: HistoryItemType,
        content: String,
        result: String,
        metadata: [String: String]
    ) async
    
    /// 删除指定记录
    func deleteRecord(id: UUID) async
    
    /// 删除多条记录
    func deleteRecords(ids: Set<UUID>) async
    
    /// 清空指定天数之前的记录
    func clearHistory(olderThan days: Int) async
    
    /// 清空所有记录
    func clearAllHistory() async
    
    /// 搜索历史记录
    func searchRecords(query: String) async -> [HistoryItem]
    
    /// 导出历史记录
    func exportHistory(to url: URL, format: HistoryExportFormat) async throws
    
    /// 获取统计信息
    func getStatistics() async -> HistoryStatistics
}

// MARK: - History Item

/// 历史记录项
struct HistoryItem: Identifiable, Codable, Sendable {
    let id: UUID
    let type: HistoryItemType
    let content: String
    let result: String
    let timestamp: Date
    let metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        type: HistoryItemType,
        content: String,
        result: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.result = result
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - History Item Type

/// 历史记录类型
enum HistoryItemType: String, Codable, Sendable, CaseIterable {
    case ocr = "OCR"
    case tts = "TTS"
    case stt = "STT"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .ocr: return "doc.text.viewfinder"
        case .tts: return "speaker.wave.2"
        case .stt: return "mic"
        }
    }
    
    var color: String {
        switch self {
        case .ocr: return "blue"
        case .tts: return "green"
        case .stt: return "orange"
        }
    }
}

// MARK: - History Export Format

/// 历史记录导出格式
enum HistoryExportFormat: String, Sendable {
    case json
    case csv
    case txt
    
    var fileExtension: String {
        rawValue
    }
    
    var displayName: String {
        rawValue.uppercased()
    }
}

// MARK: - History Statistics

/// 历史记录统计信息
struct HistoryStatistics: Sendable {
    let totalCount: Int
    let ocrCount: Int
    let ttsCount: Int
    let sttCount: Int
    let todayCount: Int
    let thisWeekCount: Int
    let thisMonthCount: Int
    let oldestRecord: Date?
    let newestRecord: Date?
    
    static let empty = HistoryStatistics(
        totalCount: 0,
        ocrCount: 0,
        ttsCount: 0,
        sttCount: 0,
        todayCount: 0,
        thisWeekCount: 0,
        thisMonthCount: 0,
        oldestRecord: nil,
        newestRecord: nil
    )
}
