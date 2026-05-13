import Foundation

enum MineCellState {
    case hidden, revealed, flagged
}

struct MineCell {
    var hasMine: Bool = false
    var state: MineCellState = .hidden
    var adjacent: Int = 0
}

enum MinesweeperResult: Equatable {
    case won, lost
}

class MinesweeperGame: ObservableObject {
    static let rows = 16
    static let cols = 16
    static let mineCount = 40

    @Published var grid: [[MineCell]]
    @Published var result: MinesweeperResult? = nil
    @Published var revealedMine: Position? = nil
    private var minesPlaced = false

    init() {
        grid = Self.emptyGrid()
    }

    static func emptyGrid() -> [[MineCell]] {
        Array(repeating: Array(repeating: MineCell(), count: cols), count: rows)
    }

    func reset() {
        grid = Self.emptyGrid()
        result = nil
        revealedMine = nil
        minesPlaced = false
    }

    var flagCount: Int {
        var n = 0
        for row in grid {
            for c in row where c.state == .flagged { n += 1 }
        }
        return n
    }

    var minesRemaining: Int { Self.mineCount - flagCount }

    func reveal(_ pos: Position) {
        guard result == nil else { return }
        let cell = grid[pos.row][pos.col]
        guard cell.state == .hidden else { return }

        if !minesPlaced {
            placeMines(avoiding: pos)
            minesPlaced = true
        }

        if grid[pos.row][pos.col].hasMine {
            grid[pos.row][pos.col].state = .revealed
            revealedMine = pos
            for r in 0..<Self.rows {
                for c in 0..<Self.cols where grid[r][c].hasMine {
                    grid[r][c].state = .revealed
                }
            }
            result = .lost
            return
        }

        floodReveal(from: pos)
        if checkWin() { result = .won }
    }

    func toggleFlag(_ pos: Position) {
        guard result == nil else { return }
        switch grid[pos.row][pos.col].state {
        case .hidden:   grid[pos.row][pos.col].state = .flagged
        case .flagged:  grid[pos.row][pos.col].state = .hidden
        case .revealed: break
        }
    }

    private func placeMines(avoiding pos: Position) {
        let safe = Set(neighbors(pos) + [pos])
        var avail: [Position] = []
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                let p = Position(row: r, col: c)
                if !safe.contains(p) { avail.append(p) }
            }
        }
        avail.shuffle()
        for p in avail.prefix(Self.mineCount) {
            grid[p.row][p.col].hasMine = true
        }
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                let p = Position(row: r, col: c)
                grid[r][c].adjacent = neighbors(p).filter { grid[$0.row][$0.col].hasMine }.count
            }
        }
    }

    private func floodReveal(from start: Position) {
        var stack = [start]
        while let p = stack.popLast() {
            guard grid[p.row][p.col].state == .hidden,
                  !grid[p.row][p.col].hasMine else { continue }
            grid[p.row][p.col].state = .revealed
            if grid[p.row][p.col].adjacent == 0 {
                for n in neighbors(p) where grid[n.row][n.col].state == .hidden {
                    stack.append(n)
                }
            }
        }
    }

    private func neighbors(_ p: Position) -> [Position] {
        var ns: [Position] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let r = p.row + dr, c = p.col + dc
                if r >= 0, r < Self.rows, c >= 0, c < Self.cols {
                    ns.append(Position(row: r, col: c))
                }
            }
        }
        return ns
    }

    private func checkWin() -> Bool {
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                if !grid[r][c].hasMine && grid[r][c].state != .revealed {
                    return false
                }
            }
        }
        return true
    }
}
