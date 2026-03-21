import SwiftUI
import AppKit

// MARK: - Save helper

@MainActor
func saveImage(_ image: NSImage, to savePath: URL) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else { return }
    let format = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
    let (fileType, ext): (NSBitmapImageRep.FileType, String) = switch format {
        case "jpeg": (.jpeg, "jpg")
        case "tiff": (.tiff, "tiff")
        default: (.png, "png")
    }
    let props: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg ? [.compressionFactor: 0.9] : [:]
    guard let data = bitmap.representation(using: fileType, properties: props) else { return }
    let filename = "Screenshot_\(DateFormatter.yyyyMMdd_HHmmss.string(from: Date())).\(ext)"
    try? data.write(to: savePath.appending(path: filename))
    ToastManager.shared.show(message: L10n.lang == "en" ? "Saved!" : "Sauvegardé !")
}

extension DateFormatter {
    static let yyyyMMdd_HHmmss: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HH-mm-ss"; return f
    }()
}

// MARK: - Crop helper

func cropImage(_ image: NSImage, to rect: CGRect, canvasSize: CGSize) -> NSImage {
    let scaleX = image.size.width / canvasSize.width
    let scaleY = image.size.height / canvasSize.height
    let cropRect = CGRect(x: rect.origin.x * scaleX, y: rect.origin.y * scaleY,
                          width: rect.width * scaleX, height: rect.height * scaleY)
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let cropped = cg.cropping(to: cropRect) else { return image }
    return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
}

// MARK: - Flatten annotations

func flattenAnnotations(_ annotations: [Annotation], onto image: NSImage, canvasSize: CGSize) -> NSImage {
    guard !annotations.isEmpty else { return image }
    let imgSize = image.size
    let sx = imgSize.width / canvasSize.width, sy = imgSize.height / canvasSize.height

    let result = NSImage(size: imgSize)
    result.lockFocus()
    image.draw(in: NSRect(origin: .zero, size: imgSize))

    for ann in annotations {
        let s = NSPoint(x: ann.start.x * sx, y: (canvasSize.height - ann.start.y) * sy)
        let e = NSPoint(x: ann.end.x * sx, y: (canvasSize.height - ann.end.y) * sy)
        let nsColor = NSColor(ann.color)
        nsColor.setStroke()
        let path = NSBezierPath()
        path.lineWidth = ann.lineWidth * sx

        switch ann.shape {
        case .rect:
            let r = NSRect(x: min(s.x, e.x), y: min(s.y, e.y), width: abs(e.x - s.x), height: abs(e.y - s.y))
            path.appendRect(r)
            if ann.filled { nsColor.withAlphaComponent(ann.solidFill ? 1.0 : 0.3).setFill(); path.fill() }
            path.stroke()
        case .circle:
            let r = NSRect(x: min(s.x, e.x), y: min(s.y, e.y), width: abs(e.x - s.x), height: abs(e.y - s.y))
            path.appendOval(in: r)
            if ann.filled { nsColor.withAlphaComponent(ann.solidFill ? 1.0 : 0.3).setFill(); path.fill() }
            path.stroke()
        case .line:
            path.move(to: s); path.line(to: e); path.stroke()
        case .arrow:
            path.move(to: s); path.line(to: e); path.stroke()
            let angle = atan2(e.y - s.y, e.x - s.x)
            let hl: CGFloat = 15 * sx, ha: CGFloat = .pi / 6
            let ap = NSBezierPath(); ap.lineWidth = ann.lineWidth * sx
            ap.move(to: e)
            ap.line(to: NSPoint(x: e.x - hl * cos(angle - ha), y: e.y - hl * sin(angle - ha)))
            ap.move(to: e)
            ap.line(to: NSPoint(x: e.x - hl * cos(angle + ha), y: e.y - hl * sin(angle + ha)))
            ap.stroke()
        case .text:
            if !ann.text.isEmpty {
                let fSize = ann.fontSize * sx
                let font = NSFont.systemFont(ofSize: fSize, weight: .medium)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: nsColor]
                let str = NSAttributedString(string: ann.text, attributes: attrs)
                let tx = ann.start.x * sx
                let ty = (canvasSize.height - ann.start.y) * sy - fSize
                str.draw(at: NSPoint(x: tx, y: ty))
            }
        case .freehand:
            guard ann.points.count >= 2 else { break }
            let fp = NSBezierPath(); fp.lineWidth = ann.lineWidth * sx
            let first = NSPoint(x: ann.points[0].x * sx, y: (canvasSize.height - ann.points[0].y) * sy)
            fp.move(to: first)
            for i in 1..<ann.points.count {
                let pt = NSPoint(x: ann.points[i].x * sx, y: (canvasSize.height - ann.points[i].y) * sy)
                let prev = NSPoint(x: ann.points[i-1].x * sx, y: (canvasSize.height - ann.points[i-1].y) * sy)
                let mid = NSPoint(x: (prev.x + pt.x) / 2, y: (prev.y + pt.y) / 2)
                fp.curve(to: mid, controlPoint1: prev, controlPoint2: prev)
            }
            let last = NSPoint(x: ann.points.last!.x * sx, y: (canvasSize.height - ann.points.last!.y) * sy)
            fp.line(to: last)
            nsColor.setStroke()
            fp.stroke()
        }
    }
    result.unlockFocus()
    return result
}

// MARK: - Drag interaction state

enum CanvasInteraction {
    case none
    case drawing(Annotation)          // creating new shape
    case moving(UUID, CGPoint)        // moving annotation, last point
    case resizing(UUID, ResizeHandle)  // resizing via handle
    case freehand([CGPoint])          // collecting freehand points
}
