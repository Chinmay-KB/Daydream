import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    fputs("Usage: render-app-icon.swift /path/to/AppIcon.iconset\n", stderr)
    exit(64)
}

let iconsetURL = URL(fileURLWithPath: arguments[1], isDirectory: true)
let fileManager = FileManager.default

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(name: String, points: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func makeImage(size: Int) -> NSImage {
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize, flipped: false) { rect in
        let inset = rect.width * 0.08
        let background = NSBezierPath(
            roundedRect: rect.insetBy(dx: inset, dy: inset),
            xRadius: rect.width * 0.24,
            yRadius: rect.width * 0.24
        )
        NSColor(calibratedRed: 0.06, green: 0.12, blue: 0.20, alpha: 1).setFill()
        background.fill()

        let mainBubble = NSBezierPath(
            ovalIn: NSRect(
                x: rect.width * 0.20,
                y: rect.height * 0.21,
                width: rect.width * 0.55,
                height: rect.width * 0.55
            )
        )
        NSColor(calibratedRed: 0.87, green: 0.96, blue: 0.97, alpha: 1).setFill()
        mainBubble.fill()

        let innerBubble = NSBezierPath(
            ovalIn: NSRect(
                x: rect.width * 0.35,
                y: rect.height * 0.36,
                width: rect.width * 0.25,
                height: rect.width * 0.25
            )
        )
        NSColor(calibratedRed: 0.10, green: 0.28, blue: 0.35, alpha: 1).setFill()
        innerBubble.fill()

        let companionBubble = NSBezierPath(
            ovalIn: NSRect(
                x: rect.width * 0.67,
                y: rect.height * 0.20,
                width: rect.width * 0.16,
                height: rect.width * 0.16
            )
        )
        NSColor(calibratedRed: 0.37, green: 0.85, blue: 0.82, alpha: 1).setFill()
        companionBubble.fill()
        return true
    }
    return image
}

for item in sizes {
    let image = makeImage(size: item.points)
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Could not render \(item.name).\n", stderr)
        exit(1)
    }
    try pngData.write(to: iconsetURL.appendingPathComponent(item.name))
}
