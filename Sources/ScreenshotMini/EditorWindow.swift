import SwiftUI
import AppKit

// MARK: - Brand color

let brandPurple = Color(red: 0x9F / 255.0, green: 0x01 / 255.0, blue: 0xA0 / 255.0)

// MARK: - Editor Window

@MainActor
class EditorWindow {
    static let shared = EditorWindow()
    private var window: NSWindow?

    func open(image: NSImage, savePath: URL) {
        window?.close()

        let editorView = EditorView(originalImage: image, savePath: savePath, onClose: { [weak self] in
            self?.window?.close()
        })

        let hostingView = NSHostingView(rootView: editorView)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let maxW = screen.width * 0.75, maxH = screen.height * 0.75
        let s = min(maxW / max(image.size.width, 1), maxH / max(image.size.height, 1), 1.0)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: max(image.size.width * s, 600), height: max(image.size.height * s, 400) + 50),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered, defer: false
        )
        win.title = "Screenshot Mini"
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.styleMask.insert(.fullSizeContentView)
        win.minSize = NSSize(width: 400, height: 300)
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = win
    }
}

// MARK: - Save helper

@MainActor
private func saveImage(_ image: NSImage, to savePath: URL) {
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

private extension DateFormatter {
    static let yyyyMMdd_HHmmss: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HH-mm-ss"; return f
    }()
}

// MARK: - Crop helper

private func cropImage(_ image: NSImage, to rect: CGRect, canvasSize: CGSize) -> NSImage {
    let scaleX = image.size.width / canvasSize.width
    let scaleY = image.size.height / canvasSize.height
    let cropRect = CGRect(x: rect.origin.x * scaleX, y: rect.origin.y * scaleY,
                          width: rect.width * scaleX, height: rect.height * scaleY)
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
          let cropped = cg.cropping(to: cropRect) else { return image }
    return NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
}

// MARK: - Flatten annotations

