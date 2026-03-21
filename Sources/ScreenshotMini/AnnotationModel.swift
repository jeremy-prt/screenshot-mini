import SwiftUI

// MARK: - Shape types

enum AnnotationShape: Equatable, Sendable {
    case rect, circle, line, arrow, text, freehand
}

// MARK: - Single annotation

struct Annotation: Identifiable, Equatable {
    let id: UUID
    var shape: AnnotationShape
    var start: CGPoint
    var end: CGPoint
    var color: Color
    var lineWidth: CGFloat
    var filled: Bool
    var solidFill: Bool
    var text: String
    var fontSize: CGFloat
    var points: [CGPoint]

    init(shape: AnnotationShape, start: CGPoint, end: CGPoint,
         color: Color = .red, lineWidth: CGFloat = 3, filled: Bool = false, solidFill: Bool = false,
         text: String = "", fontSize: CGFloat = 20, points: [CGPoint] = []) {
        self.id = UUID()
        self.shape = shape
        self.start = start
        self.end = end
        self.color = color
        self.lineWidth = lineWidth
        self.filled = filled
        self.solidFill = solidFill
        self.text = text
        self.fontSize = fontSize
        self.points = points
    }

    var boundingRect: CGRect {
        if shape == .freehand && !points.isEmpty {
            let xs = points.map(\.x), ys = points.map(\.y)
            return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
        }
        if shape == .text {
            let w = max(CGFloat(text.count) * fontSize * 0.6, 20)
            let h = fontSize * 1.4
            return CGRect(x: start.x, y: start.y - h, width: w, height: h)
        }
        return CGRect(
            x: min(start.x, end.x), y: min(start.y, end.y),
            width: abs(end.x - start.x), height: abs(end.y - start.y)
        )
    }

    // MARK: - Hit testing

    func hitTest(_ point: CGPoint, tolerance: CGFloat = 10) -> Bool {
        switch shape {
        case .rect, .circle:
            if filled { return boundingRect.insetBy(dx: -tolerance, dy: -tolerance).contains(point) }
            let outer = boundingRect.insetBy(dx: -tolerance, dy: -tolerance)
            let inner = boundingRect.insetBy(dx: tolerance, dy: tolerance)
            return outer.contains(point) && (inner.width < 0 || inner.height < 0 || !inner.contains(point))
        case .line, .arrow:
            return distanceToSegment(point: point, from: start, to: end) < tolerance
        case .text:
            return boundingRect.insetBy(dx: -tolerance, dy: -tolerance).contains(point)
        case .freehand:
            guard points.count >= 2 else { return false }
            for i in 0..<(points.count - 1) {
                if distanceToSegment(point: point, from: points[i], to: points[i + 1]) < tolerance { return true }
            }
            return false
        }
    }

    func handleAt(_ point: CGPoint, tolerance: CGFloat = 10) -> ResizeHandle? {
        let r = boundingRect
        let corners: [(CGPoint, ResizeHandle)] = [
            (CGPoint(x: r.minX, y: r.minY), .topLeft),
            (CGPoint(x: r.maxX, y: r.minY), .topRight),
            (CGPoint(x: r.minX, y: r.maxY), .bottomLeft),
            (CGPoint(x: r.maxX, y: r.maxY), .bottomRight),
        ]
        for (corner, handle) in corners {
            if hypot(point.x - corner.x, point.y - corner.y) < tolerance {
                return handle
            }
        }
        return nil
    }

    private func distanceToSegment(point: CGPoint, from a: CGPoint, to b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else { return hypot(point.x - a.x, point.y - a.y) }
        let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lenSq))
        return hypot(point.x - (a.x + t * dx), point.y - (a.y + t * dy))
    }

    // MARK: - Resize

    mutating func resize(handle: ResizeHandle, to point: CGPoint) {
        switch handle {
        case .topLeft:
            start = CGPoint(x: min(point.x, end.x), y: min(point.y, end.y))
        case .topRight:
            end = CGPoint(x: max(point.x, start.x), y: end.y)
            start = CGPoint(x: start.x, y: min(point.y, end.y))
        case .bottomLeft:
            start = CGPoint(x: min(point.x, end.x), y: start.y)
            end = CGPoint(x: end.x, y: max(point.y, start.y))
        case .bottomRight:
            end = CGPoint(x: max(point.x, start.x), y: max(point.y, start.y))
        case .startPoint:
            start = point
        case .endPoint:
            end = point
        }
    }

    // MARK: - Move

    mutating func move(by delta: CGSize) {
        start.x += delta.width
        start.y += delta.height
        end.x += delta.width
        end.y += delta.height
        for i in points.indices {
            points[i].x += delta.width
            points[i].y += delta.height
        }
    }
}

// MARK: - Resize handle

enum ResizeHandle: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight
    case startPoint, endPoint
}

// MARK: - Undo manager

@MainActor
class AnnotationHistory: ObservableObject {
    @Published var annotations: [Annotation] = []
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    func save() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = prev
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}
