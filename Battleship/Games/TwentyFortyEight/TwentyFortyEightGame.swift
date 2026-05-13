import Foundation

enum SlideDirection {
    case left, right, up, down
}

class TwentyFortyEightGame: ObservableObject {
    static let size = 4
    static let winValue = 2048

    @Published var grid: [[Int]]
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var hasWon: Bool = false
    @Published var keepPlaying: Bool = false

    init() {
        grid = Array(repeating: Array(repeating: 0, count: Self.size), count: Self.size)
        reset()
    }

    func reset() {
        grid = Array(repeating: Array(repeating: 0, count: Self.size), count: Self.size)
        score = 0
        isGameOver = false
        hasWon = false
        keepPlaying = false
        spawn()
        spawn()
    }

    func dismissWinBanner() {
        keepPlaying = true
    }

    func move(_ direction: SlideDirection) {
        guard !isGameOver else { return }
        let (newGrid, gain) = slide(grid: grid, direction: direction)
        guard newGrid != grid else { return }

        grid = newGrid
        score += gain

        if !hasWon, grid.contains(where: { $0.contains(Self.winValue) }) {
            hasWon = true
        }

        spawn()
        if !canMove() {
            isGameOver = true
        }
    }

    private func slide(grid: [[Int]], direction: SlideDirection) -> ([[Int]], Int) {
        var working = grid
        switch direction {
        case .left:
            break
        case .right:
            working = working.map { Array($0.reversed()) }
        case .up:
            working = transpose(working)
        case .down:
            working = transpose(working).map { Array($0.reversed()) }
        }

        var totalGain = 0
        var newGrid: [[Int]] = []
        for row in working {
            let (newRow, gain) = slideRowLeft(row)
            newGrid.append(newRow)
            totalGain += gain
        }

        switch direction {
        case .left:
            break
        case .right:
            newGrid = newGrid.map { Array($0.reversed()) }
        case .up:
            newGrid = transpose(newGrid)
        case .down:
            newGrid = transpose(newGrid.map { Array($0.reversed()) })
        }

        return (newGrid, totalGain)
    }

    private func slideRowLeft(_ row: [Int]) -> ([Int], Int) {
        let compact = row.filter { $0 != 0 }
        var result: [Int] = []
        var gain = 0
        var i = 0
        while i < compact.count {
            if i + 1 < compact.count, compact[i] == compact[i + 1] {
                let merged = compact[i] * 2
                result.append(merged)
                gain += merged
                i += 2
            } else {
                result.append(compact[i])
                i += 1
            }
        }
        while result.count < Self.size { result.append(0) }
        return (result, gain)
    }

    private func transpose(_ g: [[Int]]) -> [[Int]] {
        var t = Array(repeating: Array(repeating: 0, count: g.count), count: g[0].count)
        for r in 0..<g.count {
            for c in 0..<g[0].count {
                t[c][r] = g[r][c]
            }
        }
        return t
    }

    private func spawn() {
        var empties: [(Int, Int)] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size where grid[r][c] == 0 {
                empties.append((r, c))
            }
        }
        guard let (r, c) = empties.randomElement() else { return }
        grid[r][c] = Int.random(in: 0..<10) == 0 ? 4 : 2
    }

    private func canMove() -> Bool {
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if grid[r][c] == 0 { return true }
                if c + 1 < Self.size && grid[r][c] == grid[r][c + 1] { return true }
                if r + 1 < Self.size && grid[r][c] == grid[r + 1][c] { return true }
            }
        }
        return false
    }
}
