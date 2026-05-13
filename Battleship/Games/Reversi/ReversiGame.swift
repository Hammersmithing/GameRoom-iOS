import Foundation

enum ReversiDisc: Equatable {
    case black, white

    var opponent: ReversiDisc { self == .black ? .white : .black }
    var name: String { self == .black ? "Black" : "White" }
}

enum ReversiResult: Equatable {
    case win(ReversiDisc)
    case draw
}

class ReversiGame: ObservableObject {
    static let size = 8

    @Published var board: [[ReversiDisc?]]
    @Published var currentTurn: ReversiDisc = .black
    @Published var result: ReversiResult? = nil
    /// True when the previous turn's player had no legal move and was skipped.
    @Published var lastPassed: Bool = false
    @Published var lastPlaced: Position? = nil

    init() {
        board = Self.initialBoard()
    }

    static func initialBoard() -> [[ReversiDisc?]] {
        var b = Array(repeating: Array<ReversiDisc?>(repeating: nil, count: size), count: size)
        b[3][3] = .white
        b[4][4] = .white
        b[3][4] = .black
        b[4][3] = .black
        return b
    }

    func reset() {
        board = Self.initialBoard()
        currentTurn = .black
        result = nil
        lastPassed = false
        lastPlaced = nil
    }

    private static let directions: [(Int, Int)] = [
        (-1,-1), (-1, 0), (-1, 1),
        ( 0,-1),          ( 0, 1),
        ( 1,-1), ( 1, 0), ( 1, 1)
    ]

    /// Cells that would flip if `player` plays at (row, col). Empty if illegal.
    func flips(row: Int, col: Int, for player: ReversiDisc) -> [Position] {
        guard row >= 0, row < Self.size, col >= 0, col < Self.size else { return [] }
        guard board[row][col] == nil else { return [] }

        var all: [Position] = []
        for (dr, dc) in Self.directions {
            var r = row + dr, c = col + dc
            var line: [Position] = []
            while r >= 0, r < Self.size, c >= 0, c < Self.size, board[r][c] == player.opponent {
                line.append(Position(row: r, col: c))
                r += dr; c += dc
            }
            if !line.isEmpty,
               r >= 0, r < Self.size, c >= 0, c < Self.size,
               board[r][c] == player {
                all.append(contentsOf: line)
            }
        }
        return all
    }

    func legalMoves(for player: ReversiDisc) -> Set<Position> {
        var moves: Set<Position> = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if !flips(row: r, col: c, for: player).isEmpty {
                    moves.insert(Position(row: r, col: c))
                }
            }
        }
        return moves
    }

    func place(row: Int, col: Int) {
        guard result == nil else { return }
        let flipped = flips(row: row, col: col, for: currentTurn)
        guard !flipped.isEmpty else { return }

        board[row][col] = currentTurn
        for p in flipped { board[p.row][p.col] = currentTurn }
        lastPlaced = Position(row: row, col: col)
        advanceTurn()
    }

    private func advanceTurn() {
        let next = currentTurn.opponent
        if !legalMoves(for: next).isEmpty {
            currentTurn = next
            lastPassed = false
            return
        }
        if !legalMoves(for: currentTurn).isEmpty {
            lastPassed = true
            return
        }
        finishGame()
    }

    private func finishGame() {
        let b = count(.black), w = count(.white)
        if b > w { result = .win(.black) }
        else if w > b { result = .win(.white) }
        else { result = .draw }
    }

    func count(_ disc: ReversiDisc) -> Int {
        var n = 0
        for row in board {
            for sq in row where sq == disc { n += 1 }
        }
        return n
    }
}