private func flattenAnnotations(_ annotations: [Annotation], onto image: NSImage, canvasSize: CGSize) -> NSImage {
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

// MARK: - Editor View

struct EditorView: View {
    let originalImage: NSImage
    let savePath: URL
    let onClose: () -> Void

    @State private var currentImage: NSImage
    @State private var selectedTool: String? = nil
    @StateObject private var history = AnnotationHistory()

    // Selection & hover
    @State private var selectedId: UUID? = nil
    @State private var hoveredId: UUID? = nil
    @State private var interaction: CanvasInteraction = .none

    // Crop
    @State private var cropStart: CGPoint? = nil
    @State private var cropEnd: CGPoint? = nil
    @State private var canvasSize: CGSize = .zero

    // Text editing
    @State private var editingTextId: UUID? = nil
    @State private var editingText: String = ""

    // Annotation defaults
    @State private var annotationColor: Color = .red
    @State private var annotationLineWidth: CGFloat = 3
    @State private var annotationFilled: Bool = false
    @State private var fontSize: CGFloat = 20

    private var selectedAnnotation: Annotation? {
        guard let id = selectedId else { return nil }
        return history.annotations.first { $0.id == id }
    }

    private var activeShapeTool: AnnotationShape? {
        switch selectedTool {
        case "rect": .rect; case "circle": .circle
        case "line": .line; case "arrow": .arrow
        case "text": .text; case "draw": .freehand
        default: nil
        }
    }

    init(originalImage: NSImage, savePath: URL, onClose: @escaping () -> Void) {
        self.originalImage = originalImage
        self.savePath = savePath
        self.onClose = onClose
        self._currentImage = State(initialValue: originalImage)
    }

    private let tools: [(icon: String, id: String, label: String, shortcut: String)] = [
        ("cursorarrow", "cursor", "Select", "V"),
        ("crop", "crop", "Crop", "C"),
        ("rectangle", "rect", "Rectangle", "R"),
        ("circle", "circle", "Ellipse", "O"),
        ("line.diagonal", "line", "Line", "L"),
        ("arrow.up.right", "arrow", "Arrow", "A"),
        ("character.textbox", "text", "Text", "T"),
        ("applepencil.gen1", "draw", "Draw", "D"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            canvas
        }
        .ignoresSafeArea()
        .background(
            Group {
                Button("") { history.undo(); syncSelection() }
                    .keyboardShortcut("z", modifiers: .command).hidden()
                Button("") { history.redo(); syncSelection() }
                    .keyboardShortcut("z", modifiers: [.command, .shift]).hidden()
                Button("") { deleteSelected() }
                    .keyboardShortcut(.delete, modifiers: []).hidden()
                Button("") { moveSelected(dx: 0, dy: -1) }
                    .keyboardShortcut(.upArrow, modifiers: []).hidden()
                Button("") { moveSelected(dx: 0, dy: 1) }
                    .keyboardShortcut(.downArrow, modifiers: []).hidden()
                Button("") { moveSelected(dx: -1, dy: 0) }
                    .keyboardShortcut(.leftArrow, modifiers: []).hidden()
                Button("") { moveSelected(dx: 1, dy: 0) }
                    .keyboardShortcut(.rightArrow, modifiers: []).hidden()
                // Tool shortcuts
                Button("") { selectTool("cursor") }.keyboardShortcut("v", modifiers: []).hidden()
                Button("") { selectTool("crop") }.keyboardShortcut("c", modifiers: []).hidden()
                Button("") { selectTool("rect") }.keyboardShortcut("r", modifiers: []).hidden()
                Button("") { selectTool("circle") }.keyboardShortcut("o", modifiers: []).hidden()
                Button("") { selectTool("line") }.keyboardShortcut("l", modifiers: []).hidden()
                Button("") { selectTool("arrow") }.keyboardShortcut("a", modifiers: []).hidden()
                Button("") { selectTool("text") }.keyboardShortcut("t", modifiers: []).hidden()
                Button("") { selectTool("draw") }.keyboardShortcut("d", modifiers: []).hidden()
                Button("") { selectTool(nil) }.keyboardShortcut(.escape, modifiers: []).hidden()
            }
            .frame(width: 0, height: 0)
        )
    }

    // MARK: - Toolbar (in titlebar)

    private var toolbar: some View {
        HStack(spacing: 2) {
            // Left padding for traffic light buttons
            Color.clear.frame(width: 70, height: 1)

            // Tools
            ForEach(tools, id: \.id) { tool in
                ToolbarButton(
                    icon: tool.icon,
                    label: tool.label,
                    shortcut: tool.shortcut,
                    isActive: selectedTool == tool.id
                ) {
                    selectTool(selectedTool == tool.id ? nil : tool.id)
                }
            }

            // Crop confirm
            if selectedTool == "crop" && cropStart != nil && cropEnd != nil {
                Divider().frame(height: 20).padding(.horizontal, 4)
                ToolbarButton(icon: "checkmark", label: "Apply", shortcut: "↩", isActive: false) { applyCrop() }
                ToolbarButton(icon: "xmark", label: "Cancel", shortcut: "Esc", isActive: false) { cancelTool() }
            }

            Divider().frame(height: 18).padding(.horizontal, 4)
            DragMeButton(image: currentImage)

            Spacer()

            // Undo/Redo
            ToolbarButton(icon: "arrow.uturn.backward", label: "Undo", shortcut: "⌘Z", isActive: false) {
                history.undo(); syncSelection()
            }
            ToolbarButton(icon: "arrow.uturn.forward", label: "Redo", shortcut: "⌘⇧Z", isActive: false) {
                history.redo(); syncSelection()
            }

            // Copy
            Button {
                let img = flattenAnnotations(history.annotations, onto: currentImage, canvasSize: canvasSize)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([img])
                ToastManager.shared.show(message: L10n.lang == "en" ? "Copied!" : "Copié !")
            } label: {
                Image(systemName: "doc.on.doc").font(.system(size: 13)).frame(width: 28, height: 28)
            }.buttonStyle(.plain).help("Copy")

            // Save
            Button {
                let img = flattenAnnotations(history.annotations, onto: currentImage, canvasSize: canvasSize)
                saveImage(img, to: savePath)
                onClose()
            } label: {
                Text("Save").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(brandPurple))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 4).frame(height: 38).background(.bar)
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack(alignment: .topTrailing) {
            Color(nsColor: .controlBackgroundColor).frame(maxWidth: .infinity, maxHeight: .infinity)

            GeometryReader { geo in
                let imgSize = currentImage.size
                let scale = min(geo.size.width / max(imgSize.width, 1), geo.size.height / max(imgSize.height, 1))
                let dw = imgSize.width * scale, dh = imgSize.height * scale
                let ox = (geo.size.width - dw) / 2, oy = (geo.size.height - dh) / 2

                ZStack(alignment: .topLeading) {
                    Image(nsImage: currentImage).resizable().aspectRatio(contentMode: .fit)
                        .frame(width: dw, height: dh)

                    // Annotations
                    ForEach(history.annotations) { ann in
                        AnnotationView(annotation: ann)
                    }.frame(width: dw, height: dh)

                    // Hover highlight
                    if let hId = hoveredId, hId != selectedId,
                       let hAnn = history.annotations.first(where: { $0.id == hId }) {
                        HoverOverlay(annotation: hAnn).frame(width: dw, height: dh)
                    }

                    // Drawing in progress
                    if case .drawing(let ann) = interaction {
                        AnnotationView(annotation: ann).frame(width: dw, height: dh)
                    }
                    if case .freehand(let pts) = interaction, pts.count >= 2 {
                        FreehandPreview(points: pts, color: annotationColor, lineWidth: annotationLineWidth)
                            .frame(width: dw, height: dh)
                    }

                    // Text editing overlay
                    if let editId = editingTextId,
                       let ann = history.annotations.first(where: { $0.id == editId }) {
                        TextEditingOverlay(
                            text: $editingText,
                            position: ann.start,
                            fontSize: ann.fontSize,
                            color: ann.color,
                            onCommit: { commitTextEdit() }
                        )
                        .frame(width: dw, height: dh)
                    }

                    // Selection
                    if let sel = selectedAnnotation, editingTextId != sel.id {
                        SelectionOverlay(annotation: sel).frame(width: dw, height: dh)
                    }

                    // Crop
                    if selectedTool == "crop", let s = cropStart, let e = cropEnd {
                        let r = normalizedRect(from: s, to: e)
                        Color.black.opacity(0.4).frame(width: dw, height: dh)
                            .mask(CropMask(rect: r, size: CGSize(width: dw, height: dh)))
                        Rectangle().stroke(Color.white, lineWidth: 2)
                            .frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
                    }
                }
                .frame(width: dw, height: dh)
                .offset(x: ox, y: oy)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { v in handleDrag(v, dw: dw, dh: dh, ox: ox, oy: oy) }
                        .onEnded { v in handleDragEnd(v, dw: dw, dh: dh, ox: ox, oy: oy) }
                )
                .onTapGesture { loc in handleTap(loc, dw: dw, dh: dh, ox: ox, oy: oy) }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        let pt = canvasPoint(loc, dw: dw, dh: dh, ox: ox, oy: oy)
                        updateCursor(at: pt)
                        hoveredId = history.annotations.last(where: { $0.hitTest(pt) })?.id
                    case .ended:
                        NSCursor.arrow.set()
                        hoveredId = nil
                    }
                }
                .onAppear { canvasSize = CGSize(width: dw, height: dh) }
            }

            // Annotation properties toolbar (top-right)
            if showPropertiesToolbar {
                AnnotationToolbar(
                    annotation: propertiesToolbarAnnotation,
                    onChangeColor: { c in setAnnotationColor(c); annotationColor = c },
                    onChangeLineWidth: { w in setAnnotationLineWidth(w); annotationLineWidth = w },
                    onChangeFillMode: { m in setAnnotationFillMode(m) },
                    onChangeFontSize: { s in setAnnotationFontSize(s); fontSize = s },
                    onDeselect: { selectedId = nil; selectedTool = nil },
                    onDelete: { deleteSelected() }
                )
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).layoutPriority(1)
    }

    // MARK: - Gesture handling

    private func canvasPoint(_ location: CGPoint, dw: CGFloat, dh: CGFloat, ox: CGFloat, oy: CGFloat) -> CGPoint {
        CGPoint(x: max(0, min(location.x - ox, dw)), y: max(0, min(location.y - oy, dh)))
    }

    private func handleDrag(_ value: DragGesture.Value, dw: CGFloat, dh: CGFloat, ox: CGFloat, oy: CGFloat) {
        let start = canvasPoint(value.startLocation, dw: dw, dh: dh, ox: ox, oy: oy)
        let current = canvasPoint(value.location, dw: dw, dh: dh, ox: ox, oy: oy)
        canvasSize = CGSize(width: dw, height: dh)

        // Determine interaction on first move
        if case .none = interaction {
            if selectedTool == "crop" {
                cropStart = start; cropEnd = current; return
            }

            // Priority 1: Resize handle of selected annotation
            if let id = selectedId,
               let ann = history.annotations.first(where: { $0.id == id }),
               let handle = ann.handleAt(start) {
                history.save()
                interaction = .resizing(id, handle)
            }
            // Priority 2: Move the selected annotation if clicking on it
            else if let id = selectedId,
                    let ann = history.annotations.first(where: { $0.id == id }),
                    ann.hitTest(start) {
                history.save()
                interaction = .moving(id, start)
            }
            // Priority 3: Select + move another annotation if clicking on it (no tool required)
            else if let hit = history.annotations.last(where: { $0.hitTest(start) }),
                    activeShapeTool == nil {
                selectedId = hit.id
                history.save()
                interaction = .moving(hit.id, start)
            }
            // Priority 4: Draw new shape if tool is active
            else if selectedTool == "draw" {
                selectedId = nil
                commitTextIfNeeded()
                interaction = .freehand([start, current])
            }
            else if let shape = activeShapeTool, shape != .text {
                selectedId = nil
                commitTextIfNeeded()
                interaction = .drawing(Annotation(shape: shape, start: start, end: current,
                                                  color: annotationColor, lineWidth: annotationLineWidth, filled: annotationFilled))
            }
            // Priority 5: Deselect if clicking on nothing
            else {
                selectedId = nil
            }
        }

        // Continue interaction
        switch interaction {
        case .drawing(var ann):
            ann.end = current
            interaction = .drawing(ann)
        case .freehand(var pts):
            pts.append(current)
            interaction = .freehand(pts)
        case .moving(let id, let lastPt):
            if let idx = history.annotations.firstIndex(where: { $0.id == id }) {
                let dx = current.x - lastPt.x, dy = current.y - lastPt.y
                history.annotations[idx].move(by: CGSize(width: dx, height: dy))
                interaction = .moving(id, current)
            }
        case .resizing(let id, let handle):
            if let idx = history.annotations.firstIndex(where: { $0.id == id }) {
                history.annotations[idx].resize(handle: handle, to: current)
            }
        case .none:
            if selectedTool == "crop" { cropEnd = current }
        }
    }

    private func handleDragEnd(_ value: DragGesture.Value, dw: CGFloat, dh: CGFloat, ox: CGFloat, oy: CGFloat) {
        switch interaction {
        case .drawing(let ann):
            let dist = hypot(abs(ann.end.x - ann.start.x), abs(ann.end.y - ann.start.y))
            if dist > 5 {
                history.save()
                history.annotations.append(ann)
                selectedId = ann.id
                selectedTool = nil
            }
        case .freehand(let pts):
            if pts.count >= 3 {
                let xs = pts.map(\.x), ys = pts.map(\.y)
                let ann = Annotation(shape: .freehand,
                                     start: CGPoint(x: xs.min()!, y: ys.min()!),
                                     end: CGPoint(x: xs.max()!, y: ys.max()!),
                                     color: annotationColor, lineWidth: annotationLineWidth,
                                     points: pts)
                history.save()
                history.annotations.append(ann)
                selectedId = ann.id
                selectedTool = nil
            }
        case .moving, .resizing:
            break
        case .none:
            break
        }
        interaction = .none
    }

    private func handleTap(_ location: CGPoint, dw: CGFloat, dh: CGFloat, ox: CGFloat, oy: CGFloat) {
        let pt = canvasPoint(location, dw: dw, dh: dh, ox: ox, oy: oy)

        // Text tool: click to place text
        if selectedTool == "text" {
            commitTextIfNeeded()
            let ann = Annotation(shape: .text, start: pt, end: pt,
                                 color: annotationColor, fontSize: fontSize)
            history.save()
            history.annotations.append(ann)
            selectedId = ann.id
            editingTextId = ann.id
            editingText = ""
            return
        }

        // Double-click on text annotation to re-edit
        if let hit = history.annotations.last(where: { $0.hitTest(pt) }),
           hit.shape == .text, editingTextId == nil {
            selectedId = hit.id
            editingTextId = hit.id
            editingText = hit.text
            return
        }

        commitTextIfNeeded()

        if activeShapeTool == nil && selectedTool != "crop" {
            if let hit = history.annotations.last(where: { $0.hitTest(pt) }) {
                selectedId = hit.id
            } else {
                selectedId = nil
            }
        }
    }

    // MARK: - Helpers

    private func normalizedRect(from s: CGPoint, to e: CGPoint) -> CGRect {
        CGRect(x: min(s.x, e.x), y: min(s.y, e.y), width: abs(e.x - s.x), height: abs(e.y - s.y))
    }

    private func applyCrop() {
        guard let s = cropStart, let e = cropEnd else { return }
        let rect = normalizedRect(from: s, to: e)
        guard rect.width > 5 && rect.height > 5 else { return }
        if !history.annotations.isEmpty {
            currentImage = flattenAnnotations(history.annotations, onto: currentImage, canvasSize: canvasSize)
            history.annotations.removeAll()
        }
        currentImage = cropImage(currentImage, to: rect, canvasSize: canvasSize)
        cancelTool()
    }

    private func selectTool(_ tool: String?) {
        if editingTextId != nil { commitTextIfNeeded() }
        if tool == selectedTool { selectedTool = nil } else { selectedTool = tool }
        selectedId = nil; cropStart = nil; cropEnd = nil; interaction = .none
    }

    private func cancelTool() {
        commitTextIfNeeded()
        selectedTool = nil; cropStart = nil; cropEnd = nil; interaction = .none
    }

    private func deleteSelected() {
        guard let id = selectedId else { return }
        history.save()
        history.annotations.removeAll { $0.id == id }
        selectedId = nil
    }

    private func updateCursor(at point: CGPoint) {
        if selectedTool == "text" {
            NSCursor.iBeam.set()
            return
        }
        // If a tool is active, use crosshair
        if activeShapeTool != nil || selectedTool == "crop" {
            NSCursor.crosshair.set()
            return
        }

        // Check resize handles on selected annotation
        if let id = selectedId,
           let ann = history.annotations.first(where: { $0.id == id }),
           ann.handleAt(point) != nil {
            NSCursor.crosshair.set() // resize cursor
            return
        }

        // Check if hovering over any annotation
        if history.annotations.contains(where: { $0.hitTest(point) }) {
            NSCursor.openHand.set()
            return
        }

        NSCursor.arrow.set()
    }

    private func moveSelected(dx: CGFloat, dy: CGFloat) {
        guard let id = selectedId,
              let idx = history.annotations.firstIndex(where: { $0.id == id }) else { return }
        history.save()
        history.annotations[idx].move(by: CGSize(width: dx, height: dy))
    }

    private func syncSelection() {
        if let id = selectedId, !history.annotations.contains(where: { $0.id == id }) {
            selectedId = nil
        }
    }

    private var shouldShowFill: Bool {
        if let sel = selectedAnnotation { return sel.shape == .rect || sel.shape == .circle }
        return selectedTool == "rect" || selectedTool == "circle"
    }

    private var isFilled: Bool { selectedAnnotation?.filled ?? annotationFilled }

    private var showPropertiesToolbar: Bool {
        if selectedId != nil { return true }
        if let tool = selectedTool, tool != "crop" && tool != "cursor" { return true }
        return false
    }

    private var propertiesToolbarAnnotation: Annotation {
        if let sel = selectedAnnotation { return sel }
        // Build a dummy annotation from current defaults for toolbar display
        let shape: AnnotationShape = switch selectedTool {
            case "rect": .rect; case "circle": .circle
            case "line": .line; case "arrow": .arrow
            case "text": .text; case "draw": .freehand
            default: .rect
        }
        return Annotation(shape: shape, start: .zero, end: .zero,
                          color: annotationColor, lineWidth: annotationLineWidth,
                          fontSize: fontSize)
    }

    private var isTextContext: Bool {
        if let sel = selectedAnnotation { return sel.shape == .text }
        return selectedTool == "text"
    }

    private func commitTextIfNeeded() {
        guard let id = editingTextId else { return }
        if editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            history.annotations.removeAll { $0.id == id }
            selectedId = nil
        } else if let idx = history.annotations.firstIndex(where: { $0.id == id }) {
            history.annotations[idx].text = editingText
        }
        editingTextId = nil
        editingText = ""
    }

    private func commitTextEdit() {
        commitTextIfNeeded()
        selectedTool = nil
    }

    private func adjustFontSize(_ delta: CGFloat) {
        if let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) {
            history.save()
            history.annotations[idx].fontSize = max(8, min(120, history.annotations[idx].fontSize + delta))
        } else {
            fontSize = max(8, min(120, fontSize + delta))
        }
    }

    private func setAnnotationColor(_ color: Color) {
        annotationColor = color
        guard let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) else { return }
        history.save()
        history.annotations[idx].color = color
    }

    private func setAnnotationLineWidth(_ width: CGFloat) {
        annotationLineWidth = width
        guard let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) else { return }
        history.save()
        history.annotations[idx].lineWidth = width
    }

    private func setAnnotationFillMode(_ mode: FillMode) {
        guard let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) else { return }
        history.save()
        switch mode {
        case .outline:
            history.annotations[idx].filled = false
            history.annotations[idx].solidFill = false
        case .semiFilled:
            history.annotations[idx].filled = true
            history.annotations[idx].solidFill = false
        case .solidFilled:
            history.annotations[idx].filled = true
            history.annotations[idx].solidFill = true
        }
    }

    private func setAnnotationFontSize(_ size: CGFloat) {
        fontSize = size
        guard let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) else { return }
        history.save()
        history.annotations[idx].fontSize = size
    }

    private func adjustLineWidth(_ delta: CGFloat) {
        if let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) {
            history.save()
            history.annotations[idx].lineWidth = max(1, min(20, history.annotations[idx].lineWidth + delta))
        } else {
            annotationLineWidth = max(1, min(20, annotationLineWidth + delta))
        }
    }

    private func toggleFill() {
        if let id = selectedId, let idx = history.annotations.firstIndex(where: { $0.id == id }) {
            history.save()
            history.annotations[idx].filled.toggle()
        } else {
            annotationFilled.toggle()
        }
    }
}

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

