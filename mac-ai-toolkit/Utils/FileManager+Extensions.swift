//
//  FileManager+Extensions.swift
//  mac-ai-toolkit
//
//  FileManager extensions
//

import Foundation

extension FileManager {

    // MARK: - App Directories

    var appSupportDirectory: URL {
        let urls = urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0].appendingPathComponent("MacAIToolkit", isDirectory: true)

        if !fileExists(atPath: appSupport.path) {
            try? createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        return appSupport
    }

    var cacheDirectory: URL {
        let urls = urls(for: .cachesDirectory, in: .userDomainMask)
        let cache = urls[0].appendingPathComponent("MacAIToolkit", isDirectory: true)

        if !fileExists(atPath: cache.path) {
            try? createDirectory(at: cache, withIntermediateDirectories: true)
        }

        return cache
    }

    var logsDirectory: URL {
        appSupportDirectory.appendingPathComponent("Logs", isDirectory: true)
    }

    var historyDirectory: URL {
        appSupportDirectory.appendingPathComponent("History", isDirectory: true)
    }

    var tempAudioDirectory: URL {
        cacheDirectory.appendingPathComponent("Audio", isDirectory: true)
    }

    // MARK: - File Operations

    func ensureDirectoryExists(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func removeItemIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) {
            try removeItem(at: url)
        }
    }

    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }

    func formattedFileSize(at url: URL) -> String? {
        guard let size = fileSize(at: url) else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    // MARK: - Cleanup

    func clearCache() throws {
        let cacheContents = try contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        )

        for url in cacheContents {
            try removeItem(at: url)
        }
    }

    func clearOldFiles(in directory: URL, olderThan days: Int) throws {
        guard fileExists(atPath: directory.path) else { return }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let contents = try contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        )

        for url in contents {
            guard let attributes = try? url.resourceValues(forKeys: [.creationDateKey]),
                  let creationDate = attributes.creationDate,
                  creationDate < cutoffDate else {
                continue
            }

            try removeItem(at: url)
        }
    }

    // MARK: - Unique Filename

    func uniqueFilename(for name: String, in directory: URL) -> URL {
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension

        var url = directory.appendingPathComponent(name)
        var counter = 1

        while fileExists(atPath: url.path) {
            let newName = ext.isEmpty ? "\(baseName)_\(counter)" : "\(baseName)_\(counter).\(ext)"
            url = directory.appendingPathComponent(newName)
            counter += 1
        }

        return url
    }
}
