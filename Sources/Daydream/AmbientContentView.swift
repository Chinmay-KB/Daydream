import AppKit
import QuartzCore

final class AmbientContentView: NSView {
    var onDismiss: (() -> Void)?

    private let simulation = BubblesSimulation()
    private var displayLink: CADisplayLink?
    private var bubbleLayers: [CALayer] = []
    private var lastTimestamp: CFTimeInterval = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        stop()
        resetSimulationAndLayers()
        lastTimestamp = 0

        let link = displayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
        bubbleLayers.forEach { $0.removeFromSuperlayer() }
        bubbleLayers.removeAll(keepingCapacity: true)
    }

    override func layout() {
        super.layout()
        if simulation.resize(to: bounds.size) {
            rebuildLayers()
        }
    }

    override var isOpaque: Bool { false }

    override func mouseDown(with event: NSEvent) {
        onDismiss?()
    }

    @objc
    private func handleDisplayLink(_ link: CADisplayLink) {
        let timestamp = link.targetTimestamp
        if lastTimestamp == 0 {
            lastTimestamp = timestamp
            return
        }

        let delta = max(0, timestamp - lastTimestamp)
        lastTimestamp = timestamp
        simulation.step(deltaTime: delta)
        syncLayers()
    }

    private func resetSimulationAndLayers() {
        simulation.reset(in: bounds.size)
        rebuildLayers()
    }

    private func rebuildLayers() {
        bubbleLayers.forEach { $0.removeFromSuperlayer() }
        bubbleLayers.removeAll(keepingCapacity: true)

        let scaleFactor = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        guard let host = layer else { return }

        for bubble in simulation.bubbles {
            let bubbleLayer = CALayer()
            bubbleLayer.contentsGravity = .resize
            bubbleLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            bubbleLayer.contentsScale = scaleFactor
            bubbleLayer.allowsEdgeAntialiasing = true
            bubbleLayer.edgeAntialiasingMask = [.layerLeftEdge, .layerRightEdge, .layerTopEdge, .layerBottomEdge]
            bubbleLayer.contents = BubbleSpriteCache.image(for: bubble.hue)
            bubbleLayer.isHidden = !bubble.isActive
            host.addSublayer(bubbleLayer)
            bubbleLayers.append(bubbleLayer)
        }

        syncLayers()
    }

    private func syncLayers() {
        let bubbles = simulation.bubbles
        guard bubbles.count == bubbleLayers.count else {
            rebuildLayers()
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for index in bubbles.indices {
            let bubble = bubbles[index]
            let bubbleLayer = bubbleLayers[index]
            let diameter = max(bubble.radius * 2, 1)
            bubbleLayer.isHidden = !bubble.isActive
            bubbleLayer.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
            bubbleLayer.position = bubble.position
            bubbleLayer.zPosition = bubble.position.y
        }

        CATransaction.commit()
    }
}
