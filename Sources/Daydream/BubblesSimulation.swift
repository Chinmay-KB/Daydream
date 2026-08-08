import CoreGraphics

struct Bubble {
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var hue: CGFloat
    var spawnDelay: CFTimeInterval
    var cruiseSpeed: CGFloat
    var driftPhase: CGFloat
    var isActive: Bool
    var hasEnteredX: Bool
    var hasEnteredY: Bool
}

final class BubblesSimulation {
    private enum Corner: CaseIterable {
        case bottomLeft
        case bottomRight
        case topLeft
        case topRight
    }

    private(set) var bubbles: [Bubble] = []
    private var bounds: CGSize = .zero
    private var time: CFTimeInterval = 0

    func reset(in size: CGSize) {
        bounds = size
        time = 0
        guard size.width > 1, size.height > 1 else {
            bubbles = []
            return
        }

        let area = size.width * size.height
        let count = min(21, max(15, Int(area / 95_000)))
        let minSide = min(size.width, size.height)
        let baselineRadius = minSide * 0.1045
        let radiusJitter = baselineRadius * 0.10
        let corner = Corner.allCases.randomElement()!
        let groupSpeed = CGFloat.random(in: 128...158)
        let groupBias = CGFloat.random(in: -0.28...0.28)

        var hues = (0..<count).map { index in
            (CGFloat(index) + 0.5) / CGFloat(count)
        }
        hues.shuffle()

        var launchSlots: [CFTimeInterval] = [Double.random(in: 0.02...0.08)]
        while launchSlots.count < count {
            launchSlots.append(launchSlots[launchSlots.count - 1] + Double.random(in: 0.07...0.18))
        }
        for index in launchSlots.indices {
            launchSlots[index] = max(0.01, launchSlots[index] + Double.random(in: -0.03...0.05))
        }
        launchSlots.shuffle()

        bubbles = (0..<count).map { index in
            let radius = baselineRadius + CGFloat.random(in: -radiusJitter...radiusJitter)
            let cruiseSpeed = groupSpeed * CGFloat.random(in: 0.72...1.28)
            return Bubble(
                position: driftStartPosition(for: corner, radius: radius, in: size),
                velocity: driftVelocity(
                    from: corner,
                    speed: cruiseSpeed,
                    bias: groupBias + CGFloat.random(in: -0.35...0.35)
                ),
                radius: radius,
                hue: (hues[index] + CGFloat.random(in: -0.02...0.02)).wrappedHue,
                spawnDelay: launchSlots[index],
                cruiseSpeed: cruiseSpeed,
                driftPhase: CGFloat.random(in: 0...(2 * .pi)),
                isActive: false,
                hasEnteredX: false,
                hasEnteredY: false
            )
        }
    }

    @discardableResult
    func resize(to size: CGSize) -> Bool {
        guard size.width > 1, size.height > 1 else { return false }
        let sizeChanged = abs(size.width - bounds.width) > 2 || abs(size.height - bounds.height) > 2
        guard bubbles.isEmpty || sizeChanged else { return false }

        if bubbles.isEmpty {
            reset(in: size)
            return true
        }

        bounds = size
        for index in bubbles.indices {
            let radius = bubbles[index].radius
            if bubbles[index].hasEnteredX {
                bubbles[index].position.x = min(max(radius, bubbles[index].position.x), size.width - radius)
            }
            if bubbles[index].hasEnteredY {
                bubbles[index].position.y = min(max(radius, bubbles[index].position.y), size.height - radius)
            }
        }
        return false
    }

    func step(deltaTime: CFTimeInterval) {
        guard bounds.width > 1, bounds.height > 1, deltaTime > 0 else { return }

        let dt = CGFloat(min(deltaTime, 1.0 / 30.0))
        time += deltaTime

        for index in bubbles.indices {
            var bubble = bubbles[index]
            guard time >= bubble.spawnDelay else { continue }

            bubble.isActive = true
            let activeTime = CGFloat(time - bubble.spawnDelay)
            let speed = max(hypot(bubble.velocity.dx, bubble.velocity.dy), 0.001)
            let directionX = bubble.velocity.dx / speed
            let directionY = bubble.velocity.dy / speed
            let curve = sin(activeTime * 0.55 + bubble.driftPhase) * 7.5
            let desiredSpeed = bubble.cruiseSpeed * (
                1 + sin(activeTime * 0.31 + bubble.driftPhase * 0.7) * 0.08
            )
            let speedCorrection = (desiredSpeed - speed) * 0.8

            bubble.velocity.dx += (directionX * speedCorrection - directionY * curve) * dt
            bubble.velocity.dy += (directionY * speedCorrection + directionX * curve) * dt
            bubble.position.x += bubble.velocity.dx * dt
            bubble.position.y += bubble.velocity.dy * dt

            let radius = bubble.radius
            if !bubble.hasEnteredX,
               bubble.position.x >= radius,
               bubble.position.x <= bounds.width - radius {
                bubble.hasEnteredX = true
            }
            if !bubble.hasEnteredY,
               bubble.position.y >= radius,
               bubble.position.y <= bounds.height - radius {
                bubble.hasEnteredY = true
            }

            if bubble.hasEnteredX {
                if bubble.position.x - radius < 0 {
                    bubble.position.x = radius
                    bubble.velocity.dx = abs(bubble.velocity.dx) * 0.96
                } else if bubble.position.x + radius > bounds.width {
                    bubble.position.x = bounds.width - radius
                    bubble.velocity.dx = -abs(bubble.velocity.dx) * 0.96
                }
            }

            if bubble.hasEnteredY {
                if bubble.position.y - radius < 0 {
                    bubble.position.y = radius
                    bubble.velocity.dy = abs(bubble.velocity.dy) * 0.96
                } else if bubble.position.y + radius > bounds.height {
                    bubble.position.y = bounds.height - radius
                    bubble.velocity.dy = -abs(bubble.velocity.dy) * 0.96
                }
            }

            bubbles[index] = bubble
        }

        resolveCollisions()
    }

