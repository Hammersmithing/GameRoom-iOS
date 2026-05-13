import SwiftUI

struct ReversiView: View {
    @StateObject private var game = ReversiGame()
    var onExit: () -> Void = {}

    private let cellSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            GameHeader(
                title: "REVERSI",
                statusContent: AnyView(statusContent),
                onNewGame: { game.reset() },
                onExit: onExit
            )

            VStack(spacing: 0) {
                Spacer()
                board
                Spacer()
                if game.result != nil {
                    resultBanner.padding(.bottom, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .fill(discColor(game.currentTurn))
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                        .frame(width: 14, height: 14)
                    Text(game.currentTurn.name)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    if game.lastPassed {
                        Text("· \(game.currentTurn.opponent.name) passed")
                            .foregroundColor(.yellow)
                    }
                    Text("·").foregroundColor(.gray)
                    Text("B \(game.count(.black))")
                        .foregroundColor(.white)
                    Text("W \(game.count(.white))")
                        .foregroundColor(.white.opacity(0.85))
                }
            } else {
                EmptyView()
            }
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
    }

    private var board: some View {
        let legal = game.result == nil ? game.legalMoves(for: game.currentTurn) : []

        return VStack(spacing: 1) {
            ForEach(0..<ReversiGame.size, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<ReversiGame.size, id: \.self) { col in
                        cell(row: row, col: col, legal: legal)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.05, green: 0.18, blue: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(white: 0.3), lineWidth: 2)
        )
    }

    private func cell(row: Int, col: Int, legal: Set<Position>) -> some View {
        let pos = Position(row: row, col: col)
        let disc = game.board[row][col]
        let isLegal = legal.contains(pos)
        let isLast = game.lastPlaced == pos

        return Button(action: { game.place(row: row, col: col) }) {
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.45, blue: 0.22))
                    .frame(width: cellSize, height: cellSize)

                if let d = disc {
                    Circle()
                        .fill(discColor(d))
                        .frame(width: cellSize * 0.78, height: cellSize * 0.78)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                .frame(width: cellSize * 0.78, height: cellSize * 0.78)
                        )
                } else if isLegal {
                    Circle()
                        .fill(discColor(game.currentTurn).opacity(0.35))
                        .frame(width: cellSize * 0.3, height: cellSize * 0.3)
                }

                if isLast {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(game.result != nil || !isLegal)
    }

    private func discColor(_ d: ReversiDisc) -> Color {
        d == .black ? Color(white: 0.08) : Color(white: 0.95)
    }

    private var resultBanner: some View {
        VStack(spacing: 12) {
            switch game.result {
            case .win(let d):
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow)
                    Circle()
                        .fill(discColor(d))
                        .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                        .frame(width: 22, height: 22)
                    Text("\(d.name) Wins!")
                        .fontWeight(.bold)
                }
                .font(.system(size: 28, design: .monospaced))
                .foregroundColor(.white)
                Text("\(game.count(.black)) – \(game.count(.white))")
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
            case .draw:
                Text("Draw — \(game.count(.black)) all")
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
