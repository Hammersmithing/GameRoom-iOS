import Foundation

enum Disc: Equatable {
    case red, yellow

    var next: Disc { self == .red ? .yellow : .red }
    var name: String { self == .red ? "Red" : "Yellow" }
}

enum ConnectFourResult: Equatable {
    case win(Disc)
    case draw
}

class ConnectFourGame: ObservableObject {
    static let rows = 6
    static let cols = 7

    @Published var grid: [[Disc?]] = Array(
        repeating: Array(repeating: nil, count: 7),
        count: 6
    )
    @Published var currentTurn: Disc = .red
    @Published var result: ConnectFourResult? = nil
    @Published var lastDrop: (row: Int, col: Int)? = nil

    var winningCells: [(Int, Int)]? {
        guard case .win(let disc) = result else { return nil }
        return findWinLine(for: disc)
    }

    /// Returns the row the disc lands in, or nil if column is full.
    func drop(col: Int) {
        guard result == nil else { return }
        guard let row = lowestEmptyRow(in: col) else { return }

        grid[row][col] = currentTurn
        lastDrop = (row, col)

        if checkWin(row: row, col: col, disc: currentTurn) {
            result = .win(currentTurn)
        } else if isBoardFull() {
            result = .draw
        } else {
            currentTurn = currentTurn.next
        }
    }

    func lowestEmptyRow(in col: Int) -> Int? {
        for row in stride(from: Self.rows - 1, through: 0, by: -1) {
            if grid[row][col] == nil { return row }
        }
        return nil
    }

    private func isBoardFull() -> Bool {
        grid[0].allSatisfy { $0 != nil }
    }

    private func checkWin(row: Int, col: Int, disc: Disc) -> Bool {
        let directions: [(Int, Int)] = [(0,1), (1,0), (1,1), (1,-1)]
        for (dr, dc) in directions {
            var count = 1
            count += countInDirection(row: row, col: col, dr: dr, dc: dc, disc: disc)
            count += countInDirection(row: row, col: col, dr: -dr, dc: -dc, disc: disc)
            if count >= 4 { return true }
        }
        return false
    }

    private func countInDirection(row: Int, col: Int, dr: Int, dc: Int, disc: Disc) -> Int {
        var r = row + dr, c = col + dc, count = 0
        while r >= 0, r < Self.rows, c >= 0, c < Self.cols, grid[r][c] == disc {
            count += 1
            r += dr
            c += dc
        }
        return count
    }

    private func findWinLine(for disc: Disc) -> [(Int, Int)]? {
        let directions: [(Int, Int)] = [(0,1), (1,0), (1,1), (1,-1)]
        for row in 0..<Self.rows {
            for col in 0..<Self.cols {
                guard grid[row][col] == disc else { continue }
                for (dr, dc) in directions {
                    var cells: [(Int, Int)] = []
                    for i in 0..<4 {
                        let r = row + dr * i, c = col + dc * i
                        guard r >= 0, r < Self.rows, c >= 0, c < Self.cols, grid[r][c] == disc else { break }
                        cells.append((r, c))
                    }
                    if cells.count == 4 { return cells }
                }
            }
        }
        return nil
    }

    func reset() {
        grid = Array(repeating: Array(repeating: nil, count: Self.cols), count: Self.rows)
        currentTurn = .red
        result = nil
        lastDrop = nil
    }
}
