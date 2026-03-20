import SwiftUI
import AppKit

@MainActor
class EditorWindow {
    static let shared = EditorWindow()

    private var window: NSWindow?

    func open(image: NSImage, savePath: URL) {
        window?.close()

        let editorView = EditorView(
            image: image,
            onSave: { [weak self] in
                self?.save(image: image, to: savePath)
                self?.window?.close()
            },
            onCopy: {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([image])
                ToastManager.shared.show(message: L10n.lang == "en" ? "Copied!" : "Copié !")
            }
        )

        let hostingView = NSHostingView(rootView: editorView)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let maxW = screenFrame.width * 0.75
        let maxH = screenFrame.height * 0.75
        let imgSize = image.size
        let scale = min(maxW / max(imgSize.width, 1), maxH / max(imgSize.height, 1), 1.0)
        let contentW = max(imgSize.width * scale, 600)
        let contentH = max(imgSize.height * scale, 400) + 50

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: contentW, height: contentH),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Screenshot Mini"
        win.minSize = NSSize(width: 400, height: 300)
        win.contentView = hostingView
        win.center()
        win.isReleasedWhenClosed = false

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = win
    }

    private func save(image: NSImage, to savePath: URL) {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return }

        let format = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        let fileType: NSBitmapImageRep.FileType
        let ext: String

        switch format {
        case "jpeg": fileType = .jpeg; ext = "jpg"
        case "tiff": fileType = .tiff; ext = "tiff"
        default: fileType = .png; ext = "png"
        }

        let properties: [NSBitmapImageRep.PropertyKey: Any] = fileType == .jpeg
            ? [.compressionFactor: 0.9]
            : [:]

        guard let data = bitmap.representation(using: fileType, properties: properties) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Screenshot_\(formatter.string(from: Date())).\(ext)"
        let url = savePath.appending(path: filename)

        try? data.write(to: url)
        ToastManager.shared.show(message: L10n.lang == "en" ? "Saved!" : "Sauvegardé !")
    }
}

// MARK: - Editor View

struct EditorView: View {
    let image: NSImage
    let onSave: () -> Void
    let onCopy: () -> Void

    @State private var selectedTool: String? = nil

    private let tools: [(icon: String, id: String, label: String)] = [
        ("crop", "crop", "Crop"),
        ("rectangle", "rect", "Rectangle"),
        ("circle", "circle", "Circle"),
        ("line.diagonal", "line", "Line"),
        ("arrow.up.right", "arrow", "Arrow"),
        ("character.textbox", "text", "Text"),
        ("applepencil.gen1", "draw", "Draw"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Toolbar
            HStack(spacing: 2) {
                // Drawing tools
                ForEach(tools, id: \.id) { tool in
                    Button {
                        selectedTool = selectedTool == tool.id ? nil : tool.id
                    } label: {
                        Image(systemName: tool.icon)
                            .font(.system(size: 14))
                            .frame(width: 32, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTool == tool.id ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(tool.label)
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 6)

                // Drag me (drag & drop the image)
                DragMeButton(image: image)

                Spacer()

                // Copy
                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13))
                        .frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                .help("Copy")

                // Share
                Button {
                    // placeholder
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                .help("Share")

                // Save
                Button {
                    onSave()
                } label: {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // MARK: - Canvas
            ZStack(alignment: .topTrailing) {
                Color(nsColor: .controlBackgroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)

                // Work in progress banner
                HStack(spacing: 6) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11))
                    Text(L10n.lang == "en" ? "Editing interface under development — not all features are available" : "Interface d'édition en cours de développement — toutes les fonctionnalités ne sont pas disponibles")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.orange.opacity(0.85)))
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
        }
    }
}

// MARK: - Drag Me button (NSViewRepresentable for drag & drop)

struct DragMeButton: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> DragMeNSView {
        let view = DragMeNSView()
        view.image = image
        return view
    }

    func updateNSView(_ nsView: DragMeNSView, context: Context) {
        nsView.image = image
    }
}

final class DragMeNSView: NSView, NSDraggingSource {
    var image: NSImage?
    private var mouseDownPoint: NSPoint?

    override var intrinsicContentSize: NSSize { NSSize(width: 80, height: 28) }

    override func draw(_ dirtyRect: NSRect) {
        // Draw "Drag me" label
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let str = NSAttributedString(string: "Drag me", attributes: attrs)
        let size = str.size()
        let x = (bounds.width - size.width) / 2
        let y = (bounds.height - size.height) / 2
        str.draw(at: NSPoint(x: x, y: y))
    }

    nonisolated func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation { [.copy] }

    override func mouseDown(with event: NSEvent) {
        mouseDownPoint = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let image, let startPoint = mouseDownPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        guard hypot(current.x - startPoint.x, current.y - startPoint.y) > 4 else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Screenshot_drag.png")
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            try? png.write(to: tempURL)
        }

        let dragItem = NSDraggingItem(pasteboardWriter: tempURL as NSURL)
        let thumbSize = NSSize(width: 60, height: 40)
        dragItem.setDraggingFrame(
            NSRect(x: startPoint.x - thumbSize.width / 2,
                   y: startPoint.y - thumbSize.height / 2,
                   width: thumbSize.width, height: thumbSize.height),
            contents: image
        )

        beginDraggingSession(with: [dragItem], event: NSApp.currentEvent ?? NSEvent(), source: self)
        mouseDownPoint = nil
    }
}
