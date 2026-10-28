//
//  ImageSupport.swift
//  KnittingPattern
//
//  Created by Ekaterina on 26.10.2026.
//

import SwiftUI
import CoreGraphics
import ImageIO

enum ImageSupport {
    
    static func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        // Сразу учитываем EXIF-поворот и уменьшаем большие фото с камеры.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    static func image(from data: Data?) -> Image? {
        guard let data, let cgImage = cgImage(from: data) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }

    /// Уменьшенная JPEG-копия для хранения в схеме.
    static func compressedData(from data: Data) -> Data? {
        guard let cgImage = cgImage(from: data) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    /// Усредняет фото до сетки columns × rows и возвращает цвет каждой клетки.
    static func sampleColors(from data: Data, columns: Int, rows: Int) -> [Color.Resolved]? {
        guard let cgImage = cgImage(from: data), columns > 0, rows > 0 else { return nil }
        let bytesPerRow = columns * 4
        var pixels = [UInt8](repeating: 0, count: rows * bytesPerRow)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: columns, height: rows,
                bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: columns, height: rows))
            return true
        }
        guard drawn else { return nil }
        return (0..<(columns * rows)).map { index in
            let offset = index * 4
            return Color.Resolved(
                red: Float(pixels[offset]) / 255,
                green: Float(pixels[offset + 1]) / 255,
                blue: Float(pixels[offset + 2]) / 255
            )
        }
    }

    /// PNG-файл во временной папке — для «Поделиться».
    static func writePNG(_ cgImage: CGImage, named name: String) -> URL? {
        let safeName = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?*\"<>|")).joined()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName.isEmpty ? String(localized: "Chart") : safeName)
            .appendingPathExtension("png")
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        return CGImageDestinationFinalize(destination) ? url : nil
    }
}
