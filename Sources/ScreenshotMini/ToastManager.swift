import AppKit
import SwiftUI

@MainActor
class ToastManager {
    static let shared = ToastManager()

    private var panel: NSPanel?

    func show(message: String, preview: String? = nil) {
        panel?.orderOut(nil)

        let toastView = ToastView(message: message, preview: preview)
        let hostingView = NSHostingView(rootView: toastView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let width = max(hostingView.fittingSize.width, 200)
        let height = hostingView.fittingSize.height

        guard let screen = NSScreen.main else { return }
        let x = screen.frame.midX - width / 2
        let y = screen.visibleFrame.maxY - height - 12

        let toast = NSPanel(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        toast.isFloatingPanel = true
        toast.level = .statusBar
        toast.hasShadow = true
        toast.isOpaque = false
        toast.backgroundColor = .clear
        toast.contentView = hostingView
        toast.isMovableByWindowBackground = false

        toast.alphaValue = 0
        toast.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            toast.animator().alphaValue = 1
        }

        self.panel = toast

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, let panel = self.panel, panel === toast else { return }
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                panel.animator().alphaValue = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self, self.panel === toast else { return }
                toast.orderOut(nil)
                self.panel = nil
            }
        }
    }
}

struct ToastView: View {
    let message: String
    let preview: String?

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }

            if let preview, !preview.isEmpty {
                Text(preview)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 280)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.black.opacity(0.8))
        )
    }
}
