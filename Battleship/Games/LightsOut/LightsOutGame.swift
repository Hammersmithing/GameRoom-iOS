import Foundation

class LightsOutGame: ObservableObject {
    static let size = 5

    @Published var grid: [[Bool]] = []
    @Published var moves: Int = 0
    @Published var isSolved: Bool = false

    init() { reset() }

    func reset() {
        grid = Array(repeating: Array(repeating: false, count: Self.size), count: Self.size)
        moves = 0
        repeat {
            scramble()
        } while grid.flatMap({ $0 }).allSatisfy { !$0 }
        isSolved = false
    }

    func tap(row: Int, col: Int) {
        guard !isSolved else { return }
        applyTap(row: row, col: col)
        moves += 1
        if grid.flatMap({ $0 }).allSatisfy({ !$0 }) {
            isSolved = true
        }
    }

    private func applyTap(row: Int, col: Int) {
        toggle(row: row, col: col)
        for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            toggle(row: row + dr, col: col + dc)
        }
    }

    private func toggle(row: Int, col: Int) {
        guard row >= 0, row < Self.size, col >= 0, col < Self.size else { return }
        grid[row][col].toggle()
    }

    private func scramble() {
        grid = Array(repeating: Array(repeating: false, count: Self.size), count: Self.size)
        let count = 12 + Int.random(in: 0...10)
        for _ in 0..<count {
            applyTap(
                row: Int.random(in: 0..<Self.size),
                col: Int.random(in: 0..<Self.size)
            )
        }
    }
}
