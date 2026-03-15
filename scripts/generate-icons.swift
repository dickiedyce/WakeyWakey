#!/usr/bin/env swift
// Generates WakeyWakey app icons at all required sizes.
// Uses CoreGraphics to draw a rounded-rect gradient with an SF Symbol.

import Cocoa

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

for size in sizes {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext

    // Background: rounded rect with gradient
    let rect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.clip()

    // Gradient: deep blue to teal
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.1, green: 0.15, blue: 0.4, alpha: 1.0),
        CGColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1.0)
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    }

    // Draw SF Symbol
    let symbolSize = s * 0.55
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium)
    if let symbol = NSImage(systemSymbolName: "airplane", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {
        let symbolRect = NSRect(
            x: (s - symbol.size.width) / 2,
            y: (s - symbol.size.height) / 2,
            width: symbol.size.width,
            height: symbol.size.height
        )
        NSColor.white.withAlphaComponent(0.95).set()
        symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 0.95)
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        continue
    }

    let filename = "\(outputDir)/icon_\(size).png"
    do {
        try pngData.write(to: URL(fileURLWithPath: filename))
        print("Created \(filename)")
    } catch {
        print("Error writing \(filename): \(error)")
    }
}

print("Done generating icons.")
