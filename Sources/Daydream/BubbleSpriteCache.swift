import AppKit

enum BubbleSpriteCache {
    private static var images: [Int: CGImage] = [:]
    private static let hueSteps = 48
    private static let pixelSize = 512

    static func image(for hue: CGFloat) -> CGImage {
        let key = ((Int((hue * CGFloat(hueSteps)).rounded()) % hueSteps) + hueSteps) % hueSteps
        if let cached = images[key] {
            return cached
        }

        let image = render(hue: CGFloat(key) / CGFloat(hueSteps))
        images[key] = image
        return image
    }

    private static func render(hue: CGFloat) -> CGImage {
        let size = CGFloat(pixelSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            preconditionFailure("Unable to create bubble sprite context")
        }

        context.translateBy(x: 0, y: size)
        context.scaleBy(x: 1, y: -1)

        let center = CGPoint(x: size * 0.5, y: size * 0.5)
        let radius = size * 0.495
        let color = NSColor(hue: hue, saturation: 0.78, brightness: 1.0, alpha: 1)
        let rim = NSColor(
            hue: (hue + 0.06).truncatingRemainder(dividingBy: 1),
            saturation: 0.5,
            brightness: 1.0,
            alpha: 1
        )

        drawBloom(in: context, center: center, radius: radius, color: color, colorSpace: colorSpace)
        drawBody(in: context, center: center, radius: radius, color: color, rim: rim, colorSpace: colorSpace)

        guard let image = context.makeImage() else {
            preconditionFailure("Unable to create bubble sprite image")
        }
        return image
    }

    private static func drawBloom(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        color: NSColor,
        colorSpace: CGColorSpace
    ) {
        let bloomRect = CGRect(
            x: center.x - radius * 1.02,
            y: center.y - radius * 1.02,
            width: radius * 2.04,
            height: radius * 2.04
        )
        context.saveGState()
        context.addEllipse(in: bloomRect)
        context.clip()
        if let bloom = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.clear.cgColor,
                color.withAlphaComponent(0.0).cgColor,
                color.withAlphaComponent(0.08).cgColor,
                color.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.9, 0.97, 1.0]
        ) {
            context.drawRadialGradient(
                bloom,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: radius * 1.02,
                options: []
            )
        }
        context.restoreGState()
    }

    private static func drawBody(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        color: NSColor,
        rim: NSColor,
        colorSpace: CGColorSpace
    ) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.saveGState()
        context.addEllipse(in: rect)
        context.clip()

        if let body = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.white.withAlphaComponent(0.06).cgColor,
                color.withAlphaComponent(0.015).cgColor,
                color.withAlphaComponent(0.04).cgColor,
                color.withAlphaComponent(0.1).cgColor,
                rim.withAlphaComponent(0.48).cgColor,
                color.withAlphaComponent(0.16).cgColor
            ] as CFArray,
            locations: [0.0, 0.62, 0.82, 0.91, 0.975, 1.0]
        ) {
            let shadeCenter = CGPoint(x: center.x - radius * 0.12, y: center.y + radius * 0.16)
            context.drawRadialGradient(
                body,
                startCenter: shadeCenter,
                startRadius: 0,
                endCenter: center,
                endRadius: radius,
                options: [.drawsAfterEndLocation]
            )
        }

        if let fresnel = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.clear.cgColor,
                color.withAlphaComponent(0.0).cgColor,
                rim.withAlphaComponent(0.16).cgColor,
                NSColor.white.withAlphaComponent(0.28).cgColor
            ] as CFArray,
            locations: [0.88, 0.94, 0.985, 1.0]
        ) {
            context.drawRadialGradient(
                fresnel,
                startCenter: center,
                startRadius: radius * 0.86,
                endCenter: center,
                endRadius: radius,
                options: []
            )
        }

        drawSpecular(in: context, center: center, radius: radius, colorSpace: colorSpace)
        context.restoreGState()
    }

    private static func drawSpecular(
        in context: CGContext,
        center: CGPoint,
        radius: CGFloat,
        colorSpace: CGColorSpace
    ) {
        let highlightCenter = CGPoint(x: center.x - radius * 0.26, y: center.y + radius * 0.32)
        if let soft = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.white.withAlphaComponent(0.28).cgColor,
                NSColor.white.withAlphaComponent(0.1).cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.45, 1.0]
        ) {
            context.drawRadialGradient(
                soft,
                startCenter: highlightCenter,
                startRadius: 0,
                endCenter: highlightCenter,
                endRadius: radius * 0.48,
                options: [.drawsAfterEndLocation]
            )
        }

        let coreCenter = CGPoint(
            x: highlightCenter.x - radius * 0.03,
            y: highlightCenter.y + radius * 0.02
        )
        if let core = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                NSColor.white.withAlphaComponent(0.55).cgColor,
                NSColor.white.withAlphaComponent(0.12).cgColor,
                NSColor.white.withAlphaComponent(0.0).cgColor
            ] as CFArray,
            locations: [0.0, 0.4, 1.0]
        ) {
            context.drawRadialGradient(
                core,
                startCenter: coreCenter,
                startRadius: 0,
                endCenter: coreCenter,
                endRadius: radius * 0.18,
                options: [.drawsAfterEndLocation]
            )
        }
    }
}