    private func driftStartPosition(for corner: Corner, radius: CGFloat, in size: CGSize) -> CGPoint {
        let direction = inwardDirection(from: corner)
        let tangent = CGVector(dx: -direction.dy, dy: direction.dx)
        let lateralOffset = CGFloat.random(in: -1.15...1.15) * radius
        let trailingOffset = CGFloat.random(in: 0...1.4) * radius
        let outsideOffset = radius * (1.4 + CGFloat.random(in: 0...1.1)) + trailingOffset
        let cornerPoint: CGPoint

        switch corner {
        case .bottomLeft:
            cornerPoint = CGPoint(x: 0, y: 0)
        case .bottomRight:
            cornerPoint = CGPoint(x: size.width, y: 0)
        case .topLeft:
            cornerPoint = CGPoint(x: 0, y: size.height)
        case .topRight:
            cornerPoint = CGPoint(x: size.width, y: size.height)
        }

        return CGPoint(
            x: cornerPoint.x - direction.dx * outsideOffset + tangent.dx * lateralOffset,
            y: cornerPoint.y - direction.dy * outsideOffset + tangent.dy * lateralOffset
        )
    }

    private func driftVelocity(from corner: Corner, speed: CGFloat, bias: CGFloat) -> CGVector {
        let direction = inwardDirection(from: corner)
        let tangent = CGVector(dx: -direction.dy, dy: direction.dx)
        let dx = direction.dx + tangent.dx * bias
        let dy = direction.dy + tangent.dy * bias
        let length = hypot(dx, dy)
        return CGVector(dx: dx / length * speed, dy: dy / length * speed)
    }

    private func inwardDirection(from corner: Corner) -> CGVector {
        switch corner {
        case .bottomLeft:
            return CGVector(dx: 0.70710678, dy: 0.70710678)
        case .bottomRight:
            return CGVector(dx: -0.70710678, dy: 0.70710678)
        case .topLeft:
            return CGVector(dx: 0.70710678, dy: -0.70710678)
        case .topRight:
            return CGVector(dx: -0.70710678, dy: -0.70710678)
        }
    }

    private func resolveCollisions() {
        guard bubbles.count > 1 else { return }

        for i in 0..<(bubbles.count - 1) {
            for j in (i + 1)..<bubbles.count {
                var a = bubbles[i]
                var b = bubbles[j]
                guard a.isActive, b.isActive else { continue }

                let dx = b.position.x - a.position.x
                let dy = b.position.y - a.position.y
                let distance = hypot(dx, dy)
                let minDistance = a.radius + b.radius
                guard distance > 0.001, distance < minDistance else { continue }

                let nx = dx / distance
                let ny = dy / distance
                let separation = min((minDistance - distance) * 0.12, 2.0)
                let totalMass = a.radius * a.radius + b.radius * b.radius
                let aShare = (b.radius * b.radius) / totalMass
                let bShare = (a.radius * a.radius) / totalMass

                a.position.x -= nx * separation * aShare
                a.position.y -= ny * separation * aShare
                b.position.x += nx * separation * bShare
                b.position.y += ny * separation * bShare

                let closing = (a.velocity.dx - b.velocity.dx) * nx + (a.velocity.dy - b.velocity.dy) * ny
                if closing > 0 {
                    let impulse = closing * 0.82
                    a.velocity.dx -= impulse * nx * aShare * 2
                    a.velocity.dy -= impulse * ny * aShare * 2
                    b.velocity.dx += impulse * nx * bShare * 2
                    b.velocity.dy += impulse * ny * bShare * 2
                }

                bubbles[i] = a
                bubbles[j] = b
            }
        }
    }
}

private extension CGFloat {
    var wrappedHue: CGFloat {
        let value = truncatingRemainder(dividingBy: 1)
        return value < 0 ? value + 1 : value
    }
}
