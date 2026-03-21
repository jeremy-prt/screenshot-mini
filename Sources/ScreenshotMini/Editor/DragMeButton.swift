import SwiftUI
import AppKit

// MARK: - Drag Me Button

struct DragMeButton: NSViewRepresentable {
    let image: NSImage
    func makeNSView(context: Context) -> DragMeNSView { let v = DragMeNSView(); v.image = image; return v }
    func updateNSView(_ v: DragMeNSView, context: Context) { v.image = image }
}

final class DragMeNSView: NSView, NSDraggingSource {
    var image: NSImage?
    private var mouseDownPt: NSPoint?
    override var intrinsicContentSize: NSSize { NSSize(width: 80, height: 28) }

    override func draw(_ dirtyRect: NSRect) {
        let s = NSAttributedString(string: "Drag me", attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium), .foregroundColor: NSColor.secondaryLabelColor
        ])
        s.draw(at: NSPoint(x: (bounds.width - s.size().width) / 2, y: (bounds.height - s.size().height) / 2))
    }

    nonisolated func draggingSession(_ s: NSDraggingSession, sourceOperationMaskFor c: NSDraggingContext) -> NSDragOperation { [.copy] }

    override func mouseDown(with e: NSEvent) { mouseDownPt = convert(e.locationInWindow, from: nil) }

    override func mouseDragged(with e: NSEvent) {
        guard let image, let sp = mouseDownPt else { return }
        let c = convert(e.locationInWindow, from: nil)
        guard hypot(c.x - sp.x, c.y - sp.y) > 4 else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Screenshot_drag.png")
        if let t = image.tiffRepresentation, let b = NSBitmapImageRep(data: t), let d = b.representation(using: .png, properties: [:]) {
            try? d.write(to: url)
        }
        let item = NSDraggingItem(pasteboardWriter: url as NSURL)
        item.setDraggingFrame(NSRect(x: sp.x - 30, y: sp.y - 20, width: 60, height: 40), contents: image)
        beginDraggingSession(with: [item], event: NSApp.currentEvent ?? NSEvent(), source: self)
        mouseDownPt = nil
    }
}
