import AppKit

/// What the menu bar capsule should show.
enum CapsuleState: Equatable {
    case idle
    case extendedRelease
    /// `fraction` is the time remaining in 0...1; `label` is drawn to the right of the capsule.
    case timed(fraction: Double, label: String)
}

/// Draws the menu bar icon as a template image (black + alpha) so macOS tints it for
/// light/dark menu bars. Drawn in code because the fill level and label change over time.
/// Mirrors `resources/capsule/*.svg`.
enum CapsuleIcon {
    static let side: CGFloat = 18

    // Geometry in capsule-local space: origin at the center, long axis along +x.
    private static let stroke: CGFloat = 1.5
    private static let outer = NSRect(x: -8.75, y: -4.75, width: 17.5, height: 9.5)
    private static let beadRadius: CGFloat = 1
    private static let beads = [NSPoint(x: -4.9, y: -1.0), NSPoint(x: -2.5, y: 1.3), NSPoint(x: -2.3, y: -1.5)]

    static func image(for state: CapsuleState) -> NSImage {
        let label: NSAttributedString? = {
            guard case .timed(_, let text) = state else { return nil }
            return NSAttributedString(string: text, attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.black,
            ])
        }()

        let gap: CGFloat = 2
        let textWidth = label.map { ceil($0.size().width) + gap } ?? 0
        let size = NSSize(width: side + textWidth, height: side)

        let image = NSImage(size: size, flipped: false) { _ in
            drawCapsule(state)
            if let label {
                label.draw(at: NSPoint(x: side + gap, y: (side - label.size().height) / 2))
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawCapsule(_ state: CapsuleState) {
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        defer { context.restoreGraphicsState() }

        // Local space, tilted so the capsule runs lower-left to upper-right.
        let transform = NSAffineTransform()
        transform.translateX(by: side / 2, yBy: side / 2)
        transform.rotate(byDegrees: 45)
        transform.concat()

        NSColor.black.setStroke()
        NSColor.black.setFill()

        switch state {
        case .idle:
            outline().stroke()
            seam().stroke()
            fillBeads { _ in true }

        case .extendedRelease:
            body().fill()
            context.compositingOperation = .clear
            seam().stroke()
            fillBeads { _ in true }
            spark().fill() // XR marker: tells it apart from a timed dose that has just started
            context.compositingOperation = .sourceOver

        case .timed(let fraction, _):
            outline().stroke()
            // The bead end stays full while time remains; the other end empties first.
            let edge = outer.minX + outer.width * min(max(fraction, 0), 1)
            let full = NSRect(x: outer.minX - 1, y: outer.minY - 1,
                              width: max(edge - outer.minX + 1, 0), height: outer.height + 2)
            let empty = NSRect(x: edge, y: outer.minY - 1,
                               width: max(outer.maxX + 1 - edge, 0), height: outer.height + 2)

            context.saveGraphicsState()
            body().addClip()
            NSBezierPath(rect: full).fill()
            context.restoreGraphicsState()

            // Beads are knocked out of the full part and solid in the empty part; clipping
            // keeps a bead that straddles the edge clean.
            context.saveGraphicsState()
            NSBezierPath(rect: full).addClip()
            context.compositingOperation = .clear
            fillBeads { _ in true }
            context.restoreGraphicsState()

            context.saveGraphicsState()
            NSBezierPath(rect: empty).addClip()
            fillBeads { _ in true }
            context.restoreGraphicsState()
        }
    }

    private static func body() -> NSBezierPath {
        NSBezierPath(roundedRect: outer, xRadius: outer.height / 2, yRadius: outer.height / 2)
    }

    private static func outline() -> NSBezierPath {
        let path = NSBezierPath(roundedRect: outer.insetBy(dx: stroke / 2, dy: stroke / 2),
                                xRadius: outer.height / 2 - stroke / 2, yRadius: outer.height / 2 - stroke / 2)
        path.lineWidth = stroke
        return path
    }

    private static func seam() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: -4))
        path.line(to: NSPoint(x: 0, y: 4))
        path.lineWidth = stroke
        path.lineCapStyle = .round
        return path
    }

    /// Lightning bolt centered in the non-bead half, kept upright on screen
    /// (the surrounding space is rotated 45°).
    private static func spark() -> NSBezierPath {
        let bolt = NSBezierPath()
        let points = [(1.1, 3.0), (-2.1, -0.7), (-0.2, -0.7), (-1.0, -3.1), (2.2, 0.6), (0.3, 0.6)]
        bolt.move(to: NSPoint(x: points[0].0, y: points[0].1))
        for point in points.dropFirst() { bolt.line(to: NSPoint(x: point.0, y: point.1)) }
        bolt.close()

        var placement = AffineTransform(translationByX: 4.4, byY: 0)
        placement.rotate(byDegrees: -45)
        bolt.transform(using: placement)
        return bolt
    }

    private static func fillBeads(where include: (NSPoint) -> Bool) {
        for bead in beads where include(bead) {
            NSBezierPath(ovalIn: NSRect(x: bead.x - beadRadius, y: bead.y - beadRadius,
                                        width: beadRadius * 2, height: beadRadius * 2)).fill()
        }
    }
}