// MARK: - Fill mode

enum FillMode: String, CaseIterable {
    case outline, semiFilled, solidFilled
}

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
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Floating Annotation Toolbar

struct AnnotationToolbar: View {
    let annotation: Annotation
    let onChangeColor: (Color) -> Void
    let onChangeLineWidth: (CGFloat) -> Void
    let onChangeFillMode: (FillMode) -> Void
    let onChangeFontSize: (CGFloat) -> Void
    let onDeselect: () -> Void
    let onDelete: () -> Void

    private let presetColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]

    var body: some View {
        HStack(spacing: 6) {
            // Back / deselect
            Button { onDeselect() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 22, height: 22)
            }.buttonStyle(.plain)

            Divider().frame(height: 18)

            // Preset colors
            HStack(spacing: 3) {
                ForEach(presetColors, id: \.self) { c in
                    Circle()
                        .fill(c)
                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
                        .overlay(
                            annotation.color == c
                                ? Circle().stroke(brandPurple, lineWidth: 2).padding(-2)
                                : nil
                        )
                        .frame(width: 18, height: 18)
                        .onTapGesture { onChangeColor(c) }
                }
            }

            Divider().frame(height: 18)

            // Thickness or font size
            if annotation.shape == .text {
                HStack(spacing: 1) {
                    Button { onChangeFontSize(max(8, annotation.fontSize - 2)) } label: {
                        Image(systemName: "minus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 22)
                    }.buttonStyle(.plain)
                    Text("\(Int(annotation.fontSize))px")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary).frame(width: 34)
                    Button { onChangeFontSize(min(80, annotation.fontSize + 2)) } label: {
                        Image(systemName: "plus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 22)
                    }.buttonStyle(.plain)
                }
            } else {
                thicknessControl
            }

            // Fill modes (only for rect/circle)
            if annotation.shape == .rect || annotation.shape == .circle {
                Divider().frame(height: 18)
                HStack(spacing: 2) {
                    fillButton(icon: "square", mode: .outline,
                               active: !annotation.filled)
                    fillButton(icon: "square.fill", mode: .semiFilled,
                               active: annotation.filled && !annotation.solidFill)
                    fillButton(icon: "square.inset.filled", mode: .solidFilled,
                               active: annotation.filled && annotation.solidFill)
                }
            }

            Divider().frame(height: 18)

            // Delete
            Button { onDelete() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .frame(width: 22, height: 22)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 0.5))
        )
    }

    // Custom thickness control with line preview
    private var thicknessControl: some View {
        HStack(spacing: 1) {
            Button { onChangeLineWidth(max(1, annotation.lineWidth - 1)) } label: {
                Image(systemName: "minus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 22)
            }.buttonStyle(.plain)

            // Line thickness visual preview
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary)
                    .frame(width: 30, height: max(1, min(annotation.lineWidth, 12)))
            }
            .frame(width: 30, height: 22)

            Text("\(Int(annotation.lineWidth))")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary).frame(width: 16)

            Button { onChangeLineWidth(min(20, annotation.lineWidth + 1)) } label: {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold)).frame(width: 20, height: 22)
            }.buttonStyle(.plain)
        }
    }

    private func fillButton(icon: String, mode: FillMode, active: Bool) -> some View {
        Button { onChangeFillMode(mode) } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 24, height: 22)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(active ? brandPurple.opacity(0.2) : Color.clear))
        }.buttonStyle(.plain)
    }
}

// MARK: - Toolbar Button with custom tooltip

struct ToolbarButton: View {
    let icon: String
    let label: String
    let shortcut: String
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var showTooltip = false
    @State private var hoverTask: Task<Void, Never>?

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 30, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? brandPurple.opacity(0.2) :
                              isHovered ? brandPurple.opacity(0.1) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            hoverTask?.cancel()
            if hovering {
                hoverTask = Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    showTooltip = true
                }
            } else {
                showTooltip = false
            }
        }
        .popover(isPresented: $showTooltip, arrowEdge: .bottom) {
            HStack(spacing: 4) {
                Text(label).font(.system(size: 11, weight: .medium))
                Text("(\(shortcut))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
        }
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
