import AppKit

enum DaydreamIcon {
    static func statusItemImage(isActive: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let mainBubble = NSBezierPath(
                ovalIn: NSRect(x: 2.5, y: 3, width: 11.5, height: 11.5)
            )
            let companionBubble = NSBezierPath(
                ovalIn: NSRect(x: 12.25, y: 2.25, width: 3.25, height: 3.25)
            )

            NSColor.black.setFill()
            if isActive {
                mainBubble.fill()
                companionBubble.fill()

                NSColor.clear.setFill()
                NSGraphicsContext.current?.cgContext.setBlendMode(.clear)
                NSBezierPath(ovalIn: NSRect(x: 5.75, y: 6.25, width: 5, height: 5)).fill()
                NSGraphicsContext.current?.cgContext.setBlendMode(.normal)
            } else {
                NSColor.black.setStroke()
                mainBubble.lineWidth = 1.65
                mainBubble.stroke()
                companionBubble.fill()
            }

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Daydream"
        return image
    }
}
