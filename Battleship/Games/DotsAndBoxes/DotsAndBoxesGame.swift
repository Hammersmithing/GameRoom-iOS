import Foundation

enum DotsPlayer: Equatable {
    case red, blue

    var opponent: DotsPlayer { self == .red ? .blue : .red }
    var name: String { self == .red ? "Red" : "Blue" }
    var initial: String { self == .red ? "R" : "B" }
}

enum LineOrientation {
    case horizontal, vertical
}

enum DotsAndBoxesResult: Equatable {
    case win(DotsPlayer)
    case draw
}

class DotsAndBoxesGame: ObservableObject {
    static let size = 5

    /// horizontalLines[row][col] — row in 0...size, col in 0..<size
    @Published var horizontalLines: [[DotsPlayer?]]
    /// verticalLines[row][col] — row in 0..<size, col in 0...size
    @Published var verticalLines: [[DotsPlayer?]]
    @Published var boxes: [[DotsPlayer?]]
    @Published var currentTurn: DotsPlayer = .red
    @Published var result: DotsAndBoxesResult? = nil

    init() {
        horizontalLines = Self.emptyHorizontal()
        verticalLines = Self.emptyVertical()
        boxes = Self.emptyBoxes()
    }

    static func emptyHorizontal() -> [[DotsPlayer?]] {
        Array(repeating: Array(repeating: nil, count: size), count: size + 1)
    }

    static func emptyVertical() -> [[DotsPlayer?]] {
        Array(repeating: Array(repeating: nil, count: size + 1), count: size)
    }

    static func emptyBoxes() -> [[DotsPlayer?]] {
        Array(repeating: Array(repeating: nil, count: size), count: size)
    }

    func reset() {
        horizontalLines = Self.emptyHorizontal()
        verticalLines = Self.emptyVertical()
        boxes = Self.emptyBoxes()
        currentTurn = .red
        result = nil
    }

    func count(_ player: DotsPlayer) -> Int {
        var n = 0
        for row in boxes {
            for cell in row where cell == player { n += 1 }
        }
        return n
    }

    func draw(_ orientation: LineOrientation, row: Int, col: Int) {
        guard result == nil else { return }
        switch orientation {
        case .horizontal:
            guard row >= 0, row <= Self.size, col >= 0, col < Self.size else { return }
            guard horizontalLines[row][col] == nil else { return }
            horizontalLines[row][col] = currentTurn
        case .vertical:
            guard row >= 0, row < Self.size, col >= 0, col <= Self.size else { return }
            guard verticalLines[row][col] == nil else { return }
            verticalLines[row][col] = currentTurn
        }

        var newlyClaimed = 0
        for r in 0..<Self.size {
            for c in 0..<Self.size where boxes[r][c] == nil && isBoxComplete(r: r, c: c) {
                boxes[r][c] = currentTurn
                newlyClaimed += 1
            }
        }

        if isAllDrawn() {
            finish()
            return
        }

        if newlyClaimed == 0 {
            currentTurn = currentTurn.opponent
        }
    }

    private func isBoxComplete(r: Int, c: Int) -> Bool {
        horizontalLines[r][c] != nil
            && horizontalLines[r + 1][c] != nil
            && verticalLines[r][c] != nil
            && verticalLines[r][c + 1] != nil
    }

    private func isAllDrawn() -> Bool {
        for row in horizontalLines {
            if row.contains(where: { $0 == nil }) { return false }
        }
        for row in verticalLines {
            if row.contains(where: { $0 == nil }) { return false }
        }
        return true
    }

    private func finish() {
        let r = count(.red), b = count(.blue)
        if r > b { result = .win(.red) }
        else if b > r { result = .win(.blue) }
        else { result = .draw }
    }
}
