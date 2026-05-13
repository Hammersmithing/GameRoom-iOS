import Foundation

enum PieceColor: Equatable {
    case white, black
    var opponent: PieceColor { self == .white ? .black : .white }
    var name: String { self == .white ? "White" : "Black" }
}

enum PieceType: Equatable {
    case pawn, knight, bishop, rook, queen, king
}

struct ChessPiece: Equatable {
    let type: PieceType
    let color: PieceColor
    var hasMoved: Bool = false
}

struct ChessMove: Equatable, Hashable {
    let from: Position
    let to: Position
}

enum ChessResult: Equatable {
    case checkmate(PieceColor)  // winning color
    case stalemate
}

class ChessGame: ObservableObject {
    static let size = 8

    @Published var board: [[ChessPiece?]]
    @Published var currentTurn: PieceColor = .white
    @Published var selected: Position? = nil
    @Published var result: ChessResult? = nil
    @Published var lastMove: ChessMove? = nil
    @Published var enPassantTarget: Position? = nil

    init() {
        board = Self.initialBoard()
    }

    static func initialBoard() -> [[ChessPiece?]] {
        var b = Array(repeating: Array<ChessPiece?>(repeating: nil, count: size), count: size)
        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for c in 0..<size {
            b[0][c] = ChessPiece(type: backRank[c], color: .black)
            b[1][c] = ChessPiece(type: .pawn, color: .black)
            b[6][c] = ChessPiece(type: .pawn, color: .white)
            b[7][c] = ChessPiece(type: backRank[c], color: .white)
        }
        return b
    }

    func reset() {
        board = Self.initialBoard()
        currentTurn = .white
        selected = nil
        result = nil
        lastMove = nil
        enPassantTarget = nil
    }

    var isInCheck: Bool {
        Self.isInCheck(board: board, color: currentTurn)
    }

    func tap(_ pos: Position) {
        guard result == nil else { return }
        if let from = selected {
            if pos == from { selected = nil; return }
            let moves = legalMoves(from: from)
            if let move = moves.first(where: { $0.to == pos }) {
                make(move)
                return
            }
            if let p = board[pos.row][pos.col], p.color == currentTurn {
                selected = pos
                return
            }
            selected = nil
        } else if let p = board[pos.row][pos.col], p.color == currentTurn {
            selected = pos
        }
    }

    func legalMoves(from pos: Position) -> [ChessMove] {
        guard let piece = board[pos.row][pos.col], piece.color == currentTurn else { return [] }
        let pseudo = pseudoLegalMoves(from: pos, piece: piece, board: board, enPassant: enPassantTarget)
        return pseudo.filter { !wouldLeaveInCheck(move: $0, color: piece.color) }
    }

    func legalDestinations(from pos: Position) -> Set<Position> {
        Set(legalMoves(from: pos).map { $0.to })
    }

    private func make(_ move: ChessMove) {
        guard var piece = board[move.from.row][move.from.col] else { return }

        let isCastling = piece.type == .king && abs(move.to.col - move.from.col) == 2
        let isEnPassant = piece.type == .pawn
            && move.to.col != move.from.col
            && board[move.to.row][move.to.col] == nil
            && enPassantTarget == move.to

        piece.hasMoved = true
        board[move.from.row][move.from.col] = nil

        if isEnPassant {
            let dir = piece.color == .white ? 1 : -1
            board[move.to.row + dir][move.to.col] = nil
        }

        board[move.to.row][move.to.col] = piece

        if isCastling {
            let row = move.from.row
            if move.to.col > move.from.col {
                if var rook = board[row][7] { rook.hasMoved = true; board[row][5] = rook }
                board[row][7] = nil
            } else {
                if var rook = board[row][0] { rook.hasMoved = true; board[row][3] = rook }
                board[row][0] = nil
            }
        }

        if piece.type == .pawn && (move.to.row == 0 || move.to.row == Self.size - 1) {
            board[move.to.row][move.to.col] = ChessPiece(type: .queen, color: piece.color, hasMoved: true)
        }

        if piece.type == .pawn && abs(move.to.row - move.from.row) == 2 {
            enPassantTarget = Position(row: (move.to.row + move.from.row) / 2, col: move.to.col)
        } else {
            enPassantTarget = nil
        }

        lastMove = move
        selected = nil
        currentTurn = currentTurn.opponent
        checkGameEnd()
    }

