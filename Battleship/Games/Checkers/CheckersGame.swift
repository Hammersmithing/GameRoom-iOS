import Foundation

enum CheckerColor: Equatable {
    case red, black

    var opponent: CheckerColor { self == .red ? .black : .red }
    var name: String { self == .red ? "Red" : "Black" }
    /// Forward row delta. Red sits on the bottom rows and moves toward row 0.
    var forwardDelta: Int { self == .red ? -1 : 1 }
}

struct Piece: Equatable {
    let color: CheckerColor
    var isKing: Bool = false
}

struct Position: Equatable, Hashable {
    let row: Int
    let col: Int
}

struct CheckersMove: Equatable, Hashable {
    let from: Position
    let to: Position
    let captured: Position?

    var isCapture: Bool { captured != nil }
}

enum CheckersResult: Equatable {
    case win(CheckerColor)
}

class CheckersGame: ObservableObject {
    static let size = 8

    @Published var board: [[Piece?]]
    @Published var currentTurn: CheckerColor = .red
    @Published var selected: Position? = nil
    @Published var result: CheckersResult? = nil
    /// Set when a multi-jump is in progress and the same piece must continue.
    @Published var mustContinueFrom: Position? = nil

    init() {
        board = Self.initialBoard()
    }

    static func initialBoard() -> [[Piece?]] {
        var b = Array(repeating: Array<Piece?>(repeating: nil, count: size), count: size)
        for row in 0..<3 {
            for col in 0..<size where (row + col) % 2 == 1 {
                b[row][col] = Piece(color: .black)
            }
        }
        for row in 5..<size {
            for col in 0..<size where (row + col) % 2 == 1 {
                b[row][col] = Piece(color: .red)
            }
        }
        return b
    }

    func reset() {
        board = Self.initialBoard()
        currentTurn = .red
        selected = nil
        result = nil
        mustContinueFrom = nil
    }

    func tap(_ pos: Position) {
        guard result == nil else { return }

        if let cont = mustContinueFrom {
            if let move = legalMoves(from: cont).first(where: { $0.to == pos }) {
                performMove(move)
            }
            return
        }

        if let from = selected {
            if let move = legalMoves(from: from).first(where: { $0.to == pos }) {
                performMove(move)
                return
            }
            if let p = board[pos.row][pos.col], p.color == currentTurn,
               !mustCapture() || hasCapture(from: pos) {
                selected = pos
                return
            }
            selected = nil
            return
        }

        if let p = board[pos.row][pos.col], p.color == currentTurn {
            if mustCapture() && !hasCapture(from: pos) { return }
            selected = pos
        }
    }

    func legalMoves(from pos: Position) -> [CheckersMove] {
        guard let piece = board[pos.row][pos.col], piece.color == currentTurn else { return [] }

        if let cont = mustContinueFrom, cont != pos { return [] }

        let captures = captureMoves(from: pos, piece: piece)
        if !captures.isEmpty { return captures }
        if mustCapture() { return [] }
        return simpleMoves(from: pos, piece: piece)
    }

    func legalDestinations(from pos: Position) -> [Position] {
        legalMoves(from: pos).map { $0.to }
    }

    func mustCapture() -> Bool {
        if let cont = mustContinueFrom, let p = board[cont.row][cont.col] {
            return !captureMoves(from: cont, piece: p).isEmpty
        }
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if let p = board[r][c], p.color == currentTurn,
                   !captureMoves(from: Position(row: r, col: c), piece: p).isEmpty {
                    return true
                }
            }
        }
        return false
    }

    func pieceCount(_ color: CheckerColor) -> Int {
        var n = 0
        for row in board {
            for sq in row where sq?.color == color { n += 1 }
        }
        return n
    }

    private func hasCapture(from pos: Position) -> Bool {
        guard let p = board[pos.row][pos.col] else { return false }
        return !captureMoves(from: pos, piece: p).isEmpty
    }

    private func simpleMoves(from pos: Position, piece: Piece) -> [CheckersMove] {
        var moves: [CheckersMove] = []
        for (dr, dc) in movementDirections(piece: piece) {
            let nr = pos.row + dr, nc = pos.col + dc
            if inBounds(nr, nc), board[nr][nc] == nil {
                moves.append(CheckersMove(from: pos, to: Position(row: nr, col: nc), captured: nil))
            }
        }
        return moves
    }

    private func captureMoves(from pos: Position, piece: Piece) -> [CheckersMove] {
        var moves: [CheckersMove] = []
        for (dr, dc) in movementDirections(piece: piece) {
            let mr = pos.row + dr, mc = pos.col + dc
            let lr = pos.row + dr * 2, lc = pos.col + dc * 2
            guard inBounds(lr, lc) else { continue }
            guard let middle = board[mr][mc], middle.color != piece.color else { continue }
            guard board[lr][lc] == nil else { continue }
            moves.append(CheckersMove(
                from: pos,
                to: Position(row: lr, col: lc),
                captured: Position(row: mr, col: mc)
            ))
        }
        return moves
    }

    private func movementDirections(piece: Piece) -> [(Int, Int)] {
        if piece.isKing { return [(-1,-1), (-1,1), (1,-1), (1,1)] }
        let f = piece.color.forwardDelta
        return [(f, -1), (f, 1)]
    }

    private func inBounds(_ r: Int, _ c: Int) -> Bool {
        r >= 0 && r < Self.size && c >= 0 && c < Self.size
    }

    private func performMove(_ move: CheckersMove) {
        guard var piece = board[move.from.row][move.from.col] else { return }
        let wasKing = piece.isKing
        board[move.from.row][move.from.col] = nil
        if let cap = move.captured {
            board[cap.row][cap.col] = nil
        }
        if !piece.isKing {
            if piece.color == .red && move.to.row == 0 { piece.isKing = true }
            if piece.color == .black && move.to.row == Self.size - 1 { piece.isKing = true }
        }
        let becameKing = piece.isKing && !wasKing
        board[move.to.row][move.to.col] = piece

        if move.isCapture && !becameKing,
           !captureMoves(from: move.to, piece: piece).isEmpty {
            mustContinueFrom = move.to
            selected = move.to
            return
        }

        mustContinueFrom = nil
        selected = nil
        currentTurn = currentTurn.opponent
        checkGameOver()
    }

    private func checkGameOver() {
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if let p = board[r][c], p.color == currentTurn {
                    let pos = Position(row: r, col: c)
                    if !simpleMoves(from: pos, piece: p).isEmpty
                        || !captureMoves(from: pos, piece: p).isEmpty {
                        return
                    }
                }
            }
        }
        result = .win(currentTurn.opponent)
    }
}
