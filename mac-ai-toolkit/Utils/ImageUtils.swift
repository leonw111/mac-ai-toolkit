//
//  ImageUtils.swift
//  mac-ai-toolkit
//
//  Image processing utilities
//

import Foundation
import AppKit
import CoreGraphics

enum ImageUtils {

    // MARK: - Image Loading

    static func loadImage(from url: URL) -> NSImage? {
        NSImage(contentsOf: url)
    }

    static func loadImage(from data: Data) -> NSImage? {
        NSImage(data: data)
    }

    // MARK: - Image Conversion

    static func toCGImage(_ image: NSImage) -> CGImage? {
        image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }

    static func toData(_ image: NSImage, format: ImageFormat = .png) -> Data? {
        guard let cgImage = toCGImage(image) else { return nil }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)

        switch format {
        case .png:
            return bitmapRep.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        case .tiff:
            return bitmapRep.representation(using: .tiff, properties: [:])
        }
    }

    // MARK: - Clipboard

    static func imageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general

        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage {
            return image
        }

        return nil
    }

    static func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    // MARK: - Image Resizing

    static func resize(_ image: NSImage, to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    static func resizeToFit(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        if ratio >= 1.0 {
            return image
        }

        let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
        return resize(image, to: newSize)
    }

    // MARK: - Screen Capture

    static func captureScreen(rect: CGRect? = nil) -> NSImage? {
        let displayID = CGMainDisplayID()

        let cgImage: CGImage?
        if let rect = rect {
            cgImage = CGDisplayCreateImage(displayID, rect: rect)
        } else {
            cgImage = CGDisplayCreateImage(displayID)
        }

        guard let capturedImage = cgImage else { return nil }

        let size = NSSize(width: capturedImage.width, height: capturedImage.height)
        return NSImage(cgImage: capturedImage, size: size)
    }

    // MARK: - Image Validation

    static func isValidImage(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        return CGImageSourceGetCount(source) > 0
    }

    static func imageSize(from data: Data) -> NSSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            return nil
        }

        return NSSize(width: width, height: height)
    }
}

// MARK: - Image Format

enum ImageFormat: String {
    case png
    case jpeg
    case tiff
}
