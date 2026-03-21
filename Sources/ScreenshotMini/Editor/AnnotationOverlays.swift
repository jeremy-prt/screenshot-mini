import SwiftUI

// MARK: - Hover Overlay

struct HoverOverlay: View {
    let annotation: Annotation

    var body: some View {
        Canvas { ctx, _ in
            let r = annotation.boundingRect.insetBy(dx: -3, dy: -3)
            ctx.stroke(Path(r), with: .color(brandPurple.opacity(0.5)),
                       style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Selection Overlay

struct SelectionOverlay: View {
    let annotation: Annotation

    var body: some View {
        Canvas { ctx, _ in
            let r = annotation.boundingRect.insetBy(dx: -5, dy: -5)
            ctx.stroke(Path(r), with: .color(brandPurple),
                       style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            let hs: CGFloat = 9
            for c in [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                       CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)] {
                let hr = CGRect(x: c.x - hs/2, y: c.y - hs/2, width: hs, height: hs)
                ctx.fill(Path(hr), with: .color(.white))
                ctx.stroke(Path(hr), with: .color(brandPurple), lineWidth: 2)
            }
            // Midpoint handle for arrows (control point or default midpoint)
            if annotation.shape == .arrow {
                let mp = annotation.controlPoint ?? CGPoint(
                    x: (annotation.start.x + annotation.end.x) / 2,
                    y: (annotation.start.y + annotation.end.y) / 2
                )
                let hr = CGRect(x: mp.x - hs/2, y: mp.y - hs/2, width: hs, height: hs)
                ctx.fill(Path(hr), with: .color(.white))
                ctx.stroke(Path(hr), with: .color(brandPurple), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Text Editing Overlay

struct TextEditingOverlay: View {
    @Binding var text: String
    let position: CGPoint
    let fontSize: CGFloat
    let color: Color
    let onCommit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(color)
                .focused($isFocused)
                .frame(minWidth: 100, maxWidth: 400)
                .fixedSize()
                .padding(.horizontal, 2)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(brandPurple.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                )
                .position(x: position.x + 52, y: position.y + fontSize * 0.35)
                .onSubmit { onCommit() }
                .onAppear { isFocused = true }
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Crop Mask

struct CropMask: Shape {
    let rect: CGRect; let size: CGSize
    func path(in frame: CGRect) -> Path {
        var p = Path(); p.addRect(CGRect(origin: .zero, size: size)); p.addRect(rect); return p
    }
    var body: some View { self.fill(style: FillStyle(eoFill: true)) }
}
