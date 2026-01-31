//
//  ImageUtils.swift
//  mac-ai-toolkit
//
//  Image utility functions
//

import AppKit
import Foundation

struct ImageUtils {
    // MARK: - Clipboard

    static func imageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general

        // Try to get image from clipboard
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            return image
        }

        if let imageData = pasteboard.data(forType: .png),
           let image = NSImage(data: imageData) {
            return image
        }

        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           let firstURL = fileURLs.first,
           let image = NSImage(contentsOf: firstURL) {
            return image
        }

        return nil
    }

    static func copyImageToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    // MARK: - File Operations

    static func saveImage(_ image: NSImage, to url: URL, format: ImageFormat = .png) throws {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageError.invalidImage
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: format.bitmapFormat, properties: [:]) else {
            throw ImageError.conversionFailed
        }

        try data.write(to: url)
    }

    static func loadImage(from url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else {
            throw ImageError.invalidImage
        }
        return image
    }

    // MARK: - Image Processing

    static func resize(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        newImage.unlockFocus()
        return newImage
    }

    static func crop(_ image: NSImage, to rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            return nil
        }

        return NSImage(cgImage: croppedCGImage, size: rect.size)
    }
}

// MARK: - Supporting Types

enum ImageFormat {
    case png
    case jpeg(quality: Double)
    case tiff

    var bitmapFormat: NSBitmapImageRep.FileType {
        switch self {
        case .png:
            return .png
        case .jpeg:
            return .jpeg
        case .tiff:
            return .tiff
        }
    }
}

enum ImageError: LocalizedError {
    case invalidImage
    case conversionFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .conversionFailed:
            return "Failed to convert image"
        case .saveFailed:
            return "Failed to save image"
        }
    }
}
