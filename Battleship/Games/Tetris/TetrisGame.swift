import Foundation

enum TetrominoType: CaseIterable, Equatable {
    case I, O, T, S, Z, L, J

    static let baseShapes: [TetrominoType: [(Int, Int)]] = [
        .I: [(1,0),(1,1),(1,2),(1,3)],
        .O: [(0,1),(0,2),(1,1),(1,2)],
        .T: [(0,1),(1,0),(1,1),(1,2)],
        .S: [(0,1),(0,2),(1,0),(1,1)],
        .Z: [(0,0),(0,1),(1,1),(1,2)],
        .L: [(0,2),(1,0),(1,1),(1,2)],
        .J: [(0,0),(1,0),(1,1),(1,2)]
    ]

    func cells(rotation: Int) -> [(Int, Int)] {
        if self == .O { return Self.baseShapes[self]! }
        var cells = Self.baseShapes[self]!
        let r = ((rotation % 4) + 4) % 4
        for _ in 0..<r {
            cells = cells.map { (row, col) in (col, 3 - row) }
        }
        return cells
    }
}

struct ActivePiece: Equatable {
    let type: TetrominoType
    var rotation: Int
    var row: Int
    var col: Int

    var cells: [(Int, Int)] { type.cells(rotation: rotation) }

    func absoluteCells() -> [(Int, Int)] {
        cells.map { (row + $0.0, col + $0.1) }
    }
}

class TetrisGame: ObservableObject {
    static let rows = 20
    static let cols = 10

    @Published var grid: [[TetrominoType?]]
    @Published var current: ActivePiece? = nil
    @Published var nextType: TetrominoType = .I
    @Published var score: Int = 0
    @Published var lines: Int = 0
    @Published var level: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false

    private var lastDropTime: Date = Date()

    init() {
        grid = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
        reset()
    }

    func reset() {
        grid = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
        score = 0
        lines = 0
        level = 0
        isGameOver = false
        isPaused = false
        nextType = TetrominoType.allCases.randomElement() ?? .I
        spawn()
        lastDropTime = Date()
    }

    func togglePause() {
        guard !isGameOver else { return }
        isPaused.toggle()
    }

    var dropInterval: TimeInterval {
        max(0.05, 0.8 - Double(level) * 0.07)
    }

    func tick() {
        guard !isGameOver, !isPaused, current != nil else { return }
        if Date().timeIntervalSince(lastDropTime) >= dropInterval {
            stepDown()
            lastDropTime = Date()
        }
    }

    func moveLeft() {
        guard !isGameOver, !isPaused, var p = current else { return }
        p.col -= 1
        if isValid(p) { current = p }
    }

    func moveRight() {
        guard !isGameOver, !isPaused, var p = current else { return }
        p.col += 1
        if isValid(p) { current = p }
    }

    func rotate() {
        guard !isGameOver, !isPaused, var p = current else { return }
        p.rotation = (p.rotation + 1) % 4
        if isValid(p) {
            current = p
            return
        }
        for kick in [-1, 1, -2, 2] {
            var k = p
            k.col += kick
            if isValid(k) { current = k; return }
        }
    }

    func softDrop() {
        guard !isGameOver, !isPaused else { return }
        stepDown()
        lastDropTime = Date()
    }

    func hardDrop() {
        guard !isGameOver, !isPaused, var p = current else { return }
        while true {
            var trial = p
            trial.row += 1
            if isValid(trial) { p = trial } else { break }
        }
        current = p
        lock()
        lastDropTime = Date()
    }

    private func stepDown() {
        guard var p = current else { return }
        var trial = p
        trial.row += 1
        if isValid(trial) {
            p = trial
            current = p
        } else {
            lock()
        }
    }

    private func isValid(_ piece: ActivePiece) -> Bool {
        for (dr, dc) in piece.cells {
            let r = piece.row + dr
            let c = piece.col + dc
            if c < 0 || c >= Self.cols { return false }
            if r >= Self.rows { return false }
            if r >= 0 && grid[r][c] != nil { return false }
        }
        return true
    }

    private func lock() {
        guard let p = current else { return }
        for (dr, dc) in p.cells {
            let r = p.row + dr
            let c = p.col + dc
            if r >= 0 && r < Self.rows && c >= 0 && c < Self.cols {
                grid[r][c] = p.type
            }
        }
        current = nil
        clearLines()
        spawn()
    }

    private func clearLines() {
        var newGrid: [[TetrominoType?]] = []
        var cleared = 0
        for row in grid {
            if row.allSatisfy({ $0 != nil }) {
                cleared += 1
            } else {
                newGrid.append(row)
            }
        }
        for _ in 0..<cleared {
            newGrid.insert(Array(repeating: nil, count: Self.cols), at: 0)
        }
        grid = newGrid

        if cleared > 0 {
            let bonus = [0, 100, 300, 500, 800][cleared]
            score += bonus * (level + 1)
            lines += cleared
            level = lines / 10
        }
    }

    private func spawn() {
        let type = nextType
        nextType = TetrominoType.allCases.randomElement() ?? .I
        let piece = ActivePiece(type: type, rotation: 0, row: 0, col: 3)
        if !isValid(piece) {
            isGameOver = true
            current = nil
            return
        }
        current = piece
    }
}