    private func checkGameEnd() {
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if let p = board[r][c], p.color == currentTurn {
                    if !legalMoves(from: Position(row: r, col: c)).isEmpty {
                        return
                    }
                }
            }
        }
        if isInCheck {
            result = .checkmate(currentTurn.opponent)
        } else {
            result = .stalemate
        }
    }

    private func wouldLeaveInCheck(move: ChessMove, color: PieceColor) -> Bool {
        var sim = board
        guard var piece = sim[move.from.row][move.from.col] else { return false }

        let isCastling = piece.type == .king && abs(move.to.col - move.from.col) == 2
        let isEnPassant = piece.type == .pawn
            && move.to.col != move.from.col
            && sim[move.to.row][move.to.col] == nil
            && enPassantTarget == move.to

        piece.hasMoved = true
        sim[move.from.row][move.from.col] = nil

        if isEnPassant {
            let dir = color == .white ? 1 : -1
            sim[move.to.row + dir][move.to.col] = nil
        }

        sim[move.to.row][move.to.col] = piece

        if isCastling {
            let row = move.from.row
            if move.to.col > move.from.col {
                sim[row][5] = sim[row][7]
                sim[row][7] = nil
            } else {
                sim[row][3] = sim[row][0]
                sim[row][0] = nil
            }
        }

        return Self.isInCheck(board: sim, color: color)
    }

    // MARK: - Static engine helpers (operate on a passed-in board)

    static func isInCheck(board: [[ChessPiece?]], color: PieceColor) -> Bool {
        var kingPos: Position? = nil
        for r in 0..<size {
            for c in 0..<size {
                if let p = board[r][c], p.type == .king, p.color == color {
                    kingPos = Position(row: r, col: c)
                }
            }
        }
        guard let king = kingPos else { return false }
        return isSquareAttacked(board: board, square: king, by: color.opponent)
    }

    static func isSquareAttacked(board: [[ChessPiece?]], square: Position, by color: PieceColor) -> Bool {
        for r in 0..<size {
            for c in 0..<size {
                if let p = board[r][c], p.color == color {
                    if attacks(board: board, from: Position(row: r, col: c), piece: p, target: square) {
                        return true
                    }
                }
            }
        }
        return false
    }

    static func attacks(board: [[ChessPiece?]], from: Position, piece: ChessPiece, target: Position) -> Bool {
        switch piece.type {
        case .pawn:
            let dir = piece.color == .white ? -1 : 1
            return target.row == from.row + dir && abs(target.col - from.col) == 1
        case .knight:
            let dr = abs(target.row - from.row), dc = abs(target.col - from.col)
            return (dr == 1 && dc == 2) || (dr == 2 && dc == 1)
        case .king:
            return abs(target.row - from.row) <= 1
                && abs(target.col - from.col) <= 1
                && from != target
        case .bishop:
            return slidingHits(board: board, from: from, to: target,
                               dirs: [(-1,-1),(-1,1),(1,-1),(1,1)])
        case .rook:
            return slidingHits(board: board, from: from, to: target,
                               dirs: [(-1,0),(1,0),(0,-1),(0,1)])
        case .queen:
            return slidingHits(board: board, from: from, to: target,
                               dirs: [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)])
        }
    }

    static func slidingHits(board: [[ChessPiece?]], from: Position, to: Position, dirs: [(Int, Int)]) -> Bool {
        for (dr, dc) in dirs {
            var r = from.row + dr, c = from.col + dc
            while r >= 0, r < size, c >= 0, c < size {
                if Position(row: r, col: c) == to { return true }
                if board[r][c] != nil { break }
                r += dr; c += dc
            }
        }
        return false
    }

    func pseudoLegalMoves(from: Position, piece: ChessPiece, board: [[ChessPiece?]], enPassant: Position?) -> [ChessMove] {
        switch piece.type {
        case .pawn:
            return pawnMoves(from: from, piece: piece, board: board, enPassant: enPassant)
        case .knight:
            return knightMoves(from: from, piece: piece, board: board)
        case .bishop:
            return slidingMoves(from: from, piece: piece, board: board,
                                dirs: [(-1,-1),(-1,1),(1,-1),(1,1)])
        case .rook:
            return slidingMoves(from: from, piece: piece, board: board,
                                dirs: [(-1,0),(1,0),(0,-1),(0,1)])
        case .queen:
            return slidingMoves(from: from, piece: piece, board: board,
                                dirs: [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)])
        case .king:
            return kingMoves(from: from, piece: piece, board: board)
        }
    }

    private func pawnMoves(from: Position, piece: ChessPiece, board: [[ChessPiece?]], enPassant: Position?) -> [ChessMove] {
        var moves: [ChessMove] = []
        let dir = piece.color == .white ? -1 : 1
        let startRow = piece.color == .white ? 6 : 1
        let r = from.row + dir
        guard r >= 0 && r < Self.size else { return moves }

        if board[r][from.col] == nil {
            moves.append(ChessMove(from: from, to: Position(row: r, col: from.col)))
            if from.row == startRow {
                let r2 = from.row + 2 * dir
                if r2 >= 0 && r2 < Self.size && board[r2][from.col] == nil {
                    moves.append(ChessMove(from: from, to: Position(row: r2, col: from.col)))
                }
            }
        }

        for dc in [-1, 1] {
            let c = from.col + dc
            guard c >= 0 && c < Self.size else { continue }
            let target = Position(row: r, col: c)
            if let p = board[r][c], p.color != piece.color {
                moves.append(ChessMove(from: from, to: target))
            } else if enPassant == target {
                moves.append(ChessMove(from: from, to: target))
            }
        }
        return moves
    }

    private func knightMoves(from: Position, piece: ChessPiece, board: [[ChessPiece?]]) -> [ChessMove] {
        let deltas: [(Int, Int)] = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]
        var moves: [ChessMove] = []
        for (dr, dc) in deltas {
            let r = from.row + dr, c = from.col + dc
            if r >= 0, r < Self.size, c >= 0, c < Self.size {
                if let p = board[r][c], p.color == piece.color { continue }
                moves.append(ChessMove(from: from, to: Position(row: r, col: c)))
            }
        }
        return moves
    }

    private func slidingMoves(from: Position, piece: ChessPiece, board: [[ChessPiece?]], dirs: [(Int, Int)]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for (dr, dc) in dirs {
            var r = from.row + dr, c = from.col + dc
            while r >= 0, r < Self.size, c >= 0, c < Self.size {
                if let p = board[r][c] {
                    if p.color != piece.color {
                        moves.append(ChessMove(from: from, to: Position(row: r, col: c)))
                    }
                    break
                }
                moves.append(ChessMove(from: from, to: Position(row: r, col: c)))
                r += dr; c += dc
            }
        }
        return moves
    }

    private func kingMoves(from: Position, piece: ChessPiece, board: [[ChessPiece?]]) -> [ChessMove] {
        var moves: [ChessMove] = []
        for dr in -1...1 {
            for dc in -1...1 where !(dr == 0 && dc == 0) {
                let r = from.row + dr, c = from.col + dc
                if r >= 0, r < Self.size, c >= 0, c < Self.size {
                    if let p = board[r][c], p.color == piece.color { continue }
                    moves.append(ChessMove(from: from, to: Position(row: r, col: c)))
                }
            }
        }

        guard !piece.hasMoved, !Self.isInCheck(board: board, color: piece.color) else {
            return moves
        }
        let row = from.row
        if let rook = board[row][7], rook.type == .rook, rook.color == piece.color, !rook.hasMoved,
           board[row][5] == nil, board[row][6] == nil,
           !Self.isSquareAttacked(board: board, square: Position(row: row, col: 5), by: piece.color.opponent),
           !Self.isSquareAttacked(board: board, square: Position(row: row, col: 6), by: piece.color.opponent) {
            moves.append(ChessMove(from: from, to: Position(row: row, col: 6)))
        }
        if let rook = board[row][0], rook.type == .rook, rook.color == piece.color, !rook.hasMoved,
           board[row][1] == nil, board[row][2] == nil, board[row][3] == nil,
           !Self.isSquareAttacked(board: board, square: Position(row: row, col: 3), by: piece.color.opponent),
           !Self.isSquareAttacked(board: board, square: Position(row: row, col: 2), by: piece.color.opponent) {
            moves.append(ChessMove(from: from, to: Position(row: row, col: 2)))
        }
        return moves
    }
}
