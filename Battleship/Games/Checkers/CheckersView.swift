import SwiftUI

struct CheckersView: View {
    @StateObject private var game = CheckersGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "CHECKERS",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            ScaledFit(width: 8 * cellSize + 16, height: 8 * cellSize + 16) {
                board
            }
            .frame(maxHeight: .infinity)
            if game.result != nil {
                resultBanner.padding(.bottom, 30)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.1), Color(white: 0.04)],
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
                    Circle()
                        .fill(checkerFill(game.currentTurn))
                        .frame(width: 14, height: 14)
                    Text(game.currentTurn.name)
                        .foregroundColor(checkerLabel(game.currentTurn))
                        .fontWeight(.bold)
                    if game.mustContinueFrom != nil {
                        Text("· Jump again!")
                            .foregroundColor(.yellow)
                    }
                    Text("·").foregroundColor(.gray)
                    Text("R \(game.pieceCount(.red))")
                        .foregroundColor(.red)
                    Text("B \(game.pieceCount(.black))")
                        .foregroundColor(.white.opacity(0.85))
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
            return Set(game.legalDestinations(from: s))
        }()

        return VStack(spacing: 0) {
            ForEach(0..<CheckersGame.size, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<CheckersGame.size, id: \.self) { col in
                        cell(row: row, col: col, dests: dests)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int, dests: Set<Position>) -> some View {
        let pos = Position(row: row, col: col)
        let isDark = (row + col) % 2 == 1
        let isSelected = game.selected == pos
        let isLegal = dests.contains(pos)
        let piece = game.board[row][col]

        return Button(action: { game.tap(pos) }) {
            ZStack {
                Rectangle()
                    .fill(isDark
                        ? Color(red: 0.35, green: 0.22, blue: 0.13)
                        : Color(red: 0.95, green: 0.85, blue: 0.7))
                    .frame(width: cellSize, height: cellSize)

                if isSelected {
                    Rectangle()
                        .fill(Color.yellow.opacity(0.35))
                        .frame(width: cellSize, height: cellSize)
                }

                if isLegal {
                    Circle()
                        .fill(Color.green.opacity(0.55))
                        .frame(width: cellSize * 0.4, height: cellSize * 0.4)
                }

                if let p = piece {
                    pieceView(p)
                }

                if isSelected {
                    Rectangle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: cellSize, height: cellSize)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil || !isDark)
    }

    private func pieceView(_ piece: Piece) -> some View {
        ZStack {
            Circle()
                .fill(checkerFill(piece.color))
                .frame(width: cellSize * 0.78, height: cellSize * 0.78)
                .shadow(color: .black.opacity(0.5), radius: 3, y: 2)

            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: cellSize * 0.78, height: cellSize * 0.78)

            if piece.isKing {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: cellSize * 0.32, weight: .bold))
                    .shadow(color: .black.opacity(0.6), radius: 1)
            }
        }
    }

    private func checkerFill(_ c: CheckerColor) -> Color {
        c == .red
            ? Color(red: 0.85, green: 0.18, blue: 0.18)
            : Color(white: 0.12)
    }

    private func checkerLabel(_ c: CheckerColor) -> Color {
        c == .red ? .red : .white
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let c):
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Circle()
                        .fill(checkerFill(c))
                        .frame(width: 20, height: 20)
                    Text("\(c.name) Wins!").fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
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
