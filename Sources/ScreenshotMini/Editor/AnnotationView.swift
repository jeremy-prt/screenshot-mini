import SwiftUI

// MARK: - Annotation View

struct AnnotationView: View {
    let annotation: Annotation

    var body: some View {
        if annotation.shape == .text {
            textView
        } else {
            Canvas { ctx, _ in
                if annotation.shape == .freehand {
                    drawFreehand(ctx: ctx)
                } else {
                    let s = annotation.start, e = annotation.end
                    let path = shapePath(from: s, to: e)
                    if annotation.filled && (annotation.shape == .rect || annotation.shape == .circle) {
                        let opacity: Double = annotation.solidFill ? 1.0 : 0.3
                        ctx.fill(path, with: .color(annotation.color.opacity(opacity)))
                    }
                    ctx.stroke(path, with: .color(annotation.color), lineWidth: annotation.lineWidth)
                    if annotation.shape == .arrow { drawArrowhead(ctx: ctx, from: s, to: e) }
                }
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var textView: some View {
        if !annotation.text.isEmpty {
            Text(annotation.text)
                .font(.system(size: annotation.fontSize, weight: .medium))
                .foregroundStyle(annotation.color)
                .position(x: annotation.start.x + textWidth / 2,
                          y: annotation.start.y + annotation.fontSize * 0.7 / 2)
                .allowsHitTesting(false)
        }
    }

    private var textWidth: CGFloat {
        CGFloat(annotation.text.count) * annotation.fontSize * 0.6
    }

    private func drawFreehand(ctx: GraphicsContext) {
        guard annotation.points.count >= 2 else { return }
        var p = Path()
        p.move(to: annotation.points[0])
        if annotation.points.count == 2 {
            p.addLine(to: annotation.points[1])
        } else {
            for i in 1..<annotation.points.count {
                let mid = CGPoint(
                    x: (annotation.points[i - 1].x + annotation.points[i].x) / 2,
                    y: (annotation.points[i - 1].y + annotation.points[i].y) / 2
                )
                p.addQuadCurve(to: mid, control: annotation.points[i - 1])
            }
            p.addLine(to: annotation.points.last!)
        }
        ctx.stroke(p, with: .color(annotation.color), lineWidth: annotation.lineWidth)
    }

    private func shapePath(from s: CGPoint, to e: CGPoint) -> Path {
        var p = Path()
        let r = CGRect(x: min(s.x, e.x), y: min(s.y, e.y), width: abs(e.x - s.x), height: abs(e.y - s.y))
        switch annotation.shape {
        case .rect: p.addRect(r)
        case .circle: p.addEllipse(in: r)
        case .line, .arrow: p.move(to: s); p.addLine(to: e)
        case .text, .freehand: break
        }
        return p
    }

    private func drawArrowhead(ctx: GraphicsContext, from s: CGPoint, to e: CGPoint) {
        let angle = atan2(e.y - s.y, e.x - s.x)
        let hl: CGFloat = 15, ha: CGFloat = .pi / 6
        var p = Path()
        p.move(to: e)
        p.addLine(to: CGPoint(x: e.x - hl * cos(angle - ha), y: e.y - hl * sin(angle - ha)))
        p.move(to: e)
        p.addLine(to: CGPoint(x: e.x - hl * cos(angle + ha), y: e.y - hl * sin(angle + ha)))
        ctx.stroke(p, with: .color(annotation.color), lineWidth: annotation.lineWidth)
    }
}

// MARK: - Freehand Preview (during drawing)

struct FreehandPreview: View {
    let points: [CGPoint]
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            guard points.count >= 2 else { return }
            var p = Path()
            p.move(to: points[0])
            for i in 1..<points.count {
                let mid = CGPoint(
                    x: (points[i - 1].x + points[i].x) / 2,
                    y: (points[i - 1].y + points[i].y) / 2
                )
                p.addQuadCurve(to: mid, control: points[i - 1])
            }
            p.addLine(to: points.last!)
            ctx.stroke(p, with: .color(color), lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
    }
}
