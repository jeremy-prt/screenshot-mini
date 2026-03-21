import SwiftUI

// MARK: - Fill mode

enum FillMode: String, CaseIterable {
    case outline, semiFilled, solidFilled
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
