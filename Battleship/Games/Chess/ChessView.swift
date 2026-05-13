import SwiftUI

struct ChessView: View {
    @StateObject private var game = ChessGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "CHESS",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: 8 * cellSize + 12, height: 8 * cellSize + 12) {
                board
            }
            .frame(maxHeight: .infinity)
            if game.result != nil {
                resultBanner.padding(.bottom, 24)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var statusContent: some View {
        Group {
            if game.result == nil {
                HStack(spacing: 6) {
                    Text("Turn:").foregroundColor(.gray)
                    Text(game.currentTurn.name)
                        .foregroundColor(turnColor(game.currentTurn))
                        .fontWeight(.bold)
                    if game.isInCheck {
                        Text("· CHECK")
                            .foregroundColor(.red)
                            .fontWeight(.heavy)
                    }
                }
            } else {
                EmptyView()
            }
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        let dests: Set<Position> = {
            guard let s = game.selected else { return [] }
            return game.legalDestinations(from: s)
        }()
        let kingInCheckPos = game.isInCheck ? findKing(game.currentTurn) : nil

        return VStack(spacing: 0) {
            ForEach(0..<ChessGame.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<ChessGame.size, id: \.self) { col in
                        cell(row: row, col: col, dests: dests, kingInCheck: kingInCheckPos)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(white: 0.35), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int, dests: Set<Position>, kingInCheck: Position?) -> some View {
        let pos = Position(row: row, col: col)
        let isLight = (row + col) % 2 == 0
        let piece = game.board[row][col]
        let isSelected = game.selected == pos
        let isLegal = dests.contains(pos)
        let isLastMoveSquare = game.lastMove.map { $0.from == pos || $0.to == pos } ?? false
        let isKingCheck = kingInCheck == pos

        return Button(action: { game.tap(pos) }) {
            ZStack {
                Rectangle()
                    .fill(squareColor(isLight: isLight))
                    .frame(width: cellSize, height: cellSize)

                if isLastMoveSquare {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.18))
                        .frame(width: cellSize, height: cellSize)
                }
                if isSelected {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.35))
                        .frame(width: cellSize, height: cellSize)
                }
                if isKingCheck {
                    Rectangle()
                        .fill(Color.red.opacity(0.45))
                        .frame(width: cellSize, height: cellSize)
                }

                if let p = piece {
                    pieceView(p)
                }

                if isLegal {
                    if piece == nil {
                        Circle()
                            .fill(Color.green.opacity(0.55))
                            .frame(width: cellSize * 0.28, height: cellSize * 0.28)
                    } else {
                        Circle()
                            .stroke(Color.green.opacity(0.8), lineWidth: 4)
                            .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                    }
                }

                if isSelected {
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil)
    }

    private func pieceView(_ piece: ChessPiece) -> some View {
        Text(glyph(for: piece))
            .font(.system(size: cellSize * 0.78, weight: .black))
            .foregroundColor(piece.color == .white ? Color(white: 0.97) : Color(white: 0.06))
            .shadow(
                color: piece.color == .white ? .black.opacity(0.55) : .white.opacity(0.55),
                radius: 0.5,
                x: 0,
                y: 0
            )
    }

    private func glyph(for piece: ChessPiece) -> String {
        switch piece.type {
        case .king:   return "\u{265A}"  // ♚
        case .queen:  return "\u{265B}"  // ♛
        case .rook:   return "\u{265C}"  // ♜
        case .bishop: return "\u{265D}"  // ♝
        case .knight: return "\u{265E}"  // ♞
        case .pawn:   return "\u{265F}"  // ♟
        }
    }

    private func squareColor(isLight: Bool) -> Color {
        isLight
            ? Color(red: 0.93, green: 0.85, blue: 0.72)
            : Color(red: 0.45, green: 0.30, blue: 0.20)
    }

    private func turnColor(_ c: PieceColor) -> Color {
        c == .white ? .white : Color(white: 0.7)
    }

    private func findKing(_ color: PieceColor) -> Position? {
        for r in 0..<ChessGame.size {
            for c in 0..<ChessGame.size {
                if let p = game.board[r][c], p.type == .king, p.color == color {
                    return Position(row: r, col: c)
                }
            }
        }
        return nil
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .checkmate(let winner):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Text("Checkmate — \(winner.name) wins")
                        .fontWeight(.bold)
                }
                .font(.system(size: 24, design: .monospaced))
                .foregroundColor(.white)
            case .stalemate:
                Text("Stalemate")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            case .none:
                EmptyView()
            }

            Button("Play Again") { game.reset() }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }
}
