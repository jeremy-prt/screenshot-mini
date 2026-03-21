import SwiftUI

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
        Button(action: {
            showTooltip = false
            action()
        }) {
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
        .overlay(alignment: .bottom) {
            if showTooltip {
                HStack(spacing: 4) {
                    Text(label).font(.system(size: 11, weight: .medium))
                    Text("(\(shortcut))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                )
                .offset(y: 32)
                .fixedSize()
                .allowsHitTesting(false)
            }
        }
        .zIndex(showTooltip ? 100 : 0)
    }
}
